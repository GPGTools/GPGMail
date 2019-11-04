//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class NSCalendar, NSDate, NSMutableDictionary;

@interface MFUsageCounter : NSObject
{
    NSMutableDictionary *_counts;	// 8 = 0x8
    BOOL _isDirty;	// 16 = 0x10
    NSCalendar *_gregorianCalendar;	// 24 = 0x18
    NSDate *_referenceDate;	// 32 = 0x20
}

+ (void)setGatherJunkMailUsageCounts:(BOOL)arg1;	// IMP=0x00000000002378aa
+ (BOOL)gatherJunkMailUsageCounts;	// IMP=0x000000000023789f
+ (id)sharedInstance;	// IMP=0x0000000000237489
+ (id)allocWithZone:(struct _NSZone *)arg1;	// IMP=0x00000000002373d0
@property(readonly, nonatomic) NSDate *referenceDate; // @synthesize referenceDate=_referenceDate;
@property(readonly, nonatomic) NSCalendar *gregorianCalendar; // @synthesize gregorianCalendar=_gregorianCalendar;
- (void).cxx_destruct;	// IMP=0x00000000002383e0
- (void)incrementCountForKey:(id)arg1 byCount:(unsigned long long)arg2;	// IMP=0x00000000002380ff
- (void)incrementCountForKey:(id)arg1;	// IMP=0x00000000002380e8
- (void)removeCountForKey:(id)arg1;	// IMP=0x0000000000238066
- (unsigned long long)countForKey:(id)arg1 includeToday:(BOOL)arg2;	// IMP=0x0000000000237cfe
- (unsigned long long)countForKey:(id)arg1;	// IMP=0x0000000000237ce7
- (long long)numberOfDaysAvailableForKey:(id)arg1;	// IMP=0x0000000000237a04
- (void)saveDefaults;	// IMP=0x0000000000237946
- (id)_dictionaryForKey:(id)arg1 createIfNeeded:(BOOL)arg2;	// IMP=0x00000000002378b0
- (void)dealloc;	// IMP=0x00000000002377cf
- (id)init;	// IMP=0x0000000000237542

@end

