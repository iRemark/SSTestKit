//
//  User.m
//  PandaVPN
//
//  Created by Shoplex on 2016/11/8.
//  Copyright © 2016年 shoplex. All rights reserved.
//

#import "User.h"
#import <YYModel/YYModel.h>
#import "SSProxy.h"
#import "SSFilePath.h"
#import "FBEncryptorAES.h"

NSString * USER_LOGING_STATUS_NOTIFICATION_KEY = @"USER_LOGING_STATUS_NOTIFICATION";
NSString * USER_INFO_CHANGE_NOTIFICATION_KEY = @"USER_INFO_CHANGE_NOTIFICATION";

#define keyForAESUser @"x7xYg5s8xT0sW0Xa"


@implementation User

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"user_id" : @"id"};
}

//+ (NSDictionary *)modelContainerPropertyGenericClass {
//    return @{@"draw" : [Draw class],
//             @"country" : [Country class]};
//}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self yy_modelInitWithCoder:aDecoder];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [self yy_modelEncodeWithCoder:aCoder];
}

+ (NSURL*)userSaveURL
{
    return [SSFilePath sharedUserUrl];
}

+ (instancetype)initFromFile
{
    // 从本地文件获取用户信息
    NSURL * userInfoURL = [User userSaveURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:userInfoURL.path]) {
        NSData * archiverData = [[NSFileManager defaultManager] contentsAtPath:userInfoURL.path];
        NSString * jsonstring = [NSKeyedUnarchiver unarchiveObjectWithData:archiverData];
        NSData * data = [[NSData alloc] initWithBase64EncodedString:jsonstring options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSData * jsonData = [FBEncryptorAES decryptData:data key:[keyForAESUser dataUsingEncoding:NSUTF8StringEncoding]];
        User * uuu = [User yy_modelWithJSON:jsonData];
        return uuu;
    } else {
        return nil;
    }
}

- (void)saveAsDef
{
    NSURL * userInfoURL = [User userSaveURL];
    NSData * jsonData = [self yy_modelToJSONData];
    NSData * data = [FBEncryptorAES encryptData:jsonData key:[keyForAESUser dataUsingEncoding:NSUTF8StringEncoding]];
    NSString * jsonstring = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSData * keyArchiverData = [NSKeyedArchiver archivedDataWithRootObject:jsonstring];
    [[NSFileManager defaultManager] createFileAtPath:userInfoURL.path contents:keyArchiverData attributes:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_INFO_CHANGE_NOTIFICATION_KEY object:nil userInfo:nil];
}

+ (instancetype)userInfo
{
    return [User initFromFile];
}

+ (BOOL)isLogin
{
    NSURL * userInfoURL = [User userSaveURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:userInfoURL.path]) {
        return true;
    }
    return false;
}

+ (void)logout
{
    [[SSFilePath sharedUserDefaults] removeObjectForKey:@"receipt_user_id"];
    [[SSFilePath sharedUserDefaults] removeObjectForKey:@"receipt_str"];
    // 从本地文件删除用户信息
    NSURL * userInfoURL = [User userSaveURL];
    [[NSFileManager defaultManager] removeItemAtPath:userInfoURL.path error:nil];
    [SSProxy removeDefault];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_INFO_CHANGE_NOTIFICATION_KEY object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_LOGING_STATUS_NOTIFICATION_KEY object:nil];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@", [self yy_modelToJSONString]];
}


@end



