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

- (void)notifyDelegateWithDeviceID:(NSData *)deviceID {
    
    if (![self.delegate respondsToSelector:@selector(device:didReadDeviceID:parseDataError:)]) { return; }
    
    deviceID = [deviceID copy];
    NSError *error = nil;
    
    // validation
    if (deviceID.length != 16) {
        deviceID = nil;
        
        NSString *msg = [NSString stringWithFormat:@"the received data %@ is not valid Device_ID", deviceID];
        error = [NSError juma_errorWithDescription:msg];
    }
    
    [self.delegate device:self didReadDeviceID:deviceID parseDataError:error];
}

- (void)notifyDelegateWithVendorIdAndProductIdData:(NSData *)data {
    
    if (![self.delegate respondsToSelector:@selector(device:didReadVendorID:productID:parseDataError:)]) { return; }
    
    data = [data copy];
    NSString *vendorID = nil;
    NSString *productID = nil;
    NSError *error = nil;
    
    // data validation
    const NSUInteger expectedLength = 8;
    
    if (data.length != expectedLength) {
        NSString *msg = [NSString stringWithFormat:@"the received data %@ is not valid to parse out Vendor_ID and Product_ID", data];
        error = [NSError juma_errorWithDescription:msg];
    }
    
    // convert data to Vendor_ID and Product_ID
    if (!error) {
        const NSUInteger componetLenght = expectedLength / 2;
        
        NSData *vendorIdData = [data juma_subdataToIndex:componetLenght];
        char vendorIdBytes[componetLenght + 1] = {0};
        memcpy(vendorIdBytes, vendorIdData.bytes, vendorIdData.length);
        vendorID = [NSString stringWithCString:vendorIdBytes encoding:NSUTF8StringEncoding];
        
        NSData *productData = [data juma_subdataFromIndex:componetLenght];
        char productIdBytes[componetLenght + 1] = {0};
        memcpy(productIdBytes, productData.bytes, productData.length);
        productID = [NSString stringWithCString:productIdBytes encoding:NSUTF8StringEncoding];
        
        // check Vendor_ID and Product_ID
        if (!vendorID && !productID) {
            NSString *msg = [NSString stringWithFormat:@"failed to convert data %@ to Vendor_ID string and Product_ID string", data];
            error = [NSError juma_errorWithDescription:msg];
        } else if (!vendorID && productID) {
            NSString *msg = [NSString stringWithFormat:@"failed to convert data %@ to Vendor_ID string", vendorIdData];
            error = [NSError juma_errorWithDescription:msg];
        } else if (vendorID && !productID) {
            NSString *msg = [NSString stringWithFormat:@"failed to convert data %@ to Product_ID string", productData];
            error = [NSError juma_errorWithDescription:msg];
        }
    }
    
    [self.delegate device:self didReadVendorID:vendorID productID:productID parseDataError:error];
}

- (void)notifyDelegateWithFirmwareVersion:(NSData *)data {
    
    if (![self.delegate respondsToSelector:@selector(device:didReadFirmwareVersion:parseDataError:)]) { return; }
    
    data = [data copy];
    NSString *firmwareVersion = nil;
    NSError *error = nil;
    
    // data validation
    const NSUInteger expectedMaxLength = 8;
    
    if (data.length == 0 || data.length > expectedMaxLength) {
        NSString *msg = [NSString stringWithFormat:@"the received data %@ is not valid to parse out Firmware_Version", data];
        error = [NSError juma_errorWithDescription:msg];
    }
    
    // convert data to Firmware_Version
    if (!error) {
        char firmwareVersionBytes[expectedMaxLength + 1] = {0};
        memcpy(firmwareVersionBytes, data.bytes, data.length);
        firmwareVersion = [NSString stringWithCString:firmwareVersionBytes encoding:NSUTF8StringEncoding];
        
        // check Firmware_Version
        if (!firmwareVersion) {
            NSString *msg = [NSString stringWithFormat:@"failed to convert data %@ to Firmware_Version string", data];
            error = [NSError juma_errorWithDescription:msg];
        }
    }
    
    [self.delegate device:self didReadFirmwareVersion:firmwareVersion parseDataError:error];
}

- (void)notifyDelegateVerdorIdAndProductIdModified:(NSData *)data {
    
    if (![self.delegate respondsToSelector:@selector(deviceDidModifyVendorIDAndProductID:)]) { return; }
    
//    NSError *error = nil;
//    
//    // data validation
//    const UInt8 *bytes = data.bytes;
//    
//    if (!(data.length == 1 && bytes[0] == 0)) {
//        NSString *msg = [NSString stringWithFormat:@"Unable to determine whether the write success by detecting received %@", data];
//        error = [NSError juma_errorWithDescription:msg];
//    }
    
    [self.delegate deviceDidModifyVendorIDAndProductID:self];
}

@end
