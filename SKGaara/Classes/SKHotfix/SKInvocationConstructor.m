//
//  SKInvocationConstructor.m
//  SKGaara
//
//  Created by skate on 2018/10/11.
//

#import "SKInvocationConstructor.h"

static NSString * const kObjectTypeKey = @"object";
static NSString * const kStructTypeKey = @"struct";

@implementation SKInvocationConstructor

static NSString *extractStructName(NSString *typeEncodeString)
{
    NSArray *array = [typeEncodeString componentsSeparatedByString:@"="];
    NSString *typeString = array[0];
    int firstValidIndex = 0;
    for (int i = 0; i < typeString.length; i++) {
        char c = [typeString characterAtIndex:i];
        if (c == '{' || c == '_') {
            firstValidIndex++;
        }
        else {
            break;
        }
    }
    return [typeString substringFromIndex:firstValidIndex];
}

+ (BOOL)constructInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature arguments:(NSArray *)arguments {
//    [self batmanSetInvocation:invocation withSignature:signature arguments:arguments];
    [self lbySetInv:invocation withSig:signature andArgs:arguments];
    return YES;
}

+ (id)getReturnFromInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature {
//    return [self batmanGetReturnFromInvocation:invocation withSignature:signature];
    return [self lbyGetReturnFromInv:invocation withSig:signature];
}

