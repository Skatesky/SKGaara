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
    
    [SKGaara setupContext];
    [SKGaara fix:[self getJS]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)getJS {
    return @"execute1()";
}

@end
