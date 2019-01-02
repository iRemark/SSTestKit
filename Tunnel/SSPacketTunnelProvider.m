//
//  PacketTunnelProvider.m
//  tunnel
//
//  Created by xiaoyu on 2018/9/26.
//  Copyright © 2018年 xiaoyu. All rights reserved.
//

#import "SSPacketTunnelProvider.h"
#import "ProxyManager.h"
#import "TunnelInterface.h"
#import "TunnelError.h"
#import "dns.h"

#import <sys/syslog.h>
#import <ShadowPath/ShadowPath.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#import <MMWormhole/MMWormhole.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

#import "SSProxy.h"
#import "SSDevice.h"
#import "SSFilePath.h"
#import "Settings.h"
#import "JSONUtils.h"

#define REQUEST_CACHED @"requestsCached"    // Indicate that recent requests need update

@interface SSPacketTunnelProvider () <GCDAsyncSocketDelegate>

@property (nonatomic) MMWormhole *wormhole;
@property (nonatomic) GCDAsyncSocket *statusSocket;
@property (nonatomic) GCDAsyncSocket *statusClientSocket;

@property (nonatomic, assign) BOOL didSetupHockeyApp;
@property (nonatomic, assign) BOOL isRunning;

@property (nonatomic, assign) NSInteger timeoutTimes;


@property (nonatomic, copy) NSString *domin;
@property (nonatomic) NWPath *lastPath;

@property (strong) void (^pendingStartCompletion)(NSError *);
@property (strong) void (^pendingStopCompletion)(void);

@end


@implementation SSPacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    // ss 协议
    [self openLog];
    PLog(@"starting PandaVPN tunnel...");
    // 更新状态数据
    PLog(@"更新状态数据");
    [self updateUserDefaults];
    self.isRunning = false;
    PLog(@"创建虚拟网卡接口");
    NSError *error = [TunnelInterface setupWithPacketTunnelFlow:self.packetFlow];
    if (error) {
        PLog(@"创建虚拟网卡接口错误:%@",error);
        completionHandler(error);
        [TunnelInterface stop];
        exit(1);
        return;
    }
    self.pendingStartCompletion = completionHandler;
    
    PLog(@"打开代理通道");
    [self startProxies];
    // tun2socks隧道打开
    PLog(@"tun2socks隧道打开");
    [self startPacketForwarders];
    // 打开监听：手表和today插件
    PLog(@"打开监听：手表和today插件");
    [self setupWormhole];
}

// shadowsocket

- (void)updateUserDefaults {
    [[SSFilePath sharedUserDefaults] removeObjectForKey:REQUEST_CACHED];
    [[SSFilePath sharedUserDefaults] synchronize];
    [[Settings shared] setStartTime:[NSDate date]];
}

- (void)setupWormhole {
    self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:sharedGroupIdentifier optionalDirectory:@"wormhole"];
    __weak typeof(self) weakSelf = self;
    [self.wormhole listenForMessageWithIdentifier:@"getTunnelStatus" listener:^(id  _Nullable messageObject) {
        [weakSelf.wormhole passMessageObject:@"ok" identifier:@"tunnelStatus"];
    }];
    [self.wormhole listenForMessageWithIdentifier:@"stopTunnel" listener:^(id  _Nullable messageObject) {
        [weakSelf stop];
    }];
    [self.wormhole listenForMessageWithIdentifier:@"getTunnelConnectionRecords" listener:^(id  _Nullable messageObject) {
         NSMutableArray *records = [NSMutableArray array];
         struct log_client_states *p = log_clients;
         while (p) {
             struct client_state *client = p->csp;
             NSMutableDictionary *d = [NSMutableDictionary dictionary];
             char *url = client->http->url;
             if (url ==  NULL) {
                 p = p->next;
                 continue;
             }
             d[@"url"] = [NSString stringWithCString:url encoding:NSUTF8StringEncoding];
             d[@"method"] = @(client->http->gpc);
             for (int i=0; i < TIME_STAGE_COUNT; i++) {
                 d[[NSString stringWithFormat:@"time%d", i]] = @(client->time_stages[i]);
             }
             d[@"version"] = @(client->http->ver);
             if (client->rule) {
                 d[@"rule"] = [NSString stringWithCString:client->rule
                                                 encoding:NSUTF8StringEncoding];
             }
             d[@"global"] = @(global_mode);
             d[@"routing"] = @(client->routing);
             d[@"forward_stage"] = @(client->current_forward_stage);
             if (client->http->remote_host_ip_addr_str) {
                 d[@"ip"] = [NSString stringWithCString:client->http->remote_host_ip_addr_str
                                               encoding:NSUTF8StringEncoding];
             }
             d[@"responseCode"] = @(client->http->status);
             [records addObject:d];
             p = p->next;
         }
         NSString *result = [records jsonString];
         [weakSelf.wormhole passMessageObject:result identifier:@"tunnelConnectionRecords"];
     }];
    
    
    [self setupStatusSocket];
}

