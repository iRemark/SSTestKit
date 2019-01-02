//
//  PVDevice.m
//  PandaVPN
//
//  Created by Shoplex on 2017/6/22.
//  Copyright © 2017年 shoplex. All rights reserved.
//

#import "SSDevice.h"
#import "FBEncryptorAES.h"
#import <YYModel/YYModel.h>
#import <sys/utsname.h>
#import "SSFilePath.h"
#import "GetUUID/GetUUID.h"

#define keyForAESApp @"x7x5fTesTWW0Xadw"

NSString * ChangeRequestDomainSuccess = @"changerequestdomainsuccesskey__";

@implementation SSDevice


+ (NSString *)iphoneType {
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c";
    
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c";
    
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s";
    
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s";
    
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
    
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
    
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";
    
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone SE";
    
    if ([platform isEqualToString:@"iPhone9,1"] || [platform isEqualToString:@"iPhone9,3"]) return @"iPhone 7";
    
    if ([platform isEqualToString:@"iPhone9,2"] || [platform isEqualToString:@"iPhone9,4"]) return @"iPhone 7 Plus";
    
    if ([platform isEqualToString:@"iPhone10,1"] || [platform isEqualToString:@"iPhone10,4"]) return @"iPhone 8";
    
    if ([platform isEqualToString:@"iPhone10,2"] || [platform isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus";
    
    if ([platform isEqualToString:@"iPhone10,3"] || [platform isEqualToString:@"iPhone10,6"]) return @"iPhone 8 X";
    
    if ([platform isEqualToString:@"iPod1,1"])   return @"iPod Touch 1G";
    
    if ([platform isEqualToString:@"iPod2,1"])   return @"iPod Touch 2G";
    
    if ([platform isEqualToString:@"iPod3,1"])   return @"iPod Touch 3G";
    
    if ([platform isEqualToString:@"iPod4,1"])   return @"iPod Touch 4G";
    
    if ([platform isEqualToString:@"iPod5,1"])   return @"iPod Touch 5G";
    
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1G";
    
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,4"])   return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini 1G";
    
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad4,1"])   return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,2"])   return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,3"])   return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,4"])   return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"iPad4,5"])   return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"iPad4,6"])   return @"iPad Mini 2G";
    
    if ([platform isEqualToString:@"iPad4,4"]
        ||[platform isEqualToString:@"iPad4,5"]
        ||[platform isEqualToString:@"iPad4,6"])    return @"iPad mini 2";
    
    if ([platform isEqualToString:@"iPad4,7"]
        ||[platform isEqualToString:@"iPad4,8"]
        ||[platform isEqualToString:@"iPad4,9"])    return @"iPad mini 3";
    
    if ([platform isEqualToString:@"iPad5,3"])  return @"iPad Air 2";
    
    if ([platform isEqualToString:@"iPad5,4"])  return @"iPad Air 2";
    
    if ([platform isEqualToString:@"i386"])      return @"iPhone Simulator";
    
    if ([platform isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    
    return platform;
    
}


- (NSString *)description
{
    return [self yy_modelToJSONString];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder { return [super yy_modelInitWithCoder:aDecoder]; }
- (void)encodeWithCoder:(NSCoder *)aCoder { [super yy_modelEncodeWithCoder:aCoder]; }

- (void)saveAsDefault
{
    NSURL * userInfoURL = [SSFilePath sharedDeviceConfUrl];
    NSData * jsonData = [self yy_modelToJSONData];
    NSData * data = [FBEncryptorAES encryptData:jsonData key:[keyForAESApp dataUsingEncoding:NSUTF8StringEncoding]];
    NSString * jsonstring = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSData * keyArchiverData = [NSKeyedArchiver archivedDataWithRootObject:jsonstring];
    [[NSFileManager defaultManager] createFileAtPath:userInfoURL.path contents:keyArchiverData attributes:nil];
}

+ (instancetype)defaultDevice
{
    NSURL * proxyInfo = [SSFilePath sharedDeviceConfUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:proxyInfo.path]) {
        NSData * archiverData = [[NSFileManager defaultManager] contentsAtPath:proxyInfo.path];
        if (archiverData) {
            NSString * jsonstring = [NSKeyedUnarchiver unarchiveObjectWithData:archiverData];
            if (jsonstring) {
                NSData * data = [[NSData alloc] initWithBase64EncodedString:jsonstring options:NSDataBase64DecodingIgnoreUnknownCharacters];
                if (data) {
                    NSData * jsonData = [FBEncryptorAES decryptData:data key:[keyForAESApp dataUsingEncoding:NSUTF8StringEncoding]];
                    if (jsonData) {
                        SSDevice * ddd = [SSDevice yy_modelWithJSON:jsonData];
                        return ddd;
                    }
                }
            }
        }
    }
    SSDevice * ddd = [[SSDevice alloc] init];
    ddd.uuid = [GetUUID getUUID];
    ddd.deviceName = [SSDevice iphoneType];
    [ddd saveAsDefault];
    return ddd;
}

+ (BOOL)isNewVersion {
    BOOL isNewVersion = NO;
    NSString *oldVersionStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"];
#if VPNTEST
    NSString *currentVersionStr = [[[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleVersion"] copy];
#else
    NSString *currentVersionStr = [[[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"] copy];
#endif
    if (oldVersionStr.length > 0) {
        if ([currentVersionStr compare:oldVersionStr options:NSNumericSearch] == NSOrderedDescending) {
            isNewVersion = YES;
        }
    } else {
        isNewVersion = YES;
    }
    return isNewVersion;
}

@end

