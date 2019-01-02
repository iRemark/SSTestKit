//
//  PotatsoManager.m
//  Potatso
//
//  Created by LEI on 4/4/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import "SSFilePath.h"

NSString *sharedGroupIdentifier = @"group.com.pandavpn.proxy";
NSString *shareUserDefaultsId = @"SVSGPEU58N.group.com.pandavpn.proxy";

@implementation SSFilePath

+ (NSURL *)sharedUrl {
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:sharedGroupIdentifier];
}

+ (NSUserDefaults *)sharedUserDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:sharedGroupIdentifier];
}

+ (NSURL * _Nonnull)sharedAclUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"gfwlist.acl"];
}

+ (NSURL * _Nonnull)sharedPACUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"pac.xxx"];
}

+ (NSURL * _Nonnull)sharedGFWFileUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"gfw.xxx"];
}

+ (NSURL * _Nonnull)sharedAPIGFWListUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"gfwlist.apilist"];
}

+ (NSURL * _Nonnull)sharedGeneralConfUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"general.xxx"];
}

+ (NSURL *)sharedSocksConfUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"socks.xxx"];
}

+ (NSURL *)sharedProxyConfUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"proxy.xxx"];
}

+ (NSURL *)sharedDeviceConfUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"device.xxx"];
}

+ (NSURL * _Nonnull)sharedHostUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"host.xxx"];
}

+ (NSURL * _Nonnull)sharedUserUrl
{
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"user.xxx"];
}

+ (NSURL *)sharedHttpProxyConfUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"http.xxx"];
}

+ (NSURL * _Nonnull)sharedLogUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"tunnel.log"];
}

+ (NSURL * _Nonnull)sharedshadowsocksLogUrl {
    return [[SSFilePath sharedUrl] URLByAppendingPathComponent:@"shadowsocks.log"];
}

@end



