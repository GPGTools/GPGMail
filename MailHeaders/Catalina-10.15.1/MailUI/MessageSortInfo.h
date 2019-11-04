//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "ManagedListSortInfo-Protocol.h"

@class NSMutableDictionary, NSString;
@protocol MFMessageSortingValueDelegate;

@interface MessageSortInfo : NSObject <ManagedListSortInfo>
{
    NSMutableDictionary *_sortValues;	// 8 = 0x8
    id <MFMessageSortingValueDelegate> _sortValueDelegate;	// 16 = 0x10
}

@property(nonatomic) __weak id <MFMessageSortingValueDelegate> sortValueDelegate; // @synthesize sortValueDelegate=_sortValueDelegate;
- (void).cxx_destruct;	// IMP=0x0000000100200a3e
- (CDUnknownBlockType)newComparatorWithSortOrders:(id)arg1;	// IMP=0x000000010020073c
- (void)unregisterSortInfoForObject:(id)arg1;	// IMP=0x000000010020071c
- (void)registerSortInfoForObjects:(id)arg1;	// IMP=0x0000000100200694
- (void)registerSortInfoForObject:(id)arg1;	// IMP=0x0000000100200614
- (id)init;	// IMP=0x0000000100200545
- (id)initWithSortOrders:(id)arg1;	// IMP=0x000000010020045e

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

