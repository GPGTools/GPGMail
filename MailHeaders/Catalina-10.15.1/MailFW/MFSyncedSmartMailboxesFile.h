//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFSyncedFile.h>

@interface MFSyncedSmartMailboxesFile : MFSyncedFile
{
}

+ (id)syncedSmartMailboxesFile;	// IMP=0x0000000000231e5b
- (id)upgradeLegacyCloudData:(id)arg1 fromLegacyVersion:(long long)arg2;	// IMP=0x00000000002324b2
- (id)resolveConflictVersion:(id)arg1 againstCurrentVersion:(id)arg2;	// IMP=0x0000000000231e9f
- (void)writeSmartMailboxes:(id)arg1;	// IMP=0x0000000000231e8b
- (id)readSmartMailboxes;	// IMP=0x0000000000231e77

@end

