//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSToolbarItem.h>

@protocol FlaggedStatusToolbarItemDelegate;

@interface FlaggedStatusToolbarItem : NSToolbarItem
{
    id <FlaggedStatusToolbarItemDelegate> _delegate;	// 8 = 0x8
}

@property(nonatomic) __weak id <FlaggedStatusToolbarItemDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;	// IMP=0x0000000100161623
- (void)validate;	// IMP=0x0000000100025f8d
- (void)dealloc;	// IMP=0x0000000100161568
- (id)initWithItemIdentifier:(id)arg1;	// IMP=0x00000001000215d4

@end

