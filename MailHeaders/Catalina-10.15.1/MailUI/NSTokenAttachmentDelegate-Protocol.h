//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

@class NSMenu, NSTokenAttachment, NSTokenAttachmentCell, NSView;

@protocol NSTokenAttachmentDelegate

@optional
- (NSMenu *)menuForTokenAttachment:(NSTokenAttachment *)arg1;
- (BOOL)hasMenuForTokenAttachment:(NSTokenAttachment *)arg1;
- (BOOL)tokenAttachment:(NSTokenAttachment *)arg1 doubleClickedInRect:(struct CGRect)arg2 ofView:(NSView *)arg3 atCharacterIndex:(unsigned long long)arg4;
- (NSTokenAttachmentCell *)tokenAttachment:(NSTokenAttachment *)arg1 shouldUseTokenAttachmentCell:(NSTokenAttachmentCell *)arg2;
@end

