//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

@class MFUpdateAttachmentsWithAttachmentIDUpgradeStep, NSURL;
@protocol NSFastEnumeration;

@protocol MFUpdateAttachmentsWithAttachmentIDUpgradeStepDataSource
- (BOOL)updateAttachmentsWithAttachmentIDUpgradeStep:(MFUpdateAttachmentsWithAttachmentIDUpgradeStep *)arg1 isDirectoryForFileURL:(NSURL *)arg2;
- (void (^)(void))skipDescendantsBlockForUpdateAttachmentsWithAttachmentIDUpgradeStep:(MFUpdateAttachmentsWithAttachmentIDUpgradeStep *)arg1;
- (id <NSFastEnumeration>)fileURLEnumeratorForUpdateAttachmentsWithAttachmentIDUpgradeStep:(MFUpdateAttachmentsWithAttachmentIDUpgradeStep *)arg1;
@end

