//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <MailUI/MUIAddressTokenAttachmentCell.h>

@class NSSet, NSString;

@interface ParticipantTokenCell : MUIAddressTokenAttachmentCell
{
    NSString *_displayName;	// 56 = 0x38
    unsigned long long _count;	// 64 = 0x40
    BOOL _isVipCell;	// 72 = 0x48
}

@property(nonatomic) BOOL isVipCell; // @synthesize isVipCell=_isVipCell;
- (void).cxx_destruct;	// IMP=0x0000000100249fd8
- (id)_defaultAttributes;	// IMP=0x0000000100249e5e
- (BOOL)shouldDrawTokenBackground;	// IMP=0x0000000100249e23
- (void)_updateStringValue;	// IMP=0x0000000100249d00
- (id)_displayAttributedStringIsSelected:(BOOL)arg1;	// IMP=0x0000000100249a8b
- (id)tokenTintColor;	// IMP=0x0000000100249a48
- (void)drawInteriorWithFrame:(struct CGRect)arg1 inView:(id)arg2;	// IMP=0x0000000100249934
- (void)_updateVipStatus;	// IMP=0x00000001002497c2
@property(retain) NSSet *representedObject;
@property(nonatomic) unsigned long long count;
@property(copy, nonatomic) NSString *displayName;
- (BOOL)trackMouse:(id)arg1 inRect:(struct CGRect)arg2 ofView:(id)arg3 atCharacterIndex:(unsigned long long)arg4 untilMouseUp:(BOOL)arg5;	// IMP=0x00000001002493db
- (BOOL)_canBeSelected;	// IMP=0x00000001002493be
- (id)initWithCoder:(id)arg1;	// IMP=0x00000001002492ef
- (id)initTextCell:(id)arg1;	// IMP=0x0000000100249220
- (id)initWithDisplayName:(id)arg1 count:(unsigned long long)arg2;	// IMP=0x0000000100249178

@end