- (void)setupStatusSocket {
    PLog(@"开始使用socket监听127.0.0.1的状态");
    NSError *error;
    self.statusSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    [self.statusSocket acceptOnInterface:@"127.0.0.1" port:0 error:&error];
    [self.statusSocket performBlock:^{
        int port = sock_port(self.statusSocket.socket4FD);
        [[SSFilePath sharedUserDefaults] setObject:@(port) forKey:@"tunnelStatusPort"];
        [[SSFilePath sharedUserDefaults] synchronize];
        PLog(@"socket tunnel 监听 :%@", @(port));
    }];
}


- (void)startProxies {
    PLog(@"proxy : %@", [SSProxy defaultProxy]);
    [self startShadowsocks];
    [self startHttpProxy];
    [self startSocksProxy];
}

- (void)syncStartProxy: (NSString *)name completion: (void(^)(dispatch_group_t g,
                                                              NSError **proxyError))handler {
    dispatch_group_t g = dispatch_group_create();
    __block NSError *proxyError;
    dispatch_group_enter(g);
    handler(g, &proxyError);
    long res = dispatch_group_wait(g, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 2));
    if (res != 0) {
        proxyError = [TunnelError errorWithMessage:@"timeout"];
    }
    if (proxyError) {
        PLog(@"start proxy: %@ error: %@", name, [proxyError localizedDescription]);
        exit(1);
        return;
    }
}

- (void)startShadowsocks {
    [self syncStartProxy: @"shadowsocks" completion:^(dispatch_group_t g,
                                                      NSError *__autoreleasing *proxyError) {
        PLog(@"startShadowsocks");
        [[ProxyManager sharedManager] startShadowsocks:^(int port, NSError *error) {
            *proxyError = error;
            dispatch_group_leave(g);
        }];
    }];
}

- (void)startHttpProxy {
    [self syncStartProxy: @"http" completion:^(dispatch_group_t g,
                                               NSError *__autoreleasing *proxyError) {
        PLog(@"startHttpProxy");
        [[ProxyManager sharedManager] startHttpProxy:^(int port, NSError *error) {
            *proxyError = error;
            dispatch_group_leave(g);
        }];
    }];
}

- (void)startSocksProxy {
    [self syncStartProxy: @"socks" completion:^(dispatch_group_t g,
                                                NSError *__autoreleasing *proxyError) {
        PLog(@"startSocksProxy");
        [[ProxyManager sharedManager] startSocksProxy:^(int port, NSError *error) {
            *proxyError = error;
            dispatch_group_leave(g);
        }];
    }];
}

- (void)startPacketForwarders {
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTun2SocksFinished)
                                                 name:kTun2SocksStoppedNotification
                                               object:nil];
    [self startVPNWithOptions:nil completionHandler:^(NSError *error) {
        if (error == nil) {
            PLog(@"开始defaultPath监听");
            [weakSelf addObserver:weakSelf
                       forKeyPath:@"defaultPath"
                          options:NSKeyValueObservingOptionInitial
                          context:nil];
            PLog(@"开始startTun2Socks端口 ：%@ 监听",
                 @([ProxyManager sharedManager].socksProxyPort));
            [TunnelInterface startTun2Socks:[ProxyManager sharedManager].socksProxyPort];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(0.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                               [TunnelInterface processPackets];
                           });
        }
        if (weakSelf.pendingStartCompletion) {
            weakSelf.pendingStartCompletion(error);
            weakSelf.pendingStartCompletion = nil;
        }
    }];
}

- (void)startVPNWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *error))completionHandler {
    PLog(@"设置虚拟网卡，虚拟地址");
    // 指定的ip 192.189.52.1
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.100.100.1"]
                                                                 subnetMasks:@[@"255.255.255.0"]];
    NSArray *dnsServers = [SSProxy defaultProxy].dns_server;//192.0.2.1
    if (dnsServers.count > 0) {
        //NSLog(@"custom dns servers: %@", dnsServers);
    } else {
        dnsServers = [SystemDNS getSystemDnsServers];
        //NSLog(@"system dns servers: %@", dnsServers);
    }
    ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
    // 服务器ip地址 10.10.10.10
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc]
                                               initWithTunnelRemoteAddress:@"192.100.100.2"];
    //192.0.2.2
    settings.IPv4Settings = ipv4Settings;
    settings.MTU = @(TunnelMTU);
    NEProxySettings* proxySettings = [[NEProxySettings alloc] init];
    NSInteger proxyServerPort = [ProxyManager sharedManager].httpProxyPort;
    NSString *proxyServerName = @"127.0.0.1";
    
    proxySettings.autoProxyConfigurationEnabled = false;
    
    proxySettings.HTTPEnabled = YES;
    proxySettings.HTTPServer = [[NEProxyServer alloc] initWithAddress:proxyServerName
                                                                 port:proxyServerPort];
    proxySettings.HTTPSEnabled = YES;
    proxySettings.HTTPSServer = [[NEProxyServer alloc] initWithAddress:proxyServerName
                                                                  port:proxyServerPort];
    proxySettings.excludeSimpleHostnames = YES;
    settings.proxySettings = proxySettings;
    NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:dnsServers];
    dnsSettings.matchDomains = nil;
    settings.DNSSettings = dnsSettings;
    
    
    if (self.delegate != nil) {
        [self.delegate customSetTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
            if (error) {
                PLog(@"设置虚拟网卡失败");
                if (completionHandler) {
                    completionHandler(error);
                }
            }else{
                PLog(@"设置虚拟网卡成功");
                if (completionHandler) {
                    completionHandler(nil);
                }
            }
        }];
    }
}


