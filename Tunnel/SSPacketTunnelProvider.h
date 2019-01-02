//
//  PacketTunnelProvider.h
//  tunnel
//
//  Created by xiaoyu on 2018/9/26.
//  Copyright © 2018年 xiaoyu. All rights reserved.
//

 

@import NetworkExtension;


@protocol SSPacketTunnelProviderProtocol <NSObject>
- (void)customCancelTunnelWithError:(nullable NSError *)error;
- (void)customSetTunnelNetworkSettings:(nullable NETunnelNetworkSettings *)tunnelNetworkSettings completionHandler:(nullable void (^)( NSError * __nullable error))completionHandler;
@end

//NEPacketTunnelProvider

@interface SSPacketTunnelProvider: NSObject
    
@property NEPacketTunnelFlow *packetFlow;
@property (nullable) NWPath *defaultPath;
    
@property (weak) id<SSPacketTunnelProviderProtocol> delegate;
    
- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler;
- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler;
    
@end
