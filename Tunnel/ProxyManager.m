//
//  ProxyManager.m
//  Potatso
//
//  Created by LEI on 2/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import "ProxyManager.h"
#import <ShadowPath/ShadowPath.h>

#import <netinet/in.h>
#import <arpa/inet.h>

#import "SSProxy.h"
#import "SSDevice.h"
#import "SSFilePath.h"

 
@interface ProxyManager ()

@property (nonatomic) int socksProxyPort;
@property (nonatomic) int httpProxyPort;
@property (nonatomic) int shadowsocksProxyPort;


@property (nonatomic) BOOL socksProxyRunning;
@property (nonatomic) BOOL httpProxyRunning;

@property (nonatomic) BOOL shadowsocksProxyRunning;

@property (nonatomic, copy) SocksProxyCompletion socksCompletion;
@property (nonatomic, copy) HttpProxyCompletion httpCompletion;
@property (nonatomic, copy) ShadowsocksProxyCompletion shadowsocksCompletion;

@property (nonatomic, assign) void* listen;


- (void)onSocksProxyCallback:(int)fd;

- (void)onHttpProxyCallback:(int)fd;

- (void)onShadowsocksCallback:(int)fd;

@end


void http_proxy_handler(int fd, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    [provider onHttpProxyCallback:fd];
}

void shadowsocks_handler(void* listen, int fd, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    provider.listen = listen;
    [provider onShadowsocksCallback:fd];
}


int sock_port (int fd) {
    struct sockaddr_in sin;
    socklen_t len = sizeof(sin);
    if (getsockname(fd, (struct sockaddr *)&sin, &len) < 0) {
        PLog(@"getsock_port(%d) error: %s",
              fd, strerror (errno));
        return 0;
    } else {
        return ntohs(sin.sin_port);
    }
}


NSString* sock_host (int fd) {
    struct sockaddr_in sin;
    socklen_t len = sizeof(sin);
    if (getsockname(fd, (struct sockaddr *)&sin, &len) < 0) {
        PLog(@"getsock_port(%d) error: %s",
              fd, strerror (errno));
        return nil;
    } else {
        char ip[20] = {0};
        inet_ntop(AF_INET, &sin.sin_addr, ip, sizeof(ip));
        NSString* strIPAddress = [NSString stringWithUTF8String:ip];
        return strIPAddress;
    }
}



@implementation ProxyManager

+ (ProxyManager *)sharedManager {
    static dispatch_once_t onceProxyToken;
    static ProxyManager *manager;
    dispatch_once(&onceProxyToken, ^{
        manager = [ProxyManager new];
    });
    return manager;
}

- (void)startSocksProxy:(SocksProxyCompletion)completion {
    self.socksCompletion = [completion copy];
    // TODO: start config from there
    NSString *confContent = [NSString stringWithContentsOfURL:[SSFilePath sharedSocksConfUrl] encoding:NSUTF8StringEncoding error:nil];
    confContent = [confContent stringByReplacingOccurrencesOfString:@"${ssport}" withString:[NSString stringWithFormat:@"%d", [self shadowsocksProxyPort]]];
    PLog(@"将要开始AntinatServer config :%@", confContent);
    int fd = [[AntinatServer sharedServer] startWithConfig:confContent];
    [self onSocksProxyCallback:fd];
}

- (void)stopSocksProxy {
    [[AntinatServer sharedServer] stop];
    self.socksProxyRunning = NO;
}

