//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFEWSPersistenceTaskOperation.h>

@class NSString;

@interface MFEWSDeleteMailboxTaskOperation : MFEWSPersistenceTaskOperation
{
    BOOL _didDelete;	// 8 = 0x8
    NSString *_folderIDString;	// 16 = 0x10
}

@property(readonly, copy, nonatomic) NSString *folderIDString; // @synthesize folderIDString=_folderIDString;
@property(nonatomic) BOOL didDelete; // @synthesize didDelete=_didDelete;
- (void).cxx_destruct;	// IMP=0x000000000007598b
- (void)main;	// IMP=0x0000000000075884
- (id)init;	// IMP=0x00000000000757b5
- (id)initWithFolderIDString:(id)arg1;	// IMP=0x000000000007573b

@end

