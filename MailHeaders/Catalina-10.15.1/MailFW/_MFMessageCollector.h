//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <Mail/MFMessageConsumer-Protocol.h>
#import <Mail/MFQueryProgressMonitor-Protocol.h>

@class NSArray, NSMutableArray, NSString;

@interface _MFMessageCollector : NSObject <MFMessageConsumer, MFQueryProgressMonitor>
{
    NSMutableArray *_messages;	// 8 = 0x8
    BOOL _didCancel;	// 16 = 0x10
}

@property(nonatomic) BOOL didCancel; // @synthesize didCancel=_didCancel;
- (void).cxx_destruct;	// IMP=0x0000000000109c27
- (void)finishedSendingMessages;	// IMP=0x0000000000109c0e
@property(readonly) BOOL shouldCancel;
- (void)newMessagesAvailable:(id)arg1 secondaryMessages:(id)arg2 fromUpdate:(BOOL)arg3;	// IMP=0x0000000000109b8a
@property(readonly, copy, nonatomic) NSArray *messages;
- (id)init;	// IMP=0x0000000000109b1e

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

