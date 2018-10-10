//
//  SKViewController.m
//  SKGaara
//
//  Created by zhanghuabing on 10/08/2018.
//  Copyright (c) 2018 zhanghuabing. All rights reserved.
//

#import "SKViewController.h"
#import "SKGaara.h"

@interface SKViewController ()

@end

@implementation SKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self test];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Insfgg99x 的 hotfix


- (void)test {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"js"];
    [SKGaara setupContext];
    [SKGaara fixWithJSFile:jsPath];
    
    [self fixMethod];
}

- (void)fixMethod {
    
}

- (void)print:(NSString *)string {
    NSLog(@"%@", string);
}

@end
