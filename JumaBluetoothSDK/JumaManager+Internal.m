//
//  JumaManager+Internal.m
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 15/7/17.
//  Copyright (c) 2015年 JUMA. All rights reserved.
//

#import "JumaManager+Internal.h"
#import "JumaManagerConstant.h"
#import <CoreBluetooth/CoreBluetooth.h>

@implementation JumaManager (Internal)

+ (NSDictionary *)validInitOptionsFromDict:(NSDictionary *)dict {
    
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    
    id value = dict[JumaManagerOptionShowPowerAlertKey];
    
    if (value) {
        NSAssert([value isKindOfClass:[NSNumber class]], @"the value for key 'JumaManagerOptionShowPowerAlertKey' must be a number");
        options[CBCentralManagerOptionShowPowerAlertKey] = value;
    }
    
    
    value = dict[JumaManagerOptionRestoreIdentifierKey];
    
    if (value) {
        NSAssert([value isKindOfClass:[NSString class]], @"the value for key 'JumaManagerOptionRestoreIdentifierKey' must be a string");
        options[CBCentralManagerOptionRestoreIdentifierKey] = value;
    }
    
    return options.copy;
}

+ (NSDictionary *)validScanOptionsFromDict:(NSDictionary *)dict {
    
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    
    id value = dict[JumaManagerScanOptionAllowDuplicatesKey];
    
    if (value) {
        NSAssert([value isKindOfClass:[NSNumber class]], @"the value for key 'JumaManagerScanOptionAllowDuplicatesKey' must be a number");
        options[CBCentralManagerScanOptionAllowDuplicatesKey] = value;
    }
    
    return options.copy;
}

@end

@implementation JumaManager (ScannedAdvertisingServices)

+ (NSArray *)scannedAdvertisingServices {
    static NSArray *services = nil;
    
    if (!services) {
        services = @[ [CBUUID UUIDWithString:@"FE90"] ];
    }
    
    return services;
}

@end