- (void)openLog {
    NSString *logFilePath = [SSFilePath sharedLogUrl].path;
    //    if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
    [[NSFileManager defaultManager] createFileAtPath:logFilePath
                                            contents:nil
                                          attributes:nil];
    //    }
    
    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    
    //未捕获的Objective-C异常日志
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
}

void UncaughtExceptionHandler(NSException* exception)
{
    NSString* name = [ exception name ];
    NSString* reason = [ exception reason ];
    NSArray* symbols = [ exception callStackSymbols ]; // 异常发生时的调用栈
    NSMutableString* strSymbols = [ [ NSMutableString alloc ] init ]; //将调用栈拼成输出日志的字符串
    for ( NSString* item in symbols )
    {
        [ strSymbols appendString: item ];
        [ strSymbols appendString: @"\r\n" ];
    }
    
    //将crash日志保存到Document目录下的Log文件夹下
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Log"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:logDirectory]) {
        [fileManager createDirectoryAtPath:logDirectory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    
    NSString *logFilePath = [logDirectory stringByAppendingPathComponent:@"UncaughtException.log"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    NSString *crashString =
    [NSString stringWithFormat:@"<- %@ ->[ Uncaught Exception ]\r\nName: %@,"
     " Reason: %@\r\n[ Fe Symbols Start ]\r\n%@[ Fe Symbols End ]\r\n\r\n",
     dateStr, name, reason, strSymbols];
    //把错误日志写到文件中
    if (![fileManager fileExistsAtPath:logFilePath]) {
        [crashString writeToFile:logFilePath
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
    } else {
        NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        [outFile seekToEndOfFile];
        [outFile writeData:[crashString dataUsingEncoding:NSUTF8StringEncoding]];
        [outFile closeFile];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"defaultPath"] && self) {
        PLog(@"default Path : %@, %ld, %@", self.defaultPath,
             (long)self.defaultPath.status, self.lastPath);
        PLog(@"change dic : %@", change);
        if (self.defaultPath.status == NWPathStatusSatisfied
            && ![self.defaultPath isEqualToPath:self.lastPath]) {
            if (!self.lastPath) {
                self.lastPath = self.defaultPath;
            }else {
                PLog(@"received network change notifcation");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                                   [self startVPNWithOptions:nil completionHandler:nil];
                               });
            }
        }else {
            self.lastPath = self.defaultPath;
        }
    }
}


- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler
{
    // Add code here to start the process of stopping the tunnel.
    PLog(@"stopTunnelWithReason :%@", @(reason));
    [self stop];
    self.pendingStopCompletion = completionHandler;
}

- (void)stop {
    PLog(@"stoping PandaVPN tunnel...");
    [[SSFilePath sharedUserDefaults] setObject:@(0) forKey:@"tunnelStatusPort"];
    [[SSFilePath sharedUserDefaults] synchronize];
    [TunnelInterface stop];
    [self removeObserver:self forKeyPath:@"defaultPath"];
    [[ProxyManager sharedManager] stopHttpProxy];
    [[ProxyManager sharedManager] stopSocksProxy];
    [[ProxyManager sharedManager] stopShadowsocks];
}

- (void)onTun2SocksFinished {
    PLog(@"onTun2SocksFinished");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.pendingStopCompletion) {
        self.pendingStopCompletion();
        self.pendingStopCompletion = nil;
    }
    if (self.delegate != nil) {
        [self.delegate customCancelTunnelWithError:nil];
    }
//    [self cancelTunnelWithError:nil];
    exit(EXIT_SUCCESS);
}

- (void)handleAppMessage:(NSData *)messageData
       completionHandler:(void (^)(NSData *))completionHandler
{
    PLog(@"handleAppMessage");
    // Add code here to handle the message.
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler
{
    // Add code here to get ready to sleep.
    PLog(@"sleeping PandaVPN tunnel...");
    completionHandler();
}

#pragma mark - GCDAsyncSocket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    PLog(@"注册了新的socket");
    self.statusClientSocket = newSocket;
}

#pragma mark            - check connect -

- (void)closeHelper:(BOOL)removeProxy
{
    PLog(@"closeHelper is manual : %@", [NSNumber numberWithBool:removeProxy]);
//    [self disconnectServer];
    if (removeProxy) {
        [SSProxy removeDefault];
    }
    if (self.pendingStartCompletion) {
        self.pendingStartCompletion([NSError errorWithDomain:@"com.plex.plexvpn" code:1001 userInfo:@{NSLocalizedDescriptionKey:@"链接断开"}]);
        self.pendingStartCompletion = nil;
    }
    [self stop];
}

@end

