//
//  GetUUID.h
//  Shoplex
//
//  Created by shangjin on 15/3/11.
//  Copyright (c) 2015年 shangjin. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @brief GetUUID 类 
    这个类用于获取UUID,并储存在钥匙链中
 */
@interface GetUUID : NSObject

//获取唯一的uuid
+ (NSString *)getUUID;
+ (BOOL)isFirstInstall;

@end
