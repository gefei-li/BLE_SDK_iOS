//
//  JumaDevice+DelegateEventNotifying.m
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 16/5/18.
//  Copyright © 2016年 JUMA. All rights reserved.
//

#import "JumaDevice+DelegateEventNotifying.h"
#import "NSData+Category.h"
#import "NSError+Juma.h"

@implementation JumaDevice (DelegateEventNotifying)

- (void)notifyDelegateWithRSSI:(NSNumber *)RSSI error:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(device:didReadRSSI:error:)]) {
        [self.delegate device:self didReadRSSI:RSSI error:error];
    }
}

- (void)notifyDelegateWithWritingError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(device:didWriteData:)]) {
        [self.delegate device:self didWriteData:error];
    }
}

- (void)notifyDelegateWithUpdatedData:(NSData *)data type:(char)typeCode error:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(device:didUpdateData:type:error:)]) {
        [self.delegate device:self didUpdateData:data type:typeCode error:error];
    }
}

- (void)notifyDelegateWithUpdatingFirmwareError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(device:didUpdateFirmware:)]) {
        [self.delegate device:self didUpdateFirmware:error];
    }
}

- (void)notifyDelegateWithDeviceID:(NSData *)deviceID error:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(device:didReadDeviceID:error:)]) {
        [self.delegate device:self didReadDeviceID:deviceID error:error];
    }
}

- (void)notifyDelegateWithVendorIdAndProductIdData:(NSData *)data error:(NSError *)error {
    
    if (![self.delegate respondsToSelector:@selector(device:didReadVendorID:productID:error:)]) { return; }
    
    NSString *vendorID = nil;
    NSString *productID = nil;
    
    if (!error) {
        static const NSUInteger len = 8;
        
        if (data.length == len) {
            NSData *vendorData = [data juma_subdataToIndex:len / 2];
            NSData *productData = [data juma_subdataFromIndex:len / 2];
            
            vendorID  = [[NSString alloc] initWithData:vendorData  encoding:NSUTF8StringEncoding];
            productID = [[NSString alloc] initWithData:productData encoding:NSUTF8StringEncoding];
        }
        
        if (!vendorID || !productID) {
            NSString *msg = [NSString stringWithFormat:@"can not convert data %@ to Vendor_ID string and Product_ID string", data];
            error = [NSError juma_errorWithDescription:msg];
        }
    }
    
    [self.delegate device:self didReadVendorID:vendorID productID:productID error:error];
}

- (void)notifyDelegateWithFirmwareVersion:(NSData *)data error:(NSError *)error {
    
    if (![self.delegate respondsToSelector:@selector(device:didReadFirmwareVersion:error:)]) { return; }
    
    NSString *firmwareVersion = nil;
    
    if (!error) {
        
        if (data.length <= 8) {
            firmwareVersion = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        if (!firmwareVersion) {
            NSString *msg = [NSString stringWithFormat:@"can not convert data %@ to Firmware_Ver string", data];
            error = [NSError juma_errorWithDescription:msg];
        }
    }
    
    [self.delegate device:self didReadFirmwareVersion:firmwareVersion error:error];
}

- (void)notifyDelegateVerdorIdAndProductIdModified:(NSData *)data error:(NSError *)error {
    
    if (![self.delegate respondsToSelector:@selector(device:didModifyVendorIDAndProductID:)]) { return; }
    
    if (!error) {
        const UInt8 *bytes = data.bytes;
        
        if (data.length == 1 && bytes[0] != 0) {
            NSString *msg = [NSString stringWithFormat:@"Unable to determine whether the write success by detecting received %@", data];
            error = [NSError juma_errorWithDescription:msg];
        }
    }
    
    [self.delegate device:self didModifyVendorIDAndProductID:error];
}

@end
