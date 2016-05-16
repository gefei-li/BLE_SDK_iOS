//
//  NSError+Juma.m
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 15/8/13.
//  Copyright (c) 2015年 JUMA. All rights reserved.
//

#import "NSError+Juma.h"

@implementation NSError (Juma)

+ (NSError *)juma_errorWithDescription:(NSString *)desc {
    return [self juma_errorWithCode:0 description:desc];
}

+ (NSError *)juma_errorWithCode:(NSInteger)code description:(NSString *)desc {
    NSDictionary *info = @{ NSLocalizedDescriptionKey : desc };
    NSError *error = [NSError errorWithDomain:@"io.juma.www" code:code userInfo:info];
    return error;
}

@end
