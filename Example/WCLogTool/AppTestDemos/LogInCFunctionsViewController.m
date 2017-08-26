//
//  LogInCFunctionsViewController.m
//  WCLogTool
//
//  Created by wesley_chen on 25/08/2017.
//  Copyright © 2017 daydreamboy. All rights reserved.
//

#import "LogInCFunctionsViewController.h"
#import <WCLogTool/WCLogTool.h>

void callAFunction(NSString *string)
{
    NSLog(@"call a c function");
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    CLogEventD(nil);
    CLogEventD(@"a test for calling c function with %@", @"some parameters");
    CLogEventE(@"a test for calling c function");
    
    CLogEventI(@"%@", @"some");
    CLogEventW(@"some");
}

static void func_a()
{
    CLogEventD(@"func_a");
}

@implementation LogInCFunctionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    callAFunction(@"test a");
    func_a();
}

@end
