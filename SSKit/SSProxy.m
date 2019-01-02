//
//  SSProxy.m
//  PandaVPN
//
//  Created by Shoplex on 2016/11/10.
//  Copyright © 2016年 shoplex. All rights reserved.
//

#import "SSProxy.h"
#import "SSFilePath.h"
#import "FBEncryptorAES.h"
#import <YYModel/YYModel.h>

#define keyForAESApp @"x7x5fYR9TWW0Xadw"


@implementation SSProxy
- (NSString *)description {
    return [self yy_modelToJSONString];
}

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"confid" : @"id"};
}

- (void)saveAsDefault
{
    if (self.tag.length <= 0) {
        self.tag = [SSProxy defaultProxy].tag;
    }
    NSURL * userInfoURL = [SSFilePath sharedProxyConfUrl];
    NSData * jsonData = [self yy_modelToJSONData];
    NSData * data = [FBEncryptorAES encryptData:jsonData key:[keyForAESApp dataUsingEncoding:NSUTF8StringEncoding]];
    NSString * jsonstring = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSData * keyArchiverData = [NSKeyedArchiver archivedDataWithRootObject:jsonstring];
    [[NSFileManager defaultManager] createFileAtPath:userInfoURL.path contents:keyArchiverData attributes:nil];
}

+ (instancetype)defaultProxy
{
    NSURL * proxyInfo = [SSFilePath sharedProxyConfUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:proxyInfo.path]) {
        NSData * archiverData = [[NSFileManager defaultManager] contentsAtPath:proxyInfo.path];
        if (archiverData) {
            NSString * jsonstring = [NSKeyedUnarchiver unarchiveObjectWithData:archiverData];
            if (jsonstring) {
                NSData * data = [[NSData alloc] initWithBase64EncodedString:jsonstring options:NSDataBase64DecodingIgnoreUnknownCharacters];
                if (data) {
                    NSData * jsonData = [FBEncryptorAES decryptData:data key:[keyForAESApp dataUsingEncoding:NSUTF8StringEncoding]];
                    if (jsonData) {
                        SSProxy * ppp = [SSProxy yy_modelWithJSON:jsonData];
                        return ppp;
                    }
                }
            }
        }
    }
    
    return [[SSProxy alloc] init];
}

+ (void)removeDefault
{
    NSURL * proxyInfo = [SSFilePath sharedProxyConfUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:proxyInfo.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:proxyInfo.path error:nil];
        if ([[NSFileManager defaultManager] fileExistsAtPath:proxyInfo.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:proxyInfo.path error:nil];
        }
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder { return [super yy_modelInitWithCoder:aDecoder]; }
- (void)encodeWithCoder:(NSCoder *)aCoder { [super yy_modelEncodeWithCoder:aCoder]; }

- (NSDictionary *)jsonFromProxy
{
    return [self yy_modelToJSONObject];
}

@end
