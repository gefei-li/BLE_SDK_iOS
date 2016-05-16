//
//  JumaManager+Internal.h
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 15/7/17.
//  Copyright (c) 2015年 JUMA. All rights reserved.
//

#import "JumaManager.h"
#import <JumaBluetoothSDK/JumaNullability.h>

NS_ASSUME_NONNULL_BEGIN

@class CBUUID;

@interface JumaManager (Internal)

+ (NSDictionary *)validInitOptionsFromDict:(nullable NSDictionary *)dict;
+ (NSDictionary *)validScanOptionsFromDict:(nullable NSDictionary *)dict;

@end

@interface JumaManager (ScannedAdvertisingServices)

+ (NSArray *)scannedAdvertisingServices;

@end

NS_ASSUME_NONNULL_END
