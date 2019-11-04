//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <Mail/NSCopying-Protocol.h>

@class MFSyncedSignatureContentsFile, NSData, NSString, WebArchive;

@interface MFSignature : NSObject <NSCopying>
{
    NSString *_name;	// 8 = 0x8
    NSData *_webArchiveData;	// 16 = 0x10
    BOOL _isRich;	// 24 = 0x18
    BOOL _isSavedAsRich;	// 25 = 0x19
    BOOL _isDirty;	// 26 = 0x1a
    NSString *_uniqueId;	// 32 = 0x20
    MFSyncedSignatureContentsFile *_syncedFile;	// 40 = 0x28
}

@property(nonatomic) BOOL isDirty; // @synthesize isDirty=_isDirty;
@property(readonly, nonatomic) BOOL isSavedAsRich; // @synthesize isSavedAsRich=_isSavedAsRich;
@property(readonly, nonatomic) MFSyncedSignatureContentsFile *syncedFile; // @synthesize syncedFile=_syncedFile;
@property(readonly, copy, nonatomic) NSString *uniqueId; // @synthesize uniqueId=_uniqueId;
- (void).cxx_destruct;	// IMP=0x00000000002057b7
- (unsigned long long)hash;	// IMP=0x000000000020573b
- (BOOL)isEqual:(id)arg1;	// IMP=0x0000000000205670
@property(nonatomic) BOOL isRich;
@property(copy, nonatomic) WebArchive *webArchive;
- (void)_makeWebArchiveDataIfNeeded;	// IMP=0x00000000002052ad
@property(readonly, copy, nonatomic) NSData *webArchiveData;
- (void)reloadFromDisk;	// IMP=0x00000000002051b7
@property(copy, nonatomic) NSString *name;
- (id)copyWithZone:(struct _NSZone *)arg1;	// IMP=0x0000000000204f8f
- (id)dictionaryRepresentation;	// IMP=0x0000000000204e74
- (void)removeContentFromDisk;	// IMP=0x0000000000204e1a
- (BOOL)saveContentToDisk;	// IMP=0x0000000000204c17
- (id)initWithDictionary:(id)arg1;	// IMP=0x0000000000204a3c
- (id)init;	// IMP=0x00000000002049c7
- (id)initWithName:(id)arg1;	// IMP=0x0000000000204930
- (id)initWithName:(id)arg1 uniqueId:(id)arg2;	// IMP=0x0000000000204846

@end

