//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSButton.h>

@interface MailBarContainerButton : NSButton
{
    BOOL _isPerformingSearchScope;	// 108 = 0x6c
}

- (BOOL)shouldSetFontSmoothingBackgroundColor;	// IMP=0x000000010002c210
@property(nonatomic) BOOL isPerformingSearchScope;
- (void)_mailBarContainerButtonCommonInit;	// IMP=0x00000001001a8571
- (id)initWithCoder:(id)arg1;	// IMP=0x00000001001a852a
- (id)initWithFrame:(struct CGRect)arg1;	// IMP=0x00000001000103a6

@end

