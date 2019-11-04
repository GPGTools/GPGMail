//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSButton.h>

@class NSImage;

@interface _BorderlessButton : NSButton
{
    NSImage *_activeImage;	// 112 = 0x70
    NSImage *_inactiveImage;	// 120 = 0x78
}

@property(retain, nonatomic) NSImage *inactiveImage; // @synthesize inactiveImage=_inactiveImage;
@property(retain, nonatomic) NSImage *activeImage; // @synthesize activeImage=_activeImage;
- (void).cxx_destruct;	// IMP=0x00000001000c8015
- (void)setEnabled:(BOOL)arg1;	// IMP=0x00000001000c7f2f
- (void)dealloc;	// IMP=0x00000001000c7eef
- (BOOL)isOpaque;	// IMP=0x00000001000c7ee7

@end

