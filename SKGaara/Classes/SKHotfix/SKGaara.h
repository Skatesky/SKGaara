//
//  SKGaara.h
//  SKGaara
//
//  Created by zhanghuabing on 2018/10/8.
//

#import <Foundation/Foundation.h>

@interface SKGaara : NSObject

/// 启动修复环境
+ (void)setupContext;

/// 执行一段js来修复
+ (void)fix:(NSString *)jsString;

/// 根据js文件来修复
+ (void)fixWithJSFile:(NSString *)path;

@end
