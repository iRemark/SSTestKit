//
//  GetUUID.m
//  Shoplex
//
//  Created by shangjin on 15/3/11.
//  Copyright (c) 2015年 shangjin. All rights reserved.
//

#import "GetUUID.h"
#import "SSKeychain.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#endif

@implementation GetUUID

+ (NSString *)getUUID
{
    NSString *retrieveuuid = [SSKeychain passwordForService:@"com.plex.Shoplex" account:@"uuid"];
    if ( retrieveuuid == nil || [retrieveuuid isEqualToString:@""])
    {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        assert(uuid != NULL);
        CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
        retrieveuuid = [NSString stringWithFormat:@"%@", uuidStr];
        CFAutorelease(uuidStr);
        CFAutorelease(uuid);
        
        [SSKeychain setPassword:retrieveuuid forService:@"com.plex.Shoplex" account:@"uuid"];
    }
    
    NSString*sRetUUID = @"";
    if (retrieveuuid != nil) {
        sRetUUID = retrieveuuid;
    }
    else {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        //        sRetUUID = @"null";
        // 设置uuid
        sRetUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#else
        sRetUUID = @"null";
#endif
    }
    return sRetUUID;
}

+ (BOOL)isFirstInstall {
    NSString *retrieveuuid = [SSKeychain passwordForService:@"com.panda.pandavpn"account:@"firstInstall"];
    if ( retrieveuuid == nil || [retrieveuuid isEqualToString:@""])
    {
        [SSKeychain setPassword:@"false"
                             forService:@"com.panda.pandavpn"account:@"firstInstall"];
        return true;
        
    } else {
        return false;
    }
}

@end
