//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFEWSRequestOperation.h>

#import <Mail/NSSecureCoding-Protocol.h>

@class NSArray, NSString;

@interface MFEWSDeleteItemsRequestOperation : MFEWSRequestOperation <NSSecureCoding>
{
    NSArray *_EWSItemIds;	// 8 = 0x8
    NSString *_folderIdString;	// 16 = 0x10
}

+ (BOOL)supportsSecureCoding;	// IMP=0x0000000000075034
@property(readonly, copy, nonatomic) NSString *folderIdString; // @synthesize folderIdString=_folderIdString;
@property(readonly, copy, nonatomic) NSArray *EWSItemIds; // @synthesize EWSItemIds=_EWSItemIds;
- (void).cxx_destruct;	// IMP=0x000000000007570a
- (void)setupOfflineResponse;	// IMP=0x0000000000075673
- (id)prepareRequest;	// IMP=0x00000000000753f4
- (id)activityString;	// IMP=0x00000000000751ad
- (void)_ewsDeleteItemsRequestOperationCommonInitWithEWSItemIds:(id)arg1 folderIdString:(id)arg2;	// IMP=0x000000000007510e
- (id)initWithGateway:(id)arg1 errorHandler:(id)arg2;	// IMP=0x000000000007503f
- (void)encodeWithCoder:(id)arg1;	// IMP=0x0000000000074f53
- (id)initWithCoder:(id)arg1;	// IMP=0x0000000000074d79
- (id)initWithEWSItemIds:(id)arg1 folderIdString:(id)arg2 gateway:(id)arg3;	// IMP=0x0000000000074c85

@end

