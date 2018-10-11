//
//  SKInvocationConstructor.h
//  SKGaara
//
//  Created by zhanghuabing on 2018/10/11.
//

#import <Foundation/Foundation.h>

@interface SKInvocationConstructor : NSObject

/**
 根据给定参数，构造一个invocation

 @param invocation 原始的invocation
 @param signature 方法签名
 @param arguments 参数
 @return 是否成功
 */
+ (BOOL)constructInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature arguments:(NSArray *)arguments;

/**
 获取invocation的返回

 @param invocation 被执行的invocation
 @param signature 方法签名
 @return 返回
 */
+ (id)getReturnFromInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature;

@end