#pragma mark - LBYFix
+ (void)lbySetInv:(NSInvocation *)inv withSig:(NSMethodSignature *)sig andArgs:(NSArray *)args {
    
#define args_length_judgments(_index_) \
[self argsLengthJudgment:args index:_index_] \

#define set_with_args(_index_, _type_, _sel_) \
do { \
_type_ arg; \
if (args_length_judgments(_index_-2)) { \
arg = [args[_index_-2] _sel_]; \
} \
[inv setArgument:&arg atIndex:_index_]; \
} while(0)
    
#define set_with_args_struct(_dic_, _struct_, _param_, _key_, _sel_) \
do { \
if (_dic_ && [_dic_ isKindOfClass:[NSDictionary class]]) { \
if ([_dic_.allKeys containsObject:_key_]) { \
_struct_._param_ = [_dic_[_key_] _sel_]; \
} \
} \
} while(0)
    
    NSUInteger count = [sig numberOfArguments];
    for (int index = 2; index < count; index++) {
        // 从方法签名中解析出每个参数的类型，进而根据js传递过来的参数来设置其具体值
        char *type = (char *)[sig getArgumentTypeAtIndex:index];
        while (*type == 'r' ||  // const
               *type == 'n' ||  // in
               *type == 'N' ||  // inout
               *type == 'o' ||  // out
               *type == 'O' ||  // bycopy
               *type == 'R' ||  // byref
               *type == 'V') {  // oneway
            type++;             // cutoff useless prefix
        }
        
        BOOL unsupportedType = NO;
        switch (*type) {
            case 'v':   // 1:void
            case 'B':   // 1:bool
            case 'c':   // 1: char / BOOL
            case 'C':   // 1: unsigned char
            case 's':   // 2: short
            case 'S':   // 2: unsigned short
            case 'i':   // 4: int / NSInteger(32bit)
            case 'I':   // 4: unsigned int / NSUInteger(32bit)
            case 'l':   // 4: long(32bit)
            case 'L':   // 4: unsigned long(32bit)
            { // 'char' and 'short' will be promoted to 'int'
                set_with_args(index, int, intValue);
            } break;
                
            case 'q':   // 8: long long / long(64bit) / NSInteger(64bit)
            case 'Q':   // 8: unsigned long long / unsigned long(64bit) / NSUInteger(64bit)
            {
                set_with_args(index, long long, longLongValue);
            } break;
                
            case 'f': // 4: float / CGFloat(32bit)
            {
                set_with_args(index, float, floatValue);
            } break;
                
            case 'd': // 8: double / CGFloat(64bit)
            case 'D': // 16: long double
            {
                set_with_args(index, double, doubleValue);
            } break;
                
            case '*': // char *
            {
                if (args_length_judgments(index-2)) {
                    NSString *arg = args[index-2];
                    if ([arg isKindOfClass:[NSString class]]) {
                        const void *c = [arg UTF8String];
                        [inv setArgument:&c atIndex:index];
                    }
                }
            } break;
                
            case '#': // Class
            {
                if (args_length_judgments(index-2)) {
                    NSString *arg = args[index-2];
                    if ([arg isKindOfClass:[NSString class]]) {
                        Class klass = NSClassFromString(arg);
                        if (klass) {
                            [inv setArgument:&klass atIndex:index];
                        }
                    }
                }
            } break;
                
            case '@': // id
            {
                // 要对NSNull类型过滤
                if (args_length_judgments(index-2)) {
                    id arg = args[index-2];
                    if ([arg isEqual:[NSNull null]]) {
                        arg = nil;
                    }
                    [inv setArgument:&arg atIndex:index];
                }
            } break;
                
            case '{': // struct
            {
                if (strcmp(type, @encode(CGPoint)) == 0) {
                    CGPoint point = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, point, x, @"x", doubleValue);
                        set_with_args_struct(dict, point, y, @"y", doubleValue);
                    }
                    [inv setArgument:&point atIndex:index];
                } else if (strcmp(type, @encode(CGSize)) == 0) {
                    CGSize size = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, size, width, @"width", doubleValue);
                        set_with_args_struct(dict, size, height, @"height", doubleValue);
                    }
                    [inv setArgument:&size atIndex:index];
                } else if (strcmp(type, @encode(CGRect)) == 0) {
                    CGRect rect;
                    CGPoint origin = {0};
                    CGSize size = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        NSDictionary *pDict = dict[@"origin"];
                        set_with_args_struct(pDict, origin, x, @"x", doubleValue);
                        set_with_args_struct(pDict, origin, y, @"y", doubleValue);
                        
                        NSDictionary *sDict = dict[@"size"];
                        set_with_args_struct(sDict, size, width, @"width", doubleValue);
                        set_with_args_struct(sDict, size, height, @"height", doubleValue);
                    }
                    rect.origin = origin;
                    rect.size = size;
                    [inv setArgument:&rect atIndex:index];
                } else if (strcmp(type, @encode(CGVector)) == 0) {
                    CGVector vector = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, vector, dx, @"dx", doubleValue);
                        set_with_args_struct(dict, vector, dy, @"dy", doubleValue);
                    }
                    [inv setArgument:&vector atIndex:index];
                } else if (strcmp(type, @encode(CGAffineTransform)) == 0) {
                    CGAffineTransform form = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, form, a, @"a", doubleValue);
                        set_with_args_struct(dict, form, b, @"b", doubleValue);
                        set_with_args_struct(dict, form, c, @"c", doubleValue);
                        set_with_args_struct(dict, form, d, @"d", doubleValue);
                        set_with_args_struct(dict, form, tx, @"tx", doubleValue);
                        set_with_args_struct(dict, form, ty, @"ty", doubleValue);
                    }
                    [inv setArgument:&form atIndex:index];
                } else if (strcmp(type, @encode(CATransform3D)) == 0) {
                    CATransform3D form3D = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, form3D, m11, @"m11", doubleValue);
                        set_with_args_struct(dict, form3D, m12, @"m12", doubleValue);
                        set_with_args_struct(dict, form3D, m13, @"m13", doubleValue);
                        set_with_args_struct(dict, form3D, m14, @"m14", doubleValue);
                        set_with_args_struct(dict, form3D, m21, @"m21", doubleValue);
                        set_with_args_struct(dict, form3D, m22, @"m22", doubleValue);
                        set_with_args_struct(dict, form3D, m23, @"m23", doubleValue);
                        set_with_args_struct(dict, form3D, m24, @"m24", doubleValue);
                        set_with_args_struct(dict, form3D, m31, @"m31", doubleValue);
                        set_with_args_struct(dict, form3D, m32, @"m32", doubleValue);
                        set_with_args_struct(dict, form3D, m33, @"m33", doubleValue);
                        set_with_args_struct(dict, form3D, m34, @"m34", doubleValue);
                        set_with_args_struct(dict, form3D, m41, @"m41", doubleValue);
                        set_with_args_struct(dict, form3D, m42, @"m42", doubleValue);
                        set_with_args_struct(dict, form3D, m43, @"m43", doubleValue);
                        set_with_args_struct(dict, form3D, m44, @"m44", doubleValue);
                    }
                    [inv setArgument:&form3D atIndex:index];
                } else if (strcmp(type, @encode(NSRange)) == 0) {
                    NSRange range = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, range, location, @"location", unsignedIntegerValue);
                        set_with_args_struct(dict, range, length, @"length", unsignedIntegerValue);
                    }
                    [inv setArgument:&range atIndex:index];
                } else if (strcmp(type, @encode(UIOffset)) == 0) {
                    UIOffset offset = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, offset, horizontal, @"horizontal", doubleValue);
                        set_with_args_struct(dict, offset, vertical, @"vertical", doubleValue);
                    }
                    [inv setArgument:&offset atIndex:index];
                } else if (strcmp(type, @encode(UIEdgeInsets)) == 0) {
                    UIEdgeInsets insets = {0};
                    
                    if (args_length_judgments(index-2)) {
                        NSDictionary *dict = args[index-2];
                        set_with_args_struct(dict, insets, top, @"top", doubleValue);
                        set_with_args_struct(dict, insets, left, @"left", doubleValue);
                        set_with_args_struct(dict, insets, bottom, @"bottom", doubleValue);
                        set_with_args_struct(dict, insets, right, @"right", doubleValue);
                    }
                    [inv setArgument:&insets atIndex:index];
                } else {
                    unsupportedType = YES;
                }
            } break;
                
            case '^': // pointer
            {
                unsupportedType = YES;
            } break;
                
            case ':': // SEL
            {
                unsupportedType = YES;
            } break;
                
            case '(': // union
            {
                unsupportedType = YES;
            } break;
                
            case '[': // array
            {
                unsupportedType = YES;
            } break;
                
            default: // what?!
            {
                unsupportedType = YES;
            } break;
        }
        
        NSAssert(!unsupportedType, @"arg unsupportedType");
    }
}

