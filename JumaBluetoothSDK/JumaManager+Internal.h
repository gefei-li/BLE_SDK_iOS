//
//  JumaManager+Internal.h
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 15/7/17.
//  Copyright (c) 2015年 JUMA. All rights reserved.
//

#import "JumaManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CBUUID;

@interface JumaManager (Internal)

+ (NSDictionary *)validInitOptionsFromDict:(nullable NSDictionary *)dict;
+ (NSDictionary *)validScanOptionsFromDict:(nullable NSDictionary *)dict;

+ (BOOL)isValidUUIDArray:(NSArray *)UUIDs;

+ (BOOL)setUUIDString:(NSString *)UUID forKey:(NSString *)key;
+ (BOOL)setNSUUID:(NSUUID *)UUID forKey:(NSString *)key;
+ (BOOL)setCBUUID:(CBUUID *)UUID forKey:(NSString *)key;

+ (NSString *)UUIDStringForKey:(NSString *)key;
+ (NSUUID *)NSUUIDForKey:(NSString *)key;
+ (CBUUID *)CBUUIDForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
