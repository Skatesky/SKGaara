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
#import "SKInvocationConstructor.h"

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
    [self context][@"runClassWithNoParamter"] = ^id(NSString *className, NSString *selectorName) {
        return [self runClassWithClassName:className selector:selectorName param1:nil param2:nil];
    };
    [self context][@"runClassWith1Paramter"] = ^id(NSString *className, NSString *selectorName, id param1) {
        return [self runClassWithClassName:className selector:selectorName param1:param1 param2:nil];
    };
    [self context][@"runClassWith2Paramters"] = ^id(NSString *className, NSString *selectorName, id param1, id param2) {
        return [self runClassWithClassName:className selector:selectorName param1:param1 param2:param2];
    };
    [self context][@"runVoidClassWithNoParamter"] = ^(NSString *className, NSString *selectorName) {
        [self runClassWithClassName:className selector:selectorName param1:nil param2:nil];
    };
    [self context][@"runVoidClassWith1Paramter"] = ^(NSString *className, NSString *selectorName, id param1) {
        [self runClassWithClassName:className selector:selectorName param1:param1 param2:nil];
    };
    [self context][@"runVoidClassWith2Paramters"] = ^(NSString *className, NSString *selectorName, id param1, id param2) {
        [self runClassWithClassName:className selector:selectorName param1:param1 param2:param2];
    };
    [self context][@"runInstanceWithNoParamter"] = ^id(id instance, NSString *selectorName) {
        return [self runInstanceWithInstance:instance selector:selectorName param1:nil param2:nil];
    };
    [self context][@"runInstanceWith1Paramter"] = ^id(id instance, NSString *selectorName, id param1) {
        return [self runInstanceWithInstance:instance selector:selectorName param1:param1 param2:nil];
    };
    [self context][@"runInstanceWith2Paramters"] = ^id(id instance, NSString *selectorName, id param1, id param2) {
        return [self runInstanceWithInstance:instance selector:selectorName param1:param1 param2:param2];
    };
    [self context][@"runVoidInstanceWithNoParamter"] = ^(id instance, NSString *selectorName) {
        [self runInstanceWithInstance:instance selector:selectorName param1:nil param2:nil];
    };
    [self context][@"runVoidInstanceWith1Paramter"] = ^(id instance, NSString *selectorName, id param1) {
        [self runInstanceWithInstance:instance selector:selectorName param1:param1 param2:nil];
    };
    [self context][@"runVoidInstanceWith2Paramters"] = ^(id instance, NSString *selectorName, id param1, id param2) {
        [self runInstanceWithInstance:instance selector:selectorName param1:param1 param2:param2];
    };
    [self context][@""] = ^id(id instance, NSString *selectorName, NSArray *arguments) {
        return [self runInstanceWithInstance:instance selector:selectorName arguments:arguments];
    };
    [self context][@"runInvocation"] = ^(NSInvocation *invocation) {
        [invocation invoke];
    };
    [self context][@"runClassMethod"] = ^id(NSString *className, NSString *selectorName, NSArray *arguments) {
        return [self runClassWithClassName:className selector:selectorName arguments:arguments];
    };
    [self context][@"runInstanceMethod"] = ^id(NSString * className, NSString *selectorName, NSArray *arguments) {
        return [self runInstanceWithInstance:className selector:selectorName arguments:arguments];
    };
    [[self context] evaluateScript:@"var console = {}"];
    [self context][@"console"][@"log"] = ^(id message) {
        NSLog(@"Javascript log: %@",message);
    };
}

+ (void)fix:(NSString *)jsString {
    [[self context] evaluateScript:jsString];
}

+ (void)fixWithJSFile:(NSString *)path {
    NSError *error = nil;
    NSString *fixPatch = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"analysis js file error :%@", error);
        return;
    }
//#ifdef DEBUG
//    [[self context] evaluateScript:fixPatch
//                     withSourceURL:[NSURL URLWithString:path]];
//#else
    [self fix:fixPatch];
