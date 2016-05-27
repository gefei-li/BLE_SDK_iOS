//
//  JumaDevice+DelegateEventNotifying.h
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 16/5/18.
//  Copyright © 2016年 JUMA. All rights reserved.
//

#import <JumaBluetoothSDK/JumaBluetoothSDK.h>

@interface JumaDevice (DelegateEventNotifying)

- (void)notifyDelegateWithRSSI:(NSNumber *)RSSI error:(NSError *)error;

- (void)notifyDelegateWithWritingError:(NSError *)error;

- (void)notifyDelegateWithUpdatedData:(NSData *)data type:(char)typeCode error:(NSError *)error;

- (void)notifyDelegateWithUpdatingFirmwareError:(NSError *)error;

- (void)notifyDelegateWithDeviceID:(NSData *)deviceID;

- (void)notifyDelegateWithVendorIdAndProductIdData:(NSData *)data;

- (void)notifyDelegateWithFirmwareVersion:(NSData *)data;

- (void)notifyDelegateVerdorIdAndProductIdModified:(NSData *)data;

@end
