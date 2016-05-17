//
//  JumaDevice+UUIDConstants.h
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 16/5/17.
//  Copyright © 2016年 JUMA. All rights reserved.
//

#import <JumaBluetoothSDK/JumaBluetoothSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class CBUUID;

@interface JumaDevice (UUIDConstants)

+ (CBUUID *)serviceUUID;
+ (NSArray *)services;

+ (CBUUID *)commandCharacteristicUUID;
+ (CBUUID *)notifyCharacteristicUUID;
+ (CBUUID *)bulkOutCharacteristicUUID;
+ (NSArray *)characteristics;

@end

NS_ASSUME_NONNULL_END
