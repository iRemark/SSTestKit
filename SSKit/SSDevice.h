//
//  PVDevice.h
//  PandaVPN
//
//  Created by Shoplex on 2017/6/22.
//  Copyright © 2017年 shoplex. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * ChangeRequestDomainSuccess;

@interface SSDevice : NSObject

@property (nonatomic, copy) NSString * uuid;
@property (nonatomic, copy) NSString * deviceName;
@property (nonatomic, copy) NSString * userDomain;      /**< 用户手动输入的域名*/

@property (nonatomic, assign) BOOL  autoConfig;


+ (BOOL)isNewVersion;
+ (instancetype) defaultDevice;
- (void)saveAsDefault;

@end
