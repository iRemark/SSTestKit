//
//  Manager.m
//  PandaVPN
//
//  Created by Shoplex on 2016/11/11.
//  Copyright © 2016年 shoplex. All rights reserved.
//

#import "VPNManager.h"
#import "JSONUtils.h"
#import <MMWormhole/MMWormhole.h>
#import "SSFilePath.h"
#import "Settings.h"


@interface VPNManager ()

@property (nonatomic, readwrite, assign) VPNStatus vpnStatus;

@property (nonatomic, readwrite, strong)NEVPNManager *currentVPNManager;

@end

@implementation VPNManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setVpnStatus:(VPNStatus)vpnStatus
{
    _vpnStatus = vpnStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:kProxyServiceVPNStatusNotification object:nil];
}

+ (instancetype)sharedManager
{
    static VPNManager * shared_Manager;
    static dispatch_once_t onceManagerToken;
    dispatch_once(&onceManagerToken, ^{
        shared_Manager = [[VPNManager alloc] init];
    });
    return shared_Manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _vpnStatus = VPNStatus_Off;
        self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:sharedGroupIdentifier optionalDirectory:@"wormhole"];
        __weak __typeof__(self) weakSelf = self;
        [self.wormhole listenForMessageWithIdentifier:@"startTunnel" listener:^(id  _Nullable messageObject) {
            // 不一定要有用户，并且用户不是第一次打开
//            if ([[User userInfo] user_id] > 0) {
                // 不是第一次打开
                if ([Settings shared].isLinked) {
                    __strong __typeof__(weakSelf) strongSelf = weakSelf;
                    [strongSelf startVPN:^(NETunnelProviderManager *manager, NSError *err) {
                        [weakSelf.wormhole passMessageObject:err identifier:@"err"];
                    }];
                } else {
                    [weakSelf.wormhole passMessageObject:[NSError errorWithDomain:PlexProxyErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"no config"}] identifier:@"err"];
                }
//            } else {
//                [weakSelf.wormhole passMessageObject:[NSError errorWithDomain:PlexProxyErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"no user"}] identifier:@"err"];
//            }
        }];
        self.observerAdded = false;
    }
    
    if ([Settings shared].isLinked) {
        [self loadProviderManager:^(NETunnelProviderManager *manager) {
            if (manager) {
                [self updateVPNStatus:manager];
                [self addVpnStatusObserver];
            }
        }];
    }
    return self;
}

- (void)addVpnStatusObserver
{
    if (!self.observerAdded) {
        [self loadAndCreateProviderManager:^(NETunnelProviderManager * manager, NSError * err) {
            self.observerAdded = true;
            [[NSNotificationCenter defaultCenter] addObserverForName:NEVPNStatusDidChangeNotification object:manager.connection queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                [self updateVPNStatus:manager];
            }];
        }];
    }
}

- (NEVPNManager *)currentManager{
    return self.currentVPNManager;
}

- (void)updateVPNStatus:(NEVPNManager *)manager
{
    self.currentVPNManager = manager;
    switch (manager.connection.status) {
        case NEVPNStatusConnected:
            self.vpnStatus = VPNStatus_On;
            break;
        case NEVPNStatusConnecting:
        case NEVPNStatusReasserting:
            self.vpnStatus = VPNStatus_Connecting;
            break;
        case NEVPNStatusDisconnecting:
            self.vpnStatus = VPNStatus_DisConnecting;
            break;
        case NEVPNStatusDisconnected:
        case NEVPNStatusInvalid:
            self.vpnStatus = VPNStatus_Off;
            break;
            
        default:
            self.vpnStatus = VPNStatus_Off;
            break;
    }
}

