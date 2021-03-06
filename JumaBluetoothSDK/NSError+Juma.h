//
//  NSError+Juma.h
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 15/8/13.
//  Copyright (c) 2015年 JUMA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Juma)

+ (NSError *)juma_errorWithDescription:(NSString *)desc;
+ (NSError *)juma_errorWithCode:(NSInteger)code description:(NSString *)desc;

@end
