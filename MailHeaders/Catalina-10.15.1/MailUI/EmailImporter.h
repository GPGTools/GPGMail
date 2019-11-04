//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "Importer.h"

@class NSArray, NSString, NSURL;

@interface EmailImporter : Importer
{
    NSArray *_sourceItems;	// 8 = 0x8
    NSString *_destinationFolderName;	// 16 = 0x10
    BOOL _errorsDuringImport;	// 24 = 0x18
    NSURL *_rootFolder;	// 32 = 0x20
    NSArray *_sourceFolders;	// 40 = 0x28
    char *_lineDelimiter;	// 48 = 0x30
    char *_fromSpaceSeparator;	// 56 = 0x38
    NSURL *_lastDirectoryFound;	// 64 = 0x40
}

+ (id)log;	// IMP=0x00000001001522c9
@property(retain, nonatomic) NSURL *lastDirectoryFound; // @synthesize lastDirectoryFound=_lastDirectoryFound;
@property(nonatomic) BOOL errorsDuringImport; // @synthesize errorsDuringImport=_errorsDuringImport;
@property(nonatomic) char *fromSpaceSeparator; // @synthesize fromSpaceSeparator=_fromSpaceSeparator;
@property(nonatomic) char *lineDelimiter; // @synthesize lineDelimiter=_lineDelimiter;
@property(copy, nonatomic) NSArray *sourceFolders; // @synthesize sourceFolders=_sourceFolders;
@property(retain, nonatomic) NSURL *rootFolder; // @synthesize rootFolder=_rootFolder;
- (void).cxx_destruct;	// IMP=0x0000000100154ede
- (id)mailboxForImportItem:(id)arg1;	// IMP=0x0000000100154d16
- (id)mailboxNameForImportItem:(id)arg1;	// IMP=0x0000000100154d01
- (id)lastCommonParentForItems:(id)arg1;	// IMP=0x0000000100154618
- (id)uniqueDirectoriesForItems:(id)arg1;	// IMP=0x0000000100154434
- (id)searchForValidItemsInsideDirectory:(id)arg1 limit:(unsigned long long)arg2 searchDepth:(long long)arg3 validityBlock:(CDUnknownBlockType)arg4;	// IMP=0x0000000100153abb
- (id)validItemsFromItems:(id)arg1;	// IMP=0x000000010015369a
- (void)addMessagesToLibrary:(id)arg1 withMailbox:(id)arg2;	// IMP=0x0000000100153331
- (BOOL)isValidMailbox:(id)arg1;	// IMP=0x0000000100153329
@property(copy, nonatomic) NSArray *sourceList;
@property(readonly, copy, nonatomic) NSString *destinationFolderName;
- (void)importMailbox:(id)arg1;	// IMP=0x0000000100152d15
- (void)cleanup;	// IMP=0x0000000100152d01
- (id)statusLine;	// IMP=0x0000000100152c2a
- (id)importFinishedText;	// IMP=0x0000000100152ade
- (void)importFinished;	// IMP=0x00000001001527e1
- (void)_revealMailbox:(id)arg1;	// IMP=0x000000010015272f
- (void)performImport;	// IMP=0x000000010015236c
- (id)init;	// IMP=0x0000000100152326

@end

