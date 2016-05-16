//
//  NSArray+Block.m
//  iOS-Categories (https://github.com/shaojiankui/iOS-Categories)
//
//  Created by Jakey on 14/12/15.
//  Copyright (c) 2014年 www.skyfox.org. All rights reserved.
//

#import "NSArray+Block.h"

@implementation NSArray (Block)


- (NSArray *)juma_map:(id (^)(id object))block {
    NSMutableArray *array = [NSMutableArray array];
    
    for (id object in self) {
        [array addObject:block(object)];
    }
    
    return array.copy;
}

- (NSArray *)juma_filter:(BOOL (^)(id object))block {
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return block(evaluatedObject);
    }]];
}

//- (NSArray *)juma_reject:(BOOL (^)(id object))block {
//    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
//        return !block(evaluatedObject);
//    }]];
//}

- (id)juma_detect:(BOOL (^)(id object))block {
    for (id object in self) {
        if (block(object))
            return object;
    }
    return nil;
}

//- (id)juma_reduce:(id (^)(id accumulator, id object))block {
//    return [self juma_reduce:nil withBlock:block];
//}
//
//- (id)juma_reduce:(id)initial withBlock:(id (^)(id accumulator, id object))block {
//    id accumulator = initial;
//    
//    for(id object in self)
//        accumulator = accumulator ? block(accumulator, object) : object;
//    
//    return accumulator;
//}

@end