- (void)switchVPN:(void (^)(NETunnelProviderManager *, NSError * err))completion
{
    [self loadProviderManager:^(NETunnelProviderManager * manager) {
        if (manager) {
            [self updateVPNStatus:manager];
        }
        VPNStatus current = self.vpnStatus;
        if (current != VPNStatus_Connecting && current != VPNStatus_DisConnecting) {
            if (current == VPNStatus_Off) {
                [self startVPN:^(NETunnelProviderManager * manager1, NSError * err) {
                    if (completion) {
                        completion(manager1, err);
                    }
                }];
            } else {
                [self stopVPN];
                if (completion) {
                    completion(nil, nil);
                }
            }
        }
    }];
}

- (void)switchVPNFromTodayWidget:(NSExtensionContext *)context
{
    // today控件
//    NSURL * url = [NSURL URLWithString:@"pandavpn://switch"];
//    [context openURL:url completionHandler:nil];
    [self switchVPN:nil];
}

//- (void)setup
//{
//    [DefaultRealm setupDefaultRealm];
//    @try {
//        [self copyGEOIPData];
//    } @catch (NSException *exception) {
//    } @finally {
//        @try {
//            [self copyTemplateData];
//        } @catch (NSException *exception) {
//        } @finally {
//            
//        }
//    }
//}

// 复制geoIP
- (void)copyGEOIPData
{
    NSURL * fromURL = [[NSBundle mainBundle] URLForResource:@"GeoLite2-Country" withExtension:@"mmdb"];
    if (fromURL) {
        NSURL * toURL = [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"GeoLite2-Country.mmdb"];
        NSFileManager * fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:fromURL.path]) {
            NSError* error = nil;
            if ([fileManager fileExistsAtPath:toURL.path]) {
                [fileManager removeItemAtURL:toURL error:&error];
                if (error) {
                    @throw [NSException exceptionWithName:@"get geoip failed" reason:error.localizedDescription userInfo:error.userInfo];
                }
            }
            [fileManager copyItemAtURL:fromURL toURL:toURL error:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"get geoip failed" reason:error.localizedDescription userInfo:error.userInfo];
            }
        }
    }
}

- (void)copyTemplateData
{
    NSURL * bundleURL = [[NSBundle mainBundle] URLForResource:@"template" withExtension:@"bundle"];
    if (bundleURL) {
        NSError* error = nil;
        NSFileManager * fileManager = [NSFileManager defaultManager];
        NSURL* confDirUrl = [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"httpconf"];
        NSURL * toDirectoryURL = [confDirUrl URLByAppendingPathComponent:@"templates"];
        if (![fileManager fileExistsAtPath:toDirectoryURL.path]) {
            [fileManager createDirectoryAtURL:toDirectoryURL withIntermediateDirectories:true attributes:nil error:&error];
            if (error) {
                @throw [NSException exceptionWithName:@"get httptemplate failed" reason:error.localizedDescription userInfo:error.userInfo];
            }
        }
        for (NSString* file in [fileManager contentsOfDirectoryAtPath:bundleURL.path error:nil]) {
            NSURL * destURL = [toDirectoryURL URLByAppendingPathComponent:file];
            NSURL * dataURL = [bundleURL URLByAppendingPathComponent:file];
            if ([fileManager fileExistsAtPath:dataURL.path]) {
                if ([fileManager fileExistsAtPath:destURL.path]) {
                    [fileManager removeItemAtURL:destURL error:&error];
                    if (error) {
                        @throw [NSException exceptionWithName:@"remove dest failed" reason:error.localizedDescription userInfo:error.userInfo];
                    }
                }
                [fileManager copyItemAtPath:dataURL.path toPath:destURL.path error:&error];
                if (error) {
                    @throw [NSException exceptionWithName:@"cope http template failed" reason:error.localizedDescription userInfo:error.userInfo];
                }
            }
        }
    }
}

