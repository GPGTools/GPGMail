//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class MCTaskHandlerOperation, NSDate, NSOperationQueue;
@protocol MCHandlerDelegate;

@interface MCTaskHandler : NSObject
{
    MCTaskHandlerOperation *_operation;	// 8 = 0x8
    BOOL _isCleaningUp;	// 16 = 0x10
    id <MCHandlerDelegate> _delegate;	// 24 = 0x18
    long long _priority;	// 32 = 0x20
    NSDate *_cancelTime;	// 40 = 0x28
    NSOperationQueue *_queue;	// 48 = 0x30
}

+ (id)keyPathsForValuesAffectingPriority;	// IMP=0x00000000000991c5
+ (id)log;	// IMP=0x0000000000098f6f
@property(readonly, nonatomic) NSOperationQueue *queue; // @synthesize queue=_queue;
@property(retain, nonatomic) NSDate *cancelTime; // @synthesize cancelTime=_cancelTime;
@property(nonatomic) BOOL isCleaningUp; // @synthesize isCleaningUp=_isCleaningUp;
@property(nonatomic) long long priority; // @synthesize priority=_priority;
@property(nonatomic) __weak id <MCHandlerDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;	// IMP=0x00000000000999af
@property(readonly, nonatomic) NSOperationQueue *serializationQueue;
- (id)newCleanUpOperation;	// IMP=0x00000000000998d3
- (void)cleanUp;	// IMP=0x0000000000099786
- (void)_operationDidFinish:(id)arg1;	// IMP=0x00000000000994c3
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;	// IMP=0x000000000009935b
@property(readonly, nonatomic) long long qualityOfService;
@property(retain, nonatomic) MCTaskHandlerOperation *operation;
- (void)dealloc;	// IMP=0x00000000000990d4
- (id)init;	// IMP=0x0000000000098fcc

@end

