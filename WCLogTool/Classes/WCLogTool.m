//
//  WCLogTool.m
//  HelloTest
//
//  Created by wesley_chen on 23/08/2017.
//  Copyright © 2017 wesley_chen. All rights reserved.
//

#import "WCLogTool.h"
#import <objc/runtime.h>

@interface WCLogControl ()
@property (nonatomic, assign, readwrite) WCLogLevel logLevel;
@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong) NSDictionary *logLevelTags;
@property (nonatomic, strong) NSDictionary *logLevelShortTags;

@property (nonatomic, copy) NSString *logDirPath;
@property (nonatomic, copy) NSString *logFilePrefix;
@property (nonatomic, copy) NSString *logFileExtension;
@property (nonatomic, copy) NSString *currentLogFilePath;
@end

@implementation WCLogControl

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static WCLogControl *sInstance;
    dispatch_once(&onceToken, ^{
        sInstance = [[WCLogControl alloc] init];
    });
    
    return sInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
#if DEBUG
        _logLevel = WCLogLevelDebug;
#else
        _logLevel = WCLogLevelWarning;
#endif
        
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss.sss";
        formatter.timeZone = [NSTimeZone systemTimeZone];
        _formatter = formatter;
        
        _logLevelTags = @{
                          @(WCLogLevelDebug): @"DEBUG",
                          @(WCLogLevelInfo): @"INFO",
                          @(WCLogLevelWarning): @"WARNING",
                          @(WCLogLevelError): @"ERROR",
                          @(WCLogLevelAlert): @"ALERT",
                          };
        
        _logLevelShortTags = @{
                               @(WCLogLevelDebug): @"D",
                               @(WCLogLevelInfo): @"I",
                               @(WCLogLevelWarning): @"W",
                               @(WCLogLevelError): @"E",
                               @(WCLogLevelAlert): @"A",
                               };
        
        _logDirPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        _logFilePrefix = @"wc_log";
        _logFileExtension = @"txt";
    }
    return self;
}

- (void)setLogLevel:(WCLogLevel)logLevel {
    @synchronized (self) {
        _logLevel = logLevel;
    }
}

#pragma mark - 

- (const char *)levelCStringWithLogLevel:(WCLogLevel)logLevel {
    return [_logLevelTags[@(logLevel)] UTF8String];
}

- (NSString *)levelShortStringWithLogLevel:(WCLogLevel)logLevel {
    return _logLevelShortTags[@(logLevel)];
}

- (void)appendStringToFile:(NSString *)msg {
    NSString *path = [self createLogFileIfNeeded];
    // append
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

- (NSString *)createLogFileIfNeeded {
    // TODO: calculate current log file size
    //
    
    // create if needed
    self.currentLogFilePath = [NSString stringWithFormat:@"%@/%@.%@", self.logDirPath, self.logFilePrefix, self.logFileExtension];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.currentLogFilePath]) {
        fprintf(stderr,"Creating file at %s", self.currentLogFilePath.UTF8String);
        [[NSData data] writeToFile:self.currentLogFilePath atomically:YES];
    }
    
    return self.currentLogFilePath;
}

@end

#pragma mark - Public Methods

void wc_eventLogInMethod(WCLogLevel level, id slf, SEL sel, const char *file, int lineNumber, const char *funcName, NSString *format, ...)
{
    NSDate *timestamp = [NSDate date];

    NSString *timestampString = [[WCLogControl sharedInstance].formatter stringFromDate:timestamp];
    NSString *fileName = [[NSString alloc] initWithUTF8String:((strrchr(file, '/') ?: file - 1) + 1)];
    NSString *functionName = [[NSString alloc] initWithUTF8String:funcName];
    
    NSString *methodName = @"(null)";
    NSString *className = @"(null)";
    NSString *methodEncoding = @"(null)";
    NSMutableArray *parts = [[functionName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[ ]"]] mutableCopy];
    [parts removeObject:@""];
    if (parts.count == 3) {
        methodName = [NSString stringWithFormat:@"%@%@", parts[0], parts[2]];
        className = parts[1];
        
        // @see https://stackoverflow.com/questions/11491947/what-are-the-digits-in-an-objc-method-type-encoding-string
        // @see https://stackoverflow.com/questions/1538069/getting-type-encodings-for-method-signatures-in-cocoa-objective-c
        Method method = NULL;
        if (class_isMetaClass(object_getClass(slf))) {
            // class
            method = class_getClassMethod(slf, sel);
        }
        else {
            // object
            method = class_getInstanceMethod(((NSObject *)slf).class, sel);
        }
        if (method) {
            const char *encoding = method_getTypeEncoding(method);
            methodEncoding = [NSString stringWithUTF8String:encoding];
        }
    }
    else {
        NSLog(@"unexpected method name: %s", funcName);
    }
    
    va_list ap;
    va_start (ap, format);
    format = [format stringByReplacingOccurrencesOfString:@"%@" withString:@"`%@`"];
    NSMutableString *stringM = [NSMutableString stringWithFormat:@"%@@%@(%@)@%@@%f##",
                                [WCLogControl.sharedInstance levelShortStringWithLogLevel:level],
                                methodName,
                                methodEncoding,
                                className,
                                timestamp.timeIntervalSince1970];
    [stringM appendString:[[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@\n",format] arguments:ap]];
    va_end (ap);
    
    // Note: only print when DEBUG
#if DEBUG
    fprintf(stderr,"%s [%s][%s:%d] %s",
            timestampString.UTF8String,
            [WCLogControl.sharedInstance levelCStringWithLogLevel:level],
            fileName.UTF8String,
            lineNumber,
            stringM.UTF8String);
#endif
    
    if (level > [WCLogControl sharedInstance].logLevel) {
        [[WCLogControl sharedInstance] appendStringToFile:stringM];
    }
}

void wc_eventLogInFunction(WCLogLevel level, const char *file, int lineNumber, const char *funcName, NSString *format,...)
{
    NSDate *timestamp = [NSDate date];
    
    NSString *timestampString = [[WCLogControl sharedInstance].formatter stringFromDate:timestamp];
    NSString *fileName = [[NSString alloc] initWithUTF8String:((strrchr(file, '/') ?: file - 1) + 1)];
    NSString *functionName = [[NSString alloc] initWithUTF8String:funcName];
    
    va_list ap;
    va_start (ap, format);
    format = [format stringByReplacingOccurrencesOfString:@"%@" withString:@"`%@`"];
    NSMutableString *stringM = [NSMutableString stringWithFormat:@"%@@%@@%@@%f##",
                                [WCLogControl.sharedInstance levelShortStringWithLogLevel:level],
                                functionName,
                                fileName,
                                timestamp.timeIntervalSince1970];
    [stringM appendString:[[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@\n",format] arguments:ap]];
    va_end (ap);
    
    // Note: only print when DEBUG
#if DEBUG
    fprintf(stderr,"%s [%s][%s:%d] %s",
            timestampString.UTF8String,
            [WCLogControl.sharedInstance levelCStringWithLogLevel:level],
            fileName.UTF8String,
            lineNumber,
            stringM.UTF8String);
#endif
    
    if (level > [WCLogControl sharedInstance].logLevel) {
        [[WCLogControl sharedInstance] appendStringToFile:stringM];
    }
}

#pragma mark - Helper Functions

BOOL is_objc_method(const char *funcName)
{
    size_t len = strlen(funcName);
    if (len >= 3 && funcName[1] == '[' && funcName[len - 1] == ']') {
        return YES;
    }
    return NO;
}