+ (id)lbyGetReturnFromInv:(NSInvocation *)inv withSig:(NSMethodSignature *)sig {
    NSUInteger length = [sig methodReturnLength];
    if (length == 0) return nil;
    
    char *type = (char *)[sig methodReturnType];
    while (*type == 'r' ||  // const
           *type == 'n' ||  // in
           *type == 'N' ||  // inout
           *type == 'o' ||  // out
           *type == 'O' ||  // bycopy
           *type == 'R' ||  // byref
           *type == 'V') {  // oneway
        type++; // cutoff useless prefix
    }
    
#define return_with_number(_type_) \
do { \
_type_ ret; \
[inv getReturnValue:&ret]; \
return @(ret); \
} while(0)
    
    switch (*type) {
        case 'v': return nil; // void
        case 'B': return_with_number(bool);
        case 'c': return_with_number(char);
        case 'C': return_with_number(unsigned char);
        case 's': return_with_number(short);
        case 'S': return_with_number(unsigned short);
        case 'i': return_with_number(int);
        case 'I': return_with_number(unsigned int);
        case 'l': return_with_number(int);
        case 'L': return_with_number(unsigned int);
        case 'q': return_with_number(long long);
        case 'Q': return_with_number(unsigned long long);
        case 'f': return_with_number(float);
        case 'd': return_with_number(double);
        case 'D': { // long double
            long double ret;
            [inv getReturnValue:&ret];
            return [NSNumber numberWithDouble:ret];
        };
            
        case '@': { // id
            void *ret;
            [inv getReturnValue:&ret];
            return (__bridge id)(ret);
        };
            
        case '#' : { // Class
            Class ret = nil;
            [inv getReturnValue:&ret];
            return ret;
        };
            
        default: { // struct / union / SEL / void* / unknown
            const char *objCType = [sig methodReturnType];
            char *buf = calloc(1, length);
            if (!buf) return nil;
            [inv getReturnValue:buf];
            NSValue *value = [NSValue valueWithBytes:buf objCType:objCType];
            free(buf);
            return value;
        };
    }
#undef return_with_number
}

+ (BOOL)argsLengthJudgment:(NSArray *)args index:(NSInteger)index {
    return [args isKindOfClass:[NSArray class]] && index < args.count;
}