//#endif
}

#pragma mark - core
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

// run native方法 - 实例方法
+ (id)runInstanceWithInstance:(id)instance selector:(NSString *)selector arguments:(NSArray *)arguments {
    SEL sel = NSSelectorFromString(selector);
    if (!sel) {
        return nil;
    }
    
    if (![instance respondsToSelector:sel]) {
        return nil;
    }
    return [self runSelector:sel target:instance arguments:arguments];
}

// run native方法 - 类方法
+ (id)runClassWithClassName:(NSString *)className selector:(NSString *)selector arguments:(NSArray *)arguments {
    Class aClass = NSClassFromString(className);
    if (!aClass) {
        return nil;
    }
    
    SEL sel = NSSelectorFromString(selector);
    if (!sel) {
        return nil;
    }
    
    if (![aClass respondsToSelector:sel]) {
        return nil;
    }
    return [self runSelector:sel target:aClass arguments:arguments];
}

// 调用某个方法的核心方法
+ (id)runSelector:(SEL)selector target:(id)target arguments:(NSArray *)arguments {
    // 调用某个对象的某个方法，有两种方式
    // 1 'performSelector: withObject: withObject:' 改方法具有局限性，参数数量限制，类型必须是id类型，返回值也有限制
//    return [self performSelector:selector forTarget:target withArguments:arguments];
    
    // 2 通过invocation，灵活易扩展，但也很难满足navtive的数据类型
    // (1) 获取方法签名
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    
    // (2) 根据方法签名，生成调用invocation
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    // (3) 设置invocation的selector 和target
    invocation.selector = selector;
    invocation.target = target;
    
    // (4) 设置invocation的参数，之后便可以执行调用
    if (![self setInvocation:invocation withSignature:signature arguments:arguments]) {
        // 设置失败，则不执行
        return nil;
    }
    
    // (5) 执行调用invocation
    [invocation invoke];
    
    // (6) 获取调用invocation的返回值
    return [self getReturnFromInvocation:invocation withSignature:signature];
}

/// 用给定的参数设置invocation的参数 invocation 的 'setArgument: atIndex:' 方法
+ (BOOL)setInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature arguments:(NSArray *)arguments {
    return [SKInvocationConstructor constructInvocation:invocation withSignature:signature arguments:arguments];
}

/// 从invocation获取返回, invocation 的 'getReturnValue:' 方法
+ (id)getReturnFromInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature {
    return [SKInvocationConstructor getReturnFromInvocation:invocation withSignature:signature];
}

+ (id)performSelector:(SEL)selector forTarget:(id)target withArguments:(NSArray *)arguments {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // warning!!! 如果方法的返回类型是void，则会奔溃
    if (!arguments || arguments.count < 1) {
        return [target performSelector:selector];
    } else if (arguments.count == 1) {
         return [target performSelector:selector withObject:arguments[0]];
    } else if (arguments.count == 2) {
        return [target performSelector:selector withObject:arguments[0] withObject:arguments[1]];
    } else {
        NSLog(@"参数类型超过2个，无法执行！");
        return nil;
    }
#pragma clang diagnostic pop
}

+ (id)runClassWithClassName:(NSString *)className selector:(NSString *)selectorName param1:(id)param1 param2:(id)param2 {
    NSMutableArray *arguments = [NSMutableArray array];
    if (param1) {
        [arguments addObject:param1];
    }
    if (param2) {
        [arguments addObject:param2];
    }
    return [self runClassWithClassName:className selector:selectorName arguments:arguments];
}

+ (id)runInstanceWithInstance:(id)instance selector:(NSString *)selectorName param1:(id)param1 param2:(id)param2 {
    NSMutableArray *arguments = [NSMutableArray array];
    if (param1) {
        [arguments addObject:param1];
    }
    if (param2) {
        [arguments addObject:param2];
    }
    return [self runInstanceWithInstance:instance selector:selectorName arguments:arguments];
}

@end
