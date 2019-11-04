//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Foundation/NSOperation.h>

@class MCTaskHandler, NSError, NSString;

@interface MCTaskHandlerOperation : NSOperation
{
    BOOL _succeeded;	// 8 = 0x8
    MCTaskHandler *_handler;	// 16 = 0x10
    NSError *_error;	// 24 = 0x18
    NSString *_logPrefix;	// 32 = 0x20
}

@property(copy) NSString *logPrefix; // @synthesize logPrefix=_logPrefix;
@property(retain) NSError *error; // @synthesize error=_error;
@property BOOL succeeded; // @synthesize succeeded=_succeeded;
@property(retain) MCTaskHandler *handler; // @synthesize handler=_handler;
- (void).cxx_destruct;	// IMP=0x0000000000099a83

@end

