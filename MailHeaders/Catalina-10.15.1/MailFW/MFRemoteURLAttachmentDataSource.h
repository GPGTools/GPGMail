//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <MailCore/MCRemoteURLAttachmentDataSource.h>

#import <Mail/MCRemoteAttachmentDataSource-Protocol.h>

@class NSString;

@interface MFRemoteURLAttachmentDataSource : MCRemoteURLAttachmentDataSource <MCRemoteAttachmentDataSource>
{
}

- (void)_persistDownloadedFileWrapper:(id)arg1 originalContentsURL:(id)arg2;	// IMP=0x00000000001f3ed2
- (void)fetchAttachmentForAccessLevel:(long long)arg1 mimePartNumber:(id)arg2 withCompletionBlock:(CDUnknownBlockType)arg3;	// IMP=0x00000000001f3df7

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

