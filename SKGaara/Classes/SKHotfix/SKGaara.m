//
//  SKGaara.m
//  SKGaara
//
//  Created by zhanghuabing on 2018/10/8.
//

#import "SKGaara.h"
#import <objc/runtime.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <Aspects/Aspects.h>

@implementation SKGaara

#pragma mark - Public
+ (void)setupContext {
    [self context][@"fixInstanceMethodBefore"] = ^(NSString *instanceName, NSString *selectorName, JSValue *fixImpl) {
        [self fixClassMethod:NO
            aspectionOptions:AspectPositionBefore
                instanceName:instanceName
                selectorName:selectorName
                     fixImpl:fixImpl
         ];
    };
    [self context][@"fixInstanceMethodReplace"] = ^(NSString *instanceName, NSString *selectorName, JSValue *fixImpl) {
        [self fixClassMethod:NO
            aspectionOptions:AspectPositionInstead
                instanceName:instanceName
                selectorName:selectorName
                     fixImpl:fixImpl
         ];
    };
    [self context][@"fixInstanceMethodAfter"] = ^(NSString *instanceName, NSString *selectorName, JSValue *fixImpl) {
        [self fixClassMethod:NO
            aspectionOptions:AspectPositionAfter
                instanceName:instanceName
                selectorName:selectorName
                     fixImpl:fixImpl
         ];
    };
    [self context][@"fixClassMethodBefore"] = ^(NSString *instanceName, NSString *selectorName, JSValue *fixImpl) {
        [self fixClassMethod:YES
                    aspectionOptions:AspectPositionBefore
                        instanceName:instanceName
                        selectorName:selectorName
                             fixImpl:fixImpl
         ];
    };
    [self context][@"fixClassMethodReplace"] = ^(NSString *instanceName, NSString *selectorName, JSValue *fixImpl) {
        [self fixClassMethod:YES
            aspectionOptions:AspectPositionInstead
                instanceName:instanceName
                selectorName:selectorName
                     fixImpl:fixImpl
         ];
    };
    [self context][@"fixClassMethodAfter"] = ^(NSString *instanceName, NSString *selectorName, JSValue *fixImpl) {
        [self fixClassMethod:YES
            aspectionOptions:AspectPositionAfter
                instanceName:instanceName
                selectorName:selectorName
                     fixImpl:fixImpl
         ];
    };
}

+ (void)fix:(NSString *)jsString {
    [[self context] evaluateScript:jsString];
}

#pragma mark - private
// JSCore实现
+ (JSContext *)context {
    static JSContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[JSContext alloc] init];
        context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
            NSLog(@"Ohooo: %@",exception);
        };
    });
    return context;
}

// hook 方法
+ (void)fixClassMethod:(BOOL)isClassMethod aspectionOptions:(AspectOptions)aspectionOptions instanceName:(NSString *)instanceName selectorName:(NSString *)selectorName fixImpl:(JSValue *)fixImpl {
    Class aClass = NSClassFromString(instanceName);
    if (isClassMethod) {
        aClass = object_getClass(aClass);
    }
    SEL selector = NSSelectorFromString(selectorName);
    [aClass aspect_hookSelector:selector
                    withOptions:aspectionOptions
                     usingBlock:^(id<AspectInfo> aspectInfo) {
                         [fixImpl callWithArguments:@[aspectInfo.instance, aspectInfo.originalInvocation, aspectInfo.arguments]];
                     }
                          error:nil];
}

@end
