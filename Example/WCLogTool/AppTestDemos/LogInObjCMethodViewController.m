//
//  ViewController.m
//  AppTest
//
//  Created by wesley chen on 16/4/13.
//
//

#import "LogInObjCMethodViewController.h"
#import <WCLogTool/WCLogTool.h>

static void func_a()
{
    CLogEventD(@"func_a");
}

@implementation LogInObjCMethodViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    LogEventA(nil);
    LogEventD(@"view setup with %@", @"no parameters");
    
    [self.class classMethod_viewDidLoad];
    
    func_a();
}


+ (void)classMethod_viewDidLoad {
    LogEventE(@"call class method with %@", @"no parameters");
}

@end
