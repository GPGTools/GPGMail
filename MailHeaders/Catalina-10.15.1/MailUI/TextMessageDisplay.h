//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "MessageTextViewDelegate-Protocol.h"

@class MCMessage, MessageTextView, NSAttributedString, NSString, NSWindow;

@interface TextMessageDisplay : NSObject <MessageTextViewDelegate>
{
    BOOL _showControlCharacters;	// 8 = 0x8
    MCMessage *_message;	// 16 = 0x10
    NSWindow *_singleWindow;	// 24 = 0x18
    MessageTextView *_textView;	// 32 = 0x20
    NSAttributedString *_rawSourceString;	// 40 = 0x28
}

+ (void)_removeDisplayForMessage:(id)arg1;	// IMP=0x00000001002a4901
+ (void)displayRawSourceForMessage:(id)arg1;	// IMP=0x00000001002a46e8
@property(nonatomic) BOOL showControlCharacters; // @synthesize showControlCharacters=_showControlCharacters;
@property(copy, nonatomic) NSAttributedString *rawSourceString; // @synthesize rawSourceString=_rawSourceString;
@property(nonatomic) __weak MessageTextView *textView; // @synthesize textView=_textView;
@property(retain, nonatomic) NSWindow *singleWindow; // @synthesize singleWindow=_singleWindow;
@property(retain, nonatomic) MCMessage *message; // @synthesize message=_message;
- (void).cxx_destruct;	// IMP=0x00000001002a5744
- (void)saveAs:(id)arg1;	// IMP=0x00000001002a55ef
- (void)toggleShowControlCharacters:(id)arg1;	// IMP=0x00000001002a55ad
- (void)showPrintPanel:(id)arg1;	// IMP=0x00000001002a548f
- (void)setTitle:(id)arg1;	// IMP=0x00000001002a541d
- (void)windowWillClose:(id)arg1;	// IMP=0x00000001002a53c1
- (void)bringToFront;	// IMP=0x00000001002a5375
- (BOOL)validateMenuItem:(id)arg1;	// IMP=0x00000001002a525a
- (id)messageTextView:(id)arg1 willReturnMenu:(id)arg2 forEvent:(id)arg3;	// IMP=0x00000001002a5080
- (void)_displayRawSource;	// IMP=0x00000001002a4dc8
- (void)_prepareForMessage:(id)arg1;	// IMP=0x00000001002a4afc
- (void)_beginBackgroundLoad;	// IMP=0x00000001002a4a63
- (void)dealloc;	// IMP=0x00000001002a49ee
- (void)awakeFromNib;	// IMP=0x00000001002a4921

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