- (void)onSocksProxyCallback:(int)fd {
    NSError *error;
    if (fd > 0) {
        self.socksProxyPort = sock_port(fd);
        self.socksProxyRunning = YES;
        PLog(@"socks 另一个代理 port %@:%@", sock_host(fd), @(self.socksProxyPort));
    }else {
        error = [NSError errorWithDomain:@"com.plex.plexvpn" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start socks proxy"}];
        PLog(@"socks 代理 失败");
    }
    if (self.socksCompletion) {
        self.socksCompletion(self.socksProxyPort, error);
    }
}

# pragma mark - Shadowsocks 

- (void)startShadowsocks: (ShadowsocksProxyCompletion)completion {
    self.shadowsocksCompletion = [completion copy];
    [NSThread detachNewThreadSelector:@selector(_startShadowsocks) toTarget:self withObject:nil];
}

- (void)_startShadowsocks {
    SSProxy * proxy = [SSProxy defaultProxy];
    proxy = [SSProxy new];
    
    if (!proxy) {
        if (self.shadowsocksCompletion) {
            self.shadowsocksCompletion(0, nil);
        }
        return;
    }
    NSString *host = proxy.server;
    NSNumber *port = @(proxy.server_port);
    NSString *password = proxy.password;
    NSString *authscheme = proxy.method;
    NSInteger timeout = proxy.timeout;
    
    host = @"195.123.240.79";
    port = @(46056);
    password = @"3d697442eb064d72a9ff93f46e9104e5c47bfd17c85f4deed3083d277ed9ab4a";
    authscheme = @"chacha20-ietf-poly1305";
    timeout = 600;
    
    if (host && port && password && authscheme) {
        profile_t profile;
        memset(&profile, 0, sizeof(profile_t));
        profile.remote_host = strdup([host UTF8String]);
        profile.remote_port = [port intValue];
        profile.password = strdup([password UTF8String]);
        profile.method = strdup([authscheme UTF8String]);
        profile.local_addr = "127.0.0.1";
        profile.local_port = 0;
        profile.timeout = (int)timeout;
        profile.mode = 1;
        
        if ([SSDevice defaultDevice].autoConfig) {
            profile.acl = strdup([[SSFilePath sharedAclUrl].path UTF8String]);
        }
#if VPNTEST
        profile.log = strdup([[PandaVPN sharedshadowsocksLogUrl].path UTF8String]);
#endif
//        if (protocol.length > 0) {
//            profile.protocol = strdup([protocol UTF8String]);
//        }
//        if (obfs.length > 0) {
//            profile.obfs = strdup([obfs UTF8String]);
//        }
//        if (obfs_param.length > 0) {
//            profile.obfs_param = strdup([obfs_param UTF8String]);
//        }
        PLog(@"start local");
        start_ss_local_server(profile, shadowsocks_handler, (__bridge void *)self);
    } else {
        PLog(@"代理数据不全");
        if (self.shadowsocksCompletion) {
            self.shadowsocksCompletion(0, nil);
        }
        return;
    }
}

- (void)stopShadowsocks {
    // Do nothing
    plexsocks_servver_stop(self.listen);
}

- (void)onShadowsocksCallback:(int)fd {
    NSError *error;
    if (fd > 0) {
        self.shadowsocksProxyPort = sock_port(fd);
        self.shadowsocksProxyRunning = YES;
    }else {
        error = [NSError errorWithDomain:@"com.plex.plexvpn" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
    }
    PLog(@"shadowsocks 运行状态:%@ 接口为 %@:%@", fd > 0 ? @"良好" : @"关闭", sock_host(fd), @(self.shadowsocksProxyPort));
    if (self.shadowsocksCompletion) {
        self.shadowsocksCompletion(self.shadowsocksProxyPort, error);
    }
}

# pragma mark - Http Proxy

- (void)startHttpProxy:(HttpProxyCompletion)completion {
    self.httpCompletion = [completion copy];
    [NSThread detachNewThreadSelector:@selector(_startHttpProxy:) toTarget:self withObject:[SSFilePath sharedHttpProxyConfUrl]];
}

- (void)_startHttpProxy: (NSURL *)confURL {
    struct forward_spec *proxy = NULL;
    if (self.shadowsocksProxyPort > 0) {
        proxy = (malloc(sizeof(struct forward_spec)));
        memset(proxy, 0, sizeof(struct forward_spec));
        proxy->type = SOCKS_5;
        proxy->gateway_host = "127.0.0.1";
        proxy->gateway_port = self.shadowsocksProxyPort;
        PLog(@"http代理：%s:%@", proxy->gateway_host, @(proxy->gateway_port));
    } else {
        PLog(@"http 代理失败");
    }
    shadowpath_main(strdup([[confURL path] UTF8String]), proxy, http_proxy_handler, (__bridge void *)self);
}

- (void)stopHttpProxy {
//    polipoExit();
//    self.httpProxyRunning = NO;
}

- (void)onHttpProxyCallback:(int)fd {
    NSError *error;
    if (fd > 0) {
        self.httpProxyPort = sock_port(fd);
        self.httpProxyRunning = YES;
        PLog(@"http 代理 另一个接口 ：   %@:%@", sock_host(fd), @(self.httpProxyPort));
    }else {
        error = [NSError errorWithDomain:@"com.plex.plexvpn" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
        PLog(@"http 代理 另一个接口 失败");
    }
    if (self.httpCompletion) {
        self.httpCompletion(self.httpProxyPort, error);
    }
}

@end

