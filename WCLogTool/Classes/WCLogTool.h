//
//  WCLogTool.h
//  HelloTest
//
//  Created by wesley_chen on 23/08/2017.
//  Copyright © 2017 wesley_chen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WCLogLevel) {
    WCLogLevelDebug,
    WCLogLevelInfo,
    WCLogLevelWarning,
    WCLogLevelError,
    WCLogLevelAlert,
};

// Log suite in ObjC methods
#define LogEventD(args...) LogEventInMethod(WCLogLevelDebug, args)
#define LogEventI(args...) LogEventInMethod(WCLogLevelInfo, args)
#define LogEventW(args...) LogEventInMethod(WCLogLevelWarning, args)
#define LogEventE(args...) LogEventInMethod(WCLogLevelError, args)
#define LogEventA(args...) LogEventInMethod(WCLogLevelAlert, args)

// Log suite in C functions
#define CLogEventD(args...) LogEventInFunction(WCLogLevelDebug, args)
#define CLogEventI(args...) LogEventInFunction(WCLogLevelInfo, args)
#define CLogEventW(args...) LogEventInFunction(WCLogLevelWarning, args)
#define CLogEventE(args...) LogEventInFunction(WCLogLevelError, args)
#define CLogEventA(args...) LogEventInFunction(WCLogLevelAlert, args)

#define LogEventInMethod(level, args...)    wc_eventLogInMethod(level, self, _cmd, __FILE__, __LINE__, __PRETTY_FUNCTION__, args)
#define LogEventInFunction(level, args...)  wc_eventLogInFunction(level, __FILE__, __LINE__, __PRETTY_FUNCTION__, args)

extern void wc_eventLogInMethod(WCLogLevel level, id slf, SEL sel, const char *file, int lineNumber, const char *funcName, NSString *format, ...);
extern void wc_eventLogInFunction(WCLogLevel level, const char *file, int lineNumber, const char *funcName, NSString *format,...);

// @seehttps://stackoverflow.com/questions/21512382/how-do-i-define-a-macro-with-variadic-method-in-objective-c
// ## __VA_ARGS__ 的原因

@interface WCLogControl : NSObject
@property (nonatomic, assign, readonly) WCLogLevel logLevel; /**< current log level for log files */

+ (instancetype)sharedInstance;
- (void)setLogLevel:(WCLogLevel)logLevel;

@end
