//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFEWSResponseOperation.h>

@class EWSFindItemResponseType, NSArray, NSDictionary;

@interface MFEWSFindItemsResponseOperation : MFEWSResponseOperation
{
    NSArray *_EWSFolderIds;	// 8 = 0x8
    NSDictionary *_rootFoldersByEWSFolderId;	// 16 = 0x10
}

@property(copy, nonatomic) NSDictionary *rootFoldersByEWSFolderId; // @synthesize rootFoldersByEWSFolderId=_rootFoldersByEWSFolderId;
@property(copy, nonatomic) NSArray *EWSFolderIds; // @synthesize EWSFolderIds=_EWSFolderIds;
- (void).cxx_destruct;	// IMP=0x000000000007c863
- (id)rootFolderForEWSFolderId:(id)arg1;	// IMP=0x000000000007c795
- (void)executeOperation;	// IMP=0x000000000007c4ca
- (void)prepareToExecuteWithResponse:(id)arg1 forRequestOperation:(id)arg2;	// IMP=0x000000000007c270
@property(retain) EWSFindItemResponseType *response;

@end

