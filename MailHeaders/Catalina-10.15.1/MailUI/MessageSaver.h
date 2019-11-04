//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "MCActivityTarget-Protocol.h"

@class NSArray, NSButton, NSPopUpButton, NSSavePanel, NSSet, NSString, NSURL, NSView, NSWindow;

@interface MessageSaver : NSObject <MCActivityTarget>
{
    BOOL _haveAttachments;	// 8 = 0x8
    BOOL _hideExtension;	// 9 = 0x9
    BOOL _includeAttachments;	// 10 = 0xa
    BOOL _blockRemoteContent;	// 11 = 0xb
    NSView *_accessoryView;	// 16 = 0x10
    NSPopUpButton *_formatPopup;	// 24 = 0x18
    NSButton *_includeAttachmentsSwitch;	// 32 = 0x20
    NSArray *_messages;	// 40 = 0x28
    NSSet *_stores;	// 48 = 0x30
    NSSavePanel *_savePanel;	// 56 = 0x38
    NSWindow *_window;	// 64 = 0x40
    NSURL *_saveDestination;	// 72 = 0x48
    long long _saveFormat;	// 80 = 0x50
}

+ (void)saveMessages:(id)arg1 preferredFormat:(long long)arg2 blockRemoteContent:(BOOL)arg3 window:(id)arg4;	// IMP=0x00000001001fcba6
+ (void)initialize;	// IMP=0x00000001001fc5ca
@property(nonatomic) long long saveFormat; // @synthesize saveFormat=_saveFormat;
@property(nonatomic) BOOL blockRemoteContent; // @synthesize blockRemoteContent=_blockRemoteContent;
@property(nonatomic) BOOL includeAttachments; // @synthesize includeAttachments=_includeAttachments;
@property(nonatomic) BOOL hideExtension; // @synthesize hideExtension=_hideExtension;
@property(nonatomic) BOOL haveAttachments; // @synthesize haveAttachments=_haveAttachments;
@property(retain, nonatomic) NSURL *saveDestination; // @synthesize saveDestination=_saveDestination;
@property(retain, nonatomic) NSWindow *window; // @synthesize window=_window;
@property(nonatomic) __weak NSSavePanel *savePanel; // @synthesize savePanel=_savePanel;
@property(copy, nonatomic) NSSet *stores; // @synthesize stores=_stores;
@property(copy, nonatomic) NSArray *messages; // @synthesize messages=_messages;
@property(nonatomic) __weak NSButton *includeAttachmentsSwitch; // @synthesize includeAttachmentsSwitch=_includeAttachmentsSwitch;
@property(nonatomic) __weak NSPopUpButton *formatPopup; // @synthesize formatPopup=_formatPopup;
@property(retain, nonatomic) NSView *accessoryView; // @synthesize accessoryView=_accessoryView;
- (void).cxx_destruct;	// IMP=0x000000010020004d
- (id)_separator;	// IMP=0x00000001001ffd19
- (void)changeIncludeAttachments:(id)arg1;	// IMP=0x00000001001ffcab
- (void)changeFormat:(id)arg1;	// IMP=0x00000001001ffc19
- (void)_handleSaveError:(id)arg1;	// IMP=0x00000001001ffb91
- (void)_copyMessages;	// IMP=0x00000001001ff8cb
- (void)_saveMessagesToDirectory;	// IMP=0x00000001001fee38
- (void)_saveMessages;	// IMP=0x00000001001fdec2
- (void)_updateSavePanelUI;	// IMP=0x00000001001fdcc9
- (void)_runSavePanel;	// IMP=0x00000001001fd528
- (void)_savePanelDidEndWithFileHandlingResult:(long long)arg1;	// IMP=0x00000001001fd1a0
- (void)_setSaveFormat:(long long)arg1;	// IMP=0x00000001001fd11f
- (void)_setMessages:(id)arg1;	// IMP=0x00000001001fcc6c
- (void)copyMessagesWithoutPrompting:(id)arg1 toDestinationDirectory:(id)arg2;	// IMP=0x00000001001fca5a
- (void)saveMessagesAsRawSourceWithoutPrompting:(id)arg1 toDestinationDirectory:(id)arg2;	// IMP=0x00000001001fc93d
- (void)saveMessagesWithoutPrompting:(id)arg1 toFilePath:(id)arg2 format:(long long)arg3;	// IMP=0x00000001001fc725

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly, copy, nonatomic) NSString *displayName;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

