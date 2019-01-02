//
//  PotatsoManager.h
//  Potatso
//
//  Created by LEI on 4/4/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PLog(__FORMAT__, ...) NSLog((@"%s line %d $ " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

extern NSString * _Nonnull sharedGroupIdentifier;
//extern NSString * _Nonnull shareUserDefaultsId;


@interface SSFilePath : NSObject
+ (NSURL * _Nonnull)sharedUrl;
+ (NSUserDefaults * _Nonnull)sharedUserDefaults;

+ (NSURL * _Nonnull)sharedPACUrl;
+ (NSURL * _Nonnull)sharedGFWFileUrl;

+ (NSURL * _Nonnull)sharedAPIGFWListUrl;

+ (NSURL * _Nonnull)sharedAclUrl;
+ (NSURL * _Nonnull)sharedGeneralConfUrl;
+ (NSURL * _Nonnull)sharedProxyConfUrl;
+ (NSURL * _Nonnull)sharedDeviceConfUrl;
+ (NSURL * _Nonnull)sharedHostUrl;
+ (NSURL * _Nonnull)sharedUserUrl;
+ (NSURL * _Nonnull)sharedSocksConfUrl;
+ (NSURL * _Nonnull)sharedHttpProxyConfUrl;
+ (NSURL * _Nonnull)sharedLogUrl;
+ (NSURL * _Nonnull)sharedshadowsocksLogUrl;


@end
