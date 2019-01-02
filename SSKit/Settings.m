//
//  Settings.m
//  Potatso
//
//  Created by LEI on 7/13/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import "Settings.h"
#import "SSFilePath.h"

#define kSettingsKeyStartTime @"pandavpnStartTime"
#define kSettingsKeyIsLinked @"pandavpnLinked"

@interface Settings ()
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@end

@implementation Settings

+ (Settings *)shared {
    static Settings *settings;
    static dispatch_once_t onceSettingToken;
    dispatch_once(&onceSettingToken, ^{
        settings = [[Settings alloc] init];
    });
    return settings;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userDefaults = [SSFilePath sharedUserDefaults];
    }
    return self;
}

- (void)setStartTime:(NSDate *)startTime {
    [self.userDefaults setObject:startTime forKey:kSettingsKeyStartTime];
    [self.userDefaults synchronize];
}

- (NSDate *)startTime {
    return [self.userDefaults objectForKey:kSettingsKeyStartTime];
}

- (void)setIsLinked:(BOOL)isLinked
{
    [self.userDefaults setBool:isLinked forKey:kSettingsKeyIsLinked];
    [self.userDefaults synchronize];
}

- (BOOL)isLinked
{
    return [self.userDefaults boolForKey:kSettingsKeyIsLinked];
}

@end
