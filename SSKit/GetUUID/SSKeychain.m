//
//  SSKeychain.m
//  SSKeychain
//
//  Created by Sam Soffes on 5/19/10.
//  Copyright (c) 2010-2014 Sam Soffes. All rights reserved.
//

#import "SSKeychain.h"

NSString *const _kSSKeychainErrorDomain = @"com.samsoffes.sskeychain";
NSString *const _kSSKeychainAccountKey = @"acct";
NSString *const _kSSKeychainCreatedAtKey = @"cdat";
NSString *const _kSSKeychainClassKey = @"labl";
NSString *const _kSSKeychainDescriptionKey = @"desc";
NSString *const _kSSKeychainLabelKey = @"labl";
NSString *const _kSSKeychainLastModifiedKey = @"mdat";
NSString *const _kSSKeychainWhereKey = @"svce";

#if __IPHONE_4_0 && TARGET_OS_IPHONE
	static CFTypeRef SSKeychainAccessibilityType = NULL;
#endif

@implementation SSKeychain

+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account {
	return [self passwordForService:serviceName account:account error:nil];
}


+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	[query fetch:error];
	return query.password;
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account {
	return [self deletePasswordForService:serviceName account:account error:nil];
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	return [query deleteItem:error];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account {
	return [self setPassword:password forService:serviceName account:account error:nil];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
	SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
	query.service = serviceName;
	query.account = account;
	query.password = password;
	return [query save:error];
}


+ (NSArray *)allAccounts {
	return [self accountsForService:nil];
}


+ (NSArray *)accountsForService:(NSString *)serviceName {
	SSKeychainQuery *query = [[SSKeychainQuery alloc] init];
	query.service = serviceName;
	return [query fetchAll:nil];
}


#if __IPHONE_4_0 && TARGET_OS_IPHONE
+ (CFTypeRef)accessibilityType {
	return SSKeychainAccessibilityType;
}


+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
	CFRetain(accessibilityType);
	if (SSKeychainAccessibilityType) {
		CFRelease(SSKeychainAccessibilityType);
	}
	SSKeychainAccessibilityType = accessibilityType;
}
#endif

@end
