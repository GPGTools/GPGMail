//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <Mail/MCAttachmentDataSource-Protocol.h>

@class ECAngleBracketIDHash, NSString;
@protocol MCRemoteAttachmentDataSource;

@interface MFLibraryAttachmentDataSource : NSObject <MCAttachmentDataSource>
{
    BOOL _isMailDropImageArchive;	// 8 = 0x8
    BOOL _isMailDropImageThumbnail;	// 9 = 0x9
    BOOL _isAutoArchiveAttachment;	// 10 = 0xa
    id <MCRemoteAttachmentDataSource> _remoteDataSource;	// 16 = 0x10
    long long _messageID;	// 24 = 0x18
    NSString *_mimePartNumber;	// 32 = 0x20
    ECAngleBracketIDHash *_contentIDHash;	// 40 = 0x28
    NSString *_attachmentFilename;	// 48 = 0x30
}

+ (id)_asyncOperationQueue;	// IMP=0x000000000010ad32
@property(readonly, nonatomic) BOOL isAutoArchiveAttachment; // @synthesize isAutoArchiveAttachment=_isAutoArchiveAttachment;
@property(readonly, nonatomic) BOOL isMailDropImageThumbnail; // @synthesize isMailDropImageThumbnail=_isMailDropImageThumbnail;
@property(readonly, nonatomic) BOOL isMailDropImageArchive; // @synthesize isMailDropImageArchive=_isMailDropImageArchive;
@property(readonly, copy, nonatomic) NSString *attachmentFilename; // @synthesize attachmentFilename=_attachmentFilename;
@property(readonly, copy, nonatomic) ECAngleBracketIDHash *contentIDHash; // @synthesize contentIDHash=_contentIDHash;
@property(readonly, copy, nonatomic) NSString *mimePartNumber; // @synthesize mimePartNumber=_mimePartNumber;
@property(readonly, nonatomic) long long messageID; // @synthesize messageID=_messageID;
@property(readonly, nonatomic) id <MCRemoteAttachmentDataSource> remoteDataSource; // @synthesize remoteDataSource=_remoteDataSource;
- (void).cxx_destruct;	// IMP=0x000000000010d444
@property(readonly, nonatomic) BOOL isDirectory;
@property(readonly, nonatomic) BOOL canResultsBeCached;
@property(readonly, nonatomic) BOOL dataIsLocallyAvailable;
- (unsigned long long)approximateSizeForAccessLevel:(long long)arg1;	// IMP=0x000000000010cc0f
- (void)fileWrapperForAccessLevel:(long long)arg1 completionBlock:(CDUnknownBlockType)arg2;	// IMP=0x000000000010c392
- (void)_dataFromRemoteDataSourceWithAccessLevel:(long long)arg1 completionBlock:(CDUnknownBlockType)arg2;	// IMP=0x000000000010be4b
- (id)_dataFromStore:(id *)arg1;	// IMP=0x000000000010bb67
- (id)_dataFromBinaryAttachmentFile:(id *)arg1;	// IMP=0x000000000010b2de
- (void)dataForAccessLevel:(long long)arg1 completionBlock:(CDUnknownBlockType)arg2;	// IMP=0x000000000010afe6
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
- (id)init;	// IMP=0x000000000010ac63
- (id)initWithMessage:(id)arg1 mimePartNumber:(id)arg2 attachment:(id)arg3 remoteDataSource:(id)arg4;	// IMP=0x000000000010aaec

// Remaining properties
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