- (void)generatePACFile
{
    NSString * pacPath = [SSFilePath sharedPACUrl].path;
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * src = [[NSBundle mainBundle] pathForResource:@"gfwlist" ofType:@"txt"];
    [manager copyItemAtPath:src toPath:[SSFilePath sharedGFWFileUrl].path error:nil];
    if (![manager fileExistsAtPath:pacPath]) {
        // If gfwlist.txt is not exsited, copy from bundle
        if (![manager fileExistsAtPath:[SSFilePath sharedGFWFileUrl].path]) {
        }
    }
    NSString * gfwlist = [NSString stringWithContentsOfFile:[SSFilePath sharedGFWFileUrl].path encoding:NSUTF8StringEncoding error:nil];
    
    if ([manager fileExistsAtPath:[SSFilePath sharedAPIGFWListUrl].path]){
        NSData * data = [manager contentsAtPath:[SSFilePath sharedAPIGFWListUrl].path];
        NSString *datastr  = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        if (![datastr isEqualToString:@""]) {
            gfwlist = datastr;
        }
    }
    
    NSData * data = [[NSData alloc] initWithBase64EncodedString:gfwlist options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (data) {
        // 可能导致崩溃 objc_exception_throw 
        NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableArray * lines = [NSMutableArray arrayWithArray:[str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
        if (lines.count > 0) {
            NSArray * temp = [lines filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* s, NSDictionary * bindings) {
                if (s.length > 0) {
                    NSString* c = [s substringToIndex:1];
                    if ([c isEqualToString:@"!"] || [c isEqualToString:@"["]) {
                        return false;
                    }
                    return true;
                }
                return false;
            }]];
            lines = [NSMutableArray arrayWithArray:temp];
        }
        if (lines.count > 0) {
            NSData * rulesJsonData = [NSJSONSerialization dataWithJSONObject:lines options:NSJSONWritingPrettyPrinted error:nil];
            NSString * rulesJosonString = [[NSString alloc] initWithData:rulesJsonData encoding:NSUTF8StringEncoding];
            if (rulesJosonString.length <= 0) {
                rulesJosonString = @"";
            }
            NSString * jspath = [[NSBundle mainBundle] URLForResource:@"abp" withExtension:@"js"].path;
            
            NSData * jsdata = [NSData dataWithContentsOfFile:jspath];
            
            NSString * jsStr = [[NSString alloc] initWithData:jsdata encoding:NSUTF8StringEncoding];
            
            jsStr = [jsStr stringByReplacingOccurrencesOfString:@"__RULES__" withString:rulesJosonString];
            
            [[jsStr dataUsingEncoding:NSUTF8StringEncoding] writeToFile:pacPath options:NSDataWritingAtomic error:nil];
            
        }
    }
    
}

- (void)generateAclFile
{
    NSString * pacPath = [SSFilePath sharedAclUrl].path;
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * src = [[NSBundle mainBundle] pathForResource:@"gfwlist" ofType:@"acl"];
    [manager copyItemAtPath:src toPath:pacPath error:nil];
}

- (void)regenerateConfigFiles
{
    [self generateGeneralConfig];
    [self generateSocksConfig];
    [self generateHttpProxyConfig];
}

- (SSProxy *)upstreamProxy
{
    return [SSProxy defaultProxy];
}

- (void)generateGeneralConfig
{
    NSURL * confURL = [SSFilePath sharedGeneralConfUrl];
    NSDictionary * json = @{@"dns" : self.upstreamProxy.dns?:@""};
    [json.jsonString writeToURL:confURL atomically:true encoding:NSUTF8StringEncoding error:nil];
}

- (void)generateSocksConfig
{
    /*
     xml结果
     <antinatconfig><interface value="127.0.0.1"></interface><port value="0"></port><maxbindwait value="10"></maxbindwait><authchoice><select mechanism="anonymous"></select></authchoice><chain name="PandaVPN"><uri value="socks5://127.0.0.1:${ssport}"></uri><authscheme value="anonymous"></authscheme></chain><filter><accept></accept></filter></antinatconfig>
     
     */
    NSString * socksConf = @"<antinatconfig><interface value=\"127.0.0.1\"></interface><port value=\"0\"></port><maxbindwait value=\"10\"></maxbindwait><authchoice><select mechanism=\"anonymous\"></select></authchoice><chain name=\"PandaVPN\"><uri value=\"socks5://127.0.0.1:${ssport}\"></uri><authscheme value=\"anonymous\"></authscheme></chain><filter><accept></accept></filter></antinatconfig>";
    [socksConf writeToURL:[SSFilePath sharedSocksConfUrl] atomically:true encoding:NSUTF8StringEncoding error:nil];
}

- (void)generateHttpProxyConfig
{
    NSURL* rootURL = [SSFilePath sharedUrl];
    NSURL* confDirUrl = [rootURL URLByAppendingPathComponent:@"httpconf"];
    NSString* templateDirPath = [rootURL URLByAppendingPathComponent:@"templates"].path;
    NSString* temproaryDirPath = [rootURL URLByAppendingPathComponent:@"httptemporary"].path;
    NSString* logDir = [rootURL URLByAppendingPathComponent:@"log"].path;
    NSURL* userActionUrl = [confDirUrl URLByAppendingPathComponent:@"pandavpn.action"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    for (NSString * p in @[confDirUrl.path, templateDirPath, temproaryDirPath, logDir]) {
        if (![fileManager fileExistsAtPath:p]) {
            [fileManager createDirectoryAtPath:p withIntermediateDirectories:true attributes:nil error:nil];
        }
    }
    
    [self generatePACFile];
    [self generateAclFile];
    
    NSMutableArray * actionContent = [NSMutableArray array];
    
    [actionContent addObject:@"{+forward-rule}"];
    NSMutableArray * dnses = [NSMutableArray array];
    for (NSString * dns  in [Pollution dnsList]) {
        [dnses addObject:[NSString stringWithFormat:@"DNS-IP-CIDR, %@/32, PROXY", dns]];
    }
    [actionContent addObjectsFromArray:dnses];
    
    NSString * userActionString = [actionContent componentsJoinedByString:@"\n"];
    [userActionString writeToFile:userActionUrl.path atomically:true encoding:NSUTF8StringEncoding error:nil];
    
    NSMutableDictionary* mainConfig = [NSMutableDictionary dictionary];
    [mainConfig setObject:confDirUrl.path forKey:@"confdir"];
    [mainConfig setObject:logDir forKey:@"logdir"];
    [mainConfig setObject:@(1) forKey: @"global-mode"];
    [mainConfig setObject:@(131071) forKey:@"debug"];
    [mainConfig setObject:userActionUrl.path forKey:@"actionsfile"];
    
    NSMutableArray * arr = [NSMutableArray array];
    [mainConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [arr addObject:[NSString stringWithFormat:@"%@ %@", key, obj]];
    }];
    
    NSString* mainContent = [arr componentsJoinedByString:@"\n"];
    [mainContent writeToURL:[SSFilePath sharedHttpProxyConfUrl] atomically:true encoding:NSUTF8StringEncoding error:nil];
    
}

- (void)isVPNStarted:(void (^)(BOOL, NETunnelProviderManager *))complete
{
    [self loadProviderManager:^(NETunnelProviderManager * manager) {
        if (complete) {
            complete(manager.connection.status == NEVPNStatusConnected, manager);
        }
    }];
}

- (void)startVPN:(void (^)(NETunnelProviderManager *, NSError*))complete
{
    [self startVPNWithOptions:nil complete:complete];
}


- (void)startVPNWithOptions:(NSDictionary*)options complete:(void(^)(NETunnelProviderManager*m, NSError* e))complete
{
    [[VPNManager sharedManager] regenerateConfigFiles];
    [self loadAndCreateProviderManager:^(NETunnelProviderManager * manager, NSError* error) {
        if (error) {
            if (complete) {
                complete(nil, error);
            }
        } else {
            if (manager) {
                if (manager.connection.status == NEVPNStatusDisconnected || manager.connection.status == NEVPNStatusInvalid) {
                    NSError * error1 = nil;
                    [manager.connection startVPNTunnelWithOptions:options andReturnError:&error1];
                    if (error1) {
                        if (complete) {
                            complete(nil, error1);
                        }
                    } else {
                        [self addVpnStatusObserver];
                        if (complete) {
                            complete(manager, nil);
                        }
                    }
                }
            } else {
                if (complete) {
                    complete(nil, nil);
                }
            }
        }
    }];
}

- (void)stopVPN
{
    [self loadProviderManager:^(NETunnelProviderManager *manager) {
        if (manager) {
            [manager.connection stopVPNTunnel];
        }
    }];
}

- (void)postMessage
{
    [self loadProviderManager:^(NETunnelProviderManager *manager) {
        NETunnelProviderSession * session = (NETunnelProviderSession*)[manager connection];
        NSData * message = [@"Hello" dataUsingEncoding:NSUTF8StringEncoding];
        if (manager.connection.status != NEVPNStatusInvalid) {
            NSError * error;
            [session sendProviderMessage:message returnError:&error responseHandler:^(NSData * _Nullable responseData) {
                
            }];
            if (error) {
                PLog(@"Failed to send a message to the provider");
            }
        }
    }];
}

- (void)loadAndCreateProviderManager:(void(^)(NETunnelProviderManager*, NSError*))complete
{
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (managers) {
            NETunnelProviderManager * manager;
            if (managers.count > 0) {
                manager = [managers firstObject];
            } else {
                manager = [self createProviderManager];
            }
            manager.enabled = true;
            manager.localizedDescription = @"PandaVPN";
            if (!manager.protocolConfiguration) {
                manager.protocolConfiguration = [[NETunnelProviderProtocol alloc] init];
            }

            manager.protocolConfiguration.serverAddress = @"PandaVPN";
//            manager.onDemandEnabled = true;
//            // 快速启动栏目, 在todayWidget中使用"https:// on-demand.connect.plexvpn.com/start/" 这样的链接打开vpn
//            // 所以，todayWidget并不是重新初始化一个vpn，而是根据配置的rules管理vpn
//            NEOnDemandRuleEvaluateConnection * quickStartRule = [[NEOnDemandRuleEvaluateConnection alloc] init];
//            NEEvaluateConnectionRule * evaluateRule = [[NEEvaluateConnectionRule alloc] initWithMatchDomains:@[@"plexvpnspvd.com"] andAction:NEEvaluateConnectionRuleActionConnectIfNeeded];
//            quickStartRule.connectionRules = @[evaluateRule];
//            manager.onDemandRules = @[quickStartRule];
            [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error1) {
                if (error1) {
                    if (complete) {
                        complete(nil, error1);
                    }
                } else {
                    if (![Settings shared].isLinked) {
                        [[Settings shared] setIsLinked:true];
                    }
                    [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error2) {
                        if (error2) {
                            if (complete) {
                                complete(nil, error2);
                            }
                        } else {
                            if (complete) {
                                complete(manager, nil);
                            }
                        }
                    }];
                }
            }];
            
        } else {
            if (complete) {
                complete(nil, error);
            }
        }
    }];
}

- (void)loadProviderManager:(void (^)(NETunnelProviderManager *))complete
{
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (managers.count > 0) {
            if (complete) {
                complete([managers firstObject]);
            }
        } else {
            if (complete) {
                complete(nil);
            }
        }
    }];
}

- (NETunnelProviderManager*)createProviderManager
{
    NETunnelProviderManager* manager = [[NETunnelProviderManager alloc] init];
    manager.protocolConfiguration = [[NETunnelProviderProtocol alloc] init];
    return manager;
}


@end

