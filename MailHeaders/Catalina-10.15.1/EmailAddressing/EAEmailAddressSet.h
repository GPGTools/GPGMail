//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Foundation/NSMutableSet.h>

#import <EmailAddressing/EFLoggable-Protocol.h>
#import <EmailAddressing/NSSecureCoding-Protocol.h>

@class NSData, NSString;

@interface EAEmailAddressSet : NSMutableSet <EFLoggable, NSSecureCoding>
{
    NSMutableSet *_internalSet;	// 8 = 0x8
}

+ (BOOL)supportsSecureCoding;	// IMP=0x0000000000006494
+ (id)setWithCapacity:(unsigned long long)arg1;	// IMP=0x00000000000060c3
+ (id)set;	// IMP=0x0000000000006001
+ (id)log;	// IMP=0x0000000000005f22
@property(retain, nonatomic) NSMutableSet *internalSet; // @synthesize internalSet=_internalSet;
- (void).cxx_destruct;	// IMP=0x00000000000077c2
- (void)setSet:(id)arg1;	// IMP=0x0000000000007626
- (void)intersectSet:(id)arg1;	// IMP=0x000000000000750e
- (void)minusSet:(id)arg1;	// IMP=0x00000000000073ff
- (void)unionSet:(id)arg1;	// IMP=0x00000000000072f0
- (void)removeAllObjects;	// IMP=0x000000000000729d
- (void)removeObject:(id)arg1;	// IMP=0x00000000000070e6
- (void)addObject:(id)arg1;	// IMP=0x0000000000006f2f
- (unsigned long long)countByEnumeratingWithState:(CDStruct_58648341 *)arg1 objects:(id *)arg2 count:(unsigned long long)arg3;	// IMP=0x0000000000006e61
- (id)objectEnumerator;	// IMP=0x0000000000006e2b
- (id)allObjects;	// IMP=0x0000000000006c28
- (BOOL)isEqualToSet:(id)arg1;	// IMP=0x0000000000006b51
- (BOOL)isSubsetOfSet:(id)arg1;	// IMP=0x0000000000006a22
- (BOOL)intersectsSet:(id)arg1;	// IMP=0x00000000000068f3
- (id)member:(id)arg1;	// IMP=0x00000000000066ed
- (unsigned long long)count;	// IMP=0x0000000000006693
- (void)encodeWithCoder:(id)arg1;	// IMP=0x00000000000065df
- (id)initWithCoder:(id)arg1;	// IMP=0x000000000000649f
@property(readonly, nonatomic) NSData *serializedRepresentation;
- (id)initWithSerializedRepresentation:(id)arg1;	// IMP=0x000000000000626c
- (id)copyWithZone:(struct _NSZone *)arg1;	// IMP=0x000000000000625a
- (id)mutableCopyWithZone:(struct _NSZone *)arg1;	// IMP=0x0000000000006194
- (id)initWithCapacity:(unsigned long long)arg1;	// IMP=0x00000000000060fa
- (id)init;	// IMP=0x0000000000006031

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

