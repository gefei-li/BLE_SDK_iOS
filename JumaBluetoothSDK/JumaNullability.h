//
//  JumaNullability.h
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 16/5/16.
//  Copyright © 2016年 JUMA. All rights reserved.
//

#ifndef JumaNullability_h
#define JumaNullability_h

#ifdef __OBJC__

#import <Foundation/Foundation.h>

#ifndef NS_ASSUME_NONNULL_BEGIN
# if __has_feature(assume_nonnull)
#  define NS_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
# else
#  define NS_ASSUME_NONNULL_BEGIN
# endif
#endif

#ifndef NS_ASSUME_NONNULL_END
# if __has_feature(assume_nonnull)
#  define NS_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
# else
#  define NS_ASSUME_NONNULL_END
# endif
#endif


#if !__has_feature(nullability)
# define nullable
# define null_unspecified
# define _Nullable
# define _Null_unspecified
# define __nullable
# define __null_unspecified
#endif

#endif /* __OBJC__ */



#endif /* JumaNullability_h */
