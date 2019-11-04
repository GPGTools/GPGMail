//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFEWSRequestOperation.h>

@class EWSSearchExpressionType, MFEWSFindItemsResponseOperation, NSArray;

@interface MFEWSFindItemsRequestOperation : MFEWSRequestOperation
{
    NSArray *_EWSFolderIdStrings;	// 8 = 0x8
    NSArray *_additionalProperties;	// 16 = 0x10
    EWSSearchExpressionType *_searchExpression;	// 24 = 0x18
}

@property(readonly, nonatomic) EWSSearchExpressionType *searchExpression; // @synthesize searchExpression=_searchExpression;
@property(readonly, copy, nonatomic) NSArray *additionalProperties; // @synthesize additionalProperties=_additionalProperties;
@property(readonly, copy, nonatomic) NSArray *EWSFolderIdStrings; // @synthesize EWSFolderIdStrings=_EWSFolderIdStrings;
- (void).cxx_destruct;	// IMP=0x000000000007c0c2
- (id)prepareRequest;	// IMP=0x000000000007bd1d
- (id)newResponseOperationWithGateway:(id)arg1 errorHandler:(id)arg2;	// IMP=0x000000000007bcb1
@property(retain, nonatomic) MFEWSFindItemsResponseOperation *responseOperation;
- (id)activityString;	// IMP=0x000000000007b8f1
- (id)initWithGateway:(id)arg1 errorHandler:(id)arg2;	// IMP=0x000000000007b822
- (id)initWithSearchExpression:(id)arg1 EWSFolderIdStrings:(id)arg2 additionalProperties:(id)arg3 gateway:(id)arg4;	// IMP=0x000000000007b726

@end

