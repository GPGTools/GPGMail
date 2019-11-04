//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <Mail/MCActivityTarget-Protocol.h>

@class MCInvocationQueue, NSArray, NSCache, NSMutableDictionary, NSMutableSet, NSOperationQueue, NSString;

@interface MFAddressManager : NSObject <MCActivityTarget>
{
    NSMutableSet *_emailsAwaitingImage;	// 8 = 0x8
    NSMutableSet *_emailsWithoutImage;	// 16 = 0x10
    NSMutableDictionary *_recordsCache;	// 24 = 0x18
    NSMutableSet *_addressesWithNoRecords;	// 32 = 0x20
    BOOL _needToTrimRecordCaches;	// 40 = 0x28
    NSCache *_imageCache;	// 48 = 0x30
    MCInvocationQueue *_imageLoadingQueue;	// 56 = 0x38
    NSOperationQueue *_imageCreationQueue;	// 64 = 0x40
}

+ (id)addressManager;	// IMP=0x000000000001f22a
+ (id)allocWithZone:(struct _NSZone *)arg1;	// IMP=0x000000000001f171
@property(readonly, nonatomic) NSOperationQueue *imageCreationQueue; // @synthesize imageCreationQueue=_imageCreationQueue;
@property(readonly, nonatomic) MCInvocationQueue *imageLoadingQueue; // @synthesize imageLoadingQueue=_imageLoadingQueue;
@property(readonly, nonatomic) NSCache *imageCache; // @synthesize imageCache=_imageCache;
- (void).cxx_destruct;	// IMP=0x0000000000022c3e
@property(readonly, copy, nonatomic) NSArray *groups;
- (id)_addressBookRecordsForFirstName:(id)arg1 lastName:(id)arg2;	// IMP=0x00000000000229bc
- (id)addressBookPersonForEmail:(id)arg1;	// IMP=0x000000000002289d
- (id)_addressBookRecordForEmail:(id)arg1;	// IMP=0x00000000000226bc
- (void)removeRecentRecord:(id)arg1;	// IMP=0x0000000000022646
- (void)removeRecentAddresses:(id)arg1;	// IMP=0x0000000000022095
- (void)removeRecordFromAddressBook:(id)arg1 forRecent:(id)arg2;	// IMP=0x0000000000021fe8
- (id)addRecentToAddressBook:(id)arg1;	// IMP=0x0000000000021def
- (void)addAddresses:(id)arg1;	// IMP=0x0000000000021d79
- (void)addRecentAddresses:(id)arg1 sendingAddress:(id)arg2;	// IMP=0x0000000000021965
- (void)_addAddresses:(id)arg1;	// IMP=0x0000000000020c46
- (id)recordForUniqueId:(id)arg1;	// IMP=0x0000000000020bb7
- (void)_clearCachedImagesForRemovedRecords:(id)arg1;	// IMP=0x0000000000020aaa
- (void)_invalidateInsertedRecords:(id)arg1;	// IMP=0x0000000000020785
- (id)_fullAddressesForRecords:(id)arg1;	// IMP=0x00000000000203e4
- (void)_invalidateChangedRecords:(id)arg1;	// IMP=0x000000000001ff7e
- (void)_addressBookDidChange:(id)arg1;	// IMP=0x000000000001fc19
- (void)_trimRecordCaches;	// IMP=0x000000000001f935
- (void)_trimRecordCachesAfterDelay;	// IMP=0x000000000001f912
- (id)bestRecordMatchingFormattedAddress:(id)arg1;	// IMP=0x000000000001f726
- (void)_loadAddressBookSynchronously;	// IMP=0x000000000001f6b0
- (void)loadAddressBookAsynchronously;	// IMP=0x000000000001f5d3
- (void)dealloc;	// IMP=0x000000000001f4ce
- (id)init;	// IMP=0x000000000001f2e3

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly, copy, nonatomic) NSString *displayName;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

