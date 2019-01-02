//
//  SSProxy.h
//  PandaVPN
//
//  Created by Shoplex on 2016/11/10.
//  Copyright © 2016年 shoplex. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#define PlexProxyErrorDomain @"PlexProxyError_Domain"

// 这个是代理类，储存代理信息
@interface SSProxy : NSObject <NSCoding>

//@property (nonatomic, assign) NSInteger confid;
//@property (nonatomic, strong) NSString * countryFlag;
//@property (nonatomic, strong) NSString * name ;
//@property (nonatomic, strong) NSString * server;
//@property (nonatomic, assign) NSInteger server_port;
//@property (nonatomic, strong) NSString * method;
//@property (nonatomic, strong) NSString * user;
//@property (nonatomic, strong) NSString * password;
//@property (nonatomic, assign) NSInteger timeout;
//@property (nonatomic, strong) NSArray  * dns_server;
//
//@property (nonatomic, strong) NSString * tag;        // 区分线路
//@property (nonatomic, strong) NSString * type;
//@property (nonatomic, strong) NSString * dns; //使用,分割



@property (nonatomic, assign) NSInteger confid;
@property (nonatomic, assign) NSInteger server_port;
@property (nonatomic, assign) NSInteger timeout;


@property (nonatomic, copy) NSString * countryFlag;
@property (nonatomic, copy) NSString * name ;
@property (nonatomic, copy) NSString * server;

@property (nonatomic, copy) NSString * method;
@property (nonatomic, copy) NSString * user;
@property (nonatomic, copy) NSString * password;


@property (nonatomic, copy) NSString * tag;        // 区分线路
@property (nonatomic, copy) NSString * type;
@property (nonatomic, copy) NSString * dns; //使用,分割

@property (nonatomic, strong) NSArray  * dns_server;
@property (nonatomic, strong) NSDictionary *ovpn; // ovpn文件链接


- (void)saveAsDefault;

+ (instancetype)defaultProxy;

+ (void)removeDefault;

- (NSDictionary*)jsonFromProxy;

@end
