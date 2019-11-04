//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <MailCore/MCActivityTarget-Protocol.h>

@class NSArray, NSMutableSet, NSString;
@protocol MCActivityTarget;

@interface _MCActivityMonitorMultiTarget : NSObject <MCActivityTarget>
{
    NSMutableSet *_allTargets;	// 8 = 0x8
    id <MCActivityTarget> _primaryTarget;	// 16 = 0x10
}

@property(retain, nonatomic) id <MCActivityTarget> primaryTarget; // @synthesize primaryTarget=_primaryTarget;
- (void).cxx_destruct;	// IMP=0x0000000000026208
@property(readonly, copy, nonatomic) NSString *displayName;
@property(readonly, copy, nonatomic) NSArray *allTargets;
- (BOOL)removeActivityTarget:(id)arg1;	// IMP=0x0000000000024897
- (BOOL)addActivityTarget:(id)arg1;	// IMP=0x00000000000225c7

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