#pragma mark - Batman you know
+ (void)batmanSetInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature arguments:(NSArray *)arguments {
    // 对于诸如`CGRect CGPoint`等结构体，可以通过转换的方式，比如字典...
    // ...JS在字典中申明类型，指定结构体的每个成员的值.
    // 下面的方法不够严谨，不能对嵌套数据进行转换，正确的做法是对参数做递归转换后再'[invocation setArgument:&argValue atIndex:index]'
    NSUInteger numberOfArguments = signature.numberOfArguments;
    for (NSUInteger index = 2; index < numberOfArguments; index++) {
        // 参数个数比匹配？
        id argValue = arguments[index - 2]; // 可能越界！！！
        if ([argValue isKindOfClass:[NSDictionary class]]) {
            // 字典类型，存储了结构体的数据
            NSString *structTypeKey = [argValue objectForKey:kStructTypeKey];
            if (structTypeKey) {
                // 结构体类型，需要解析结构体数据
                if ([structTypeKey isEqualToString:@"CGRect"]) {
                    CGFloat x = [[argValue objectForKey:@"x"] floatValue];
                    CGFloat y = [[argValue objectForKey:@"y"] floatValue];
                    CGFloat width = [[argValue objectForKey:@"width"] floatValue];
                    CGFloat height = [[argValue objectForKey:@"height"] floatValue];
                    CGRect rect = CGRectMake(x, y, width, height);
                    
                    [invocation setArgument:&rect atIndex:index];
                } else if ([structTypeKey isEqualToString:@"CGPoint"]) {
                    CGFloat x = [[argValue objectForKey:@"x"] floatValue];
                    CGFloat y = [[argValue objectForKey:@"y"] floatValue];
                    CGPoint point = CGPointMake(x, y);
                    
                    [invocation setArgument:&point atIndex:index];
                } else if ([structTypeKey isEqualToString:@"CGSize"]) {
                    CGFloat width = [[argValue objectForKey:@"width"] floatValue];
                    CGFloat height = [[argValue objectForKey:@"height"] floatValue];
                    CGSize size = CGSizeMake(width, height);
                    
                    [invocation setArgument:&size atIndex:index];
                } else if ([structTypeKey isEqualToString:@"NSRange"]) {
                    NSUInteger loc =
                    [[argValue objectForKey:@"loc"] unsignedIntegerValue];
                    NSUInteger len =
                    [[argValue objectForKey:@"len"] unsignedIntegerValue];
                    NSRange range = NSMakeRange(loc, len);
                    
                    [invocation setArgument:&range atIndex:index];
                } else {
                    [invocation setArgument:&argValue atIndex:index];
                }
            } else {
                [invocation setArgument:&argValue atIndex:index];
            }
        } else if ([argValue isKindOfClass:[NSArray class]]) {
            // 数组类型，直接设置
            [invocation setArgument:&argValue atIndex:index];
        } else {
            // 普通类型
            // why?
            static NSObject *_nullObj = nil;
            static NSObject *_nilObj = nil;
            _nullObj = [[NSObject alloc] init];
            _nilObj = [[NSObject alloc] init];
            
            const char *argumentType = [signature getArgumentTypeAtIndex:index];
            switch (argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
                    
#define SET_INVOCATION_ARG_TYPE(_charType_, _type_, _sel_) \
case _charType_: {      \
_type_ value = [argValue _sel_]; \
[invocation setArgument:&value atIndex:index];                             \
break;                      \
}\

                    
                    SET_INVOCATION_ARG_TYPE('c', char, charValue)
                    SET_INVOCATION_ARG_TYPE('C', unsigned char, unsignedCharValue)
                    SET_INVOCATION_ARG_TYPE('s', short, shortValue)
                    SET_INVOCATION_ARG_TYPE('S', unsigned short, unsignedShortValue)
                    SET_INVOCATION_ARG_TYPE('i', int, intValue)
                    SET_INVOCATION_ARG_TYPE('I', unsigned int, unsignedIntValue)
                    SET_INVOCATION_ARG_TYPE('l', long, longValue)
                    SET_INVOCATION_ARG_TYPE('L', unsigned long, unsignedLongValue)
                    SET_INVOCATION_ARG_TYPE('q', long long, longLongValue)
                    SET_INVOCATION_ARG_TYPE('Q', unsigned long long,
                                            unsignedLongLongValue)
                    SET_INVOCATION_ARG_TYPE('f', float, floatValue)
                    SET_INVOCATION_ARG_TYPE('d', double, doubleValue)
                    SET_INVOCATION_ARG_TYPE('B', BOOL, boolValue)
                    
                case ':': {
                    SEL value = nil;
                    if (argValue != _nilObj) {
                        value = NSSelectorFromString(argValue);
                    }
                    [invocation setArgument:&value atIndex:index];
                    break;
                }
                    
                default: {
                    if (argValue == _nullObj) {
                        argValue = [NSNull null];
                        [invocation setArgument:&argValue atIndex:index];
                        break;
                    }
                    if (argValue == _nilObj ||
                        ([argValue isKindOfClass:[NSNumber class]] &&
                         strcmp([argValue objCType], "c") == 0 &&
                         ![argValue boolValue])) {
                            argValue = nil;
                            [invocation setArgument:&argValue atIndex:index];
                            break;
                        }
                    
                    [invocation setArgument:&argValue atIndex:index];
                }
            }
        }
    }
}

