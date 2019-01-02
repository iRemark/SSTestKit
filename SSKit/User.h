//
//  User.h
//  PandaVPN
//
//  Created by Shoplex on 2016/11/8.
//  Copyright © 2016年 shoplex. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * USER_LOGING_STATUS_NOTIFICATION_KEY;
extern NSString * USER_INFO_CHANGE_NOTIFICATION_KEY;

@interface User : NSObject <NSCoding>
@property (nonatomic, strong) NSString      *accessToken;
@property (nonatomic, strong) NSString      *dueTime;
@property (nonatomic, strong) NSString      *email;
@property (nonatomic, strong) NSString      *expireAt;

@property (nonatomic, assign) NSInteger     user_id;
@property (nonatomic, strong) NSString      *registerAt;
@property (nonatomic, strong) NSString      *role;
@property (nonatomic, strong) NSString      *userNumber;

@property (nonatomic, strong) NSString      *invitationLink;
@property (nonatomic, assign) NSInteger     maxDeviceCount;

@property (nonatomic, strong) NSString      *webAccessToken;

@property (nonatomic, assign) BOOL          emailChecked;

+ (BOOL)isLogin;
+ (void)logout;

- (void)saveAsDef;
+ (instancetype)userInfo;

@end
