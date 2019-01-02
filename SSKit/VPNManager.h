//
//  Manager.h
//  PandaVPN
//
//  Created by Shoplex on 2016/11/11.
//  Copyright © 2016年 shoplex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import "Pollution.h"
#import "SSProxy.h"


@class MMWormhole;

typedef enum : NSUInteger {
    ManagerError_InvalidProvider,
    ManagerError_VPNStartFail,
} ManagerError;

typedef ManagerError ManagerError;

typedef enum : NSUInteger {
    VPNStatus_Off,
    VPNStatus_On,
    VPNStatus_Connecting,
    VPNStatus_DisConnecting,
} VPNStatus;

typedef VPNStatus VPNStatus;



#define kDefaultGroupIdentifier @"defaultGroup"
#define kDefaultGroupName @"defaultGroupName"
#define statusIdentifier @"statusid"
#define kProxyServiceVPNStatusNotification @"kProxyServiceVPNStatusNotification"




// PandaVPN状态和默认参数调度，此类保存了一个通道管理器的实例，方便使用
// 同时此管理器也负责苹果手表的调度MMWormhole
@interface VPNManager : NSObject

@property (nonatomic, readonly, assign) VPNStatus vpnStatus;

@property (nonatomic, strong) MMWormhole * wormhole;
@property (nonatomic, assign) BOOL observerAdded;


+ (instancetype)sharedManager;

// 添加vpn监听
- (void)addVpnStatusObserver;

- (NEVPNManager *)currentManager;

// 更新vpn状态
- (void)updateVPNStatus:(NEVPNManager*)manager;

// 开关vpn
- (void)switchVPN:(void(^)(NETunnelProviderManager* manager, NSError * err))completion;

// 今日
- (void)switchVPNFromTodayWidget:(NSExtensionContext*)context;

// 重新生成配置文件
- (void)regenerateConfigFiles;


@end



@interface VPNManager ()

// 配置属性
@property (nonatomic, strong) SSProxy * upstreamProxy;

@property (nonatomic, assign) BOOL defaultToProxy;

// 生成配置
- (void)generateGeneralConfig;
- (void)generateSocksConfig;
- (void)generateHttpProxyConfig;

// vpn状态是打开的
- (void)isVPNStarted:(void(^)(BOOL isStarted, NETunnelProviderManager* manager))complete;
// 打开vpn
- (void)startVPN:(void(^)(NETunnelProviderManager* manager, NSError* err))complete;

- (void)startVPNWithOptions:(NSDictionary*)options complete:(void(^)(NETunnelProviderManager*m, NSError* e))complete;
// 关闭vpn
- (void)stopVPN;
// 发送消息
- (void)postMessage;
// 加载通道
- (void)loadProviderManager:(void(^)(NETunnelProviderManager* manager))complete;

@end
