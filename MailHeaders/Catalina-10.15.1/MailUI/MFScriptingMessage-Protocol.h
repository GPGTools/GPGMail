//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "NSObject-Protocol.h"

@class NSArray, NSScriptObjectSpecifier, NSString;

@protocol MFScriptingMessage <NSObject>
@property(readonly, copy, nonatomic) NSArray *bccRecipients;
@property(readonly, copy, nonatomic) NSArray *ccRecipients;
@property(readonly, copy, nonatomic) NSArray *toRecipients;
@property(readonly) NSScriptObjectSpecifier *objectSpecifier;

@optional
- (void)replaceFormattedAddress:(NSString *)arg1 withAddress:(NSString *)arg2 forKey:(NSString *)arg3;
@end