+ (id)batmanGetReturnFromInvocation:(NSInvocation *)invocation withSignature:(NSMethodSignature *)signature {
    char returnType[255];
    strcpy(returnType, [signature methodReturnType]);
    id returnValue;
    if (strncmp(returnType, "v", 1) != 0) {
        if (strncmp(returnType, "@", 1) == 0) {
            void *result;
            [invocation getReturnValue:&result];
            
            // For performance, ignore the other methods prefix with
            // alloc/new/copy/mutableCopy
            NSString *selectorName = NSStringFromSelector(invocation.selector);
            if ([selectorName isEqualToString:@"alloc"] ||
                [selectorName isEqualToString:@"new"] ||
                [selectorName isEqualToString:@"copy"] ||
                [selectorName isEqualToString:@"mutableCopy"]) {
                returnValue = (__bridge_transfer id)result;
            }
            else {
                returnValue = (__bridge id)result;
            }
            return returnValue;
        }
        else {
            switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
                    
#define JP_CALL_RET_CASE(_typeString, _type)                                   \
case _typeString: {                                                        \
_type tempResultSet;                                                   \
[invocation getReturnValue:&tempResultSet];                            \
returnValue = @(tempResultSet);                                        \
break;                                                                 \
}
                    JP_CALL_RET_CASE('c', char)
                    JP_CALL_RET_CASE('C', unsigned char)
                    JP_CALL_RET_CASE('s', short)
                    JP_CALL_RET_CASE('S', unsigned short)
                    JP_CALL_RET_CASE('i', int)
                    JP_CALL_RET_CASE('I', unsigned int)
                    JP_CALL_RET_CASE('l', long)
                    JP_CALL_RET_CASE('L', unsigned long)
                    JP_CALL_RET_CASE('q', long long)
                    JP_CALL_RET_CASE('Q', unsigned long long)
                    JP_CALL_RET_CASE('f', float)
                    JP_CALL_RET_CASE('d', double)
                    JP_CALL_RET_CASE('B', BOOL)
                    
                case '{': {
                    NSString *typeString = extractStructName(
                                                             [NSString stringWithUTF8String:returnType]);
#define JP_CALL_RET_STRUCT(_type, _methodName)                                 \
if ([typeString rangeOfString:@ #_type].location != NSNotFound) {          \
_type result;                                                          \
[invocation getReturnValue:&result];                                   \
return [JSValue _methodName:result inContext:[self context]];          \
}
                    if ([typeString rangeOfString:@"CGRect"].location !=
                        NSNotFound) {
                        CGRect rect;
                        [invocation getReturnValue:&rect];
                        return @{
                                 kStructTypeKey : @"CGRect",
                                 @"x" : @(rect.origin.x),
                                 @"y" : @(rect.origin.y),
                                 @"width" : @(rect.size.width),
                                 @"height" : @(rect.size.height),
                                 };
                    }
                    if ([typeString rangeOfString:@"CGPoint"].location !=
                        NSNotFound) {
                        CGPoint result;
                        [invocation getReturnValue:&result];
                        return @{
                                 kStructTypeKey : @"CGPoint",
                                 @"x" : @(result.x),
                                 @"y" : @(result.y)
                                 };
                    }
                    if ([typeString rangeOfString:@"CGSize"].location !=
                        NSNotFound) {
                        CGSize result;
                        [invocation getReturnValue:&result];
                        return @{
                                 kStructTypeKey : @"CGSize",
                                 @"width" : @(result.width),
                                 @"height" : @(result.height)
                                 };
                    }
                    if ([typeString rangeOfString:@"NSRange"].location !=
                        NSNotFound) {
                        NSRange result;
                        [invocation getReturnValue:&result];
                        return @{
                                 kStructTypeKey : @"NSRange",
                                 @"loc" : @(result.location),
                                 @"len" : @(result.length)
                                 };
                    }
                }
                case '#': {
                    Class result;
                    [invocation getReturnValue:&result];
                    returnValue = result;
                    break;
                }
            }
            return returnValue;
        }
    }
    
    return nil;
}

@end
