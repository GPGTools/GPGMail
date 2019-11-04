//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "BannerViewController.h"

@class NSButton, NSString, NSTextField;

@interface CalendarBannerViewController : BannerViewController
{
    NSTextField *_eventTitle;	// 16 = 0x10
    NSTextField *_eventTime;	// 24 = 0x18
    NSButton *_openCalendarButton;	// 32 = 0x20
    NSString *_alternateTimeProposal;	// 40 = 0x28
}

+ (id)keyPathsForValuesAffectingShouldHideMeetingCancellationOKButton;	// IMP=0x00000001000ca663
+ (id)keyPathsForValuesAffectingShouldHideMeetingRequestButtons;	// IMP=0x00000001000ca5cf
@property(copy, nonatomic) NSString *alternateTimeProposal; // @synthesize alternateTimeProposal=_alternateTimeProposal;
@property(nonatomic) __weak NSButton *openCalendarButton; // @synthesize openCalendarButton=_openCalendarButton;
@property(nonatomic) __weak NSTextField *eventTime; // @synthesize eventTime=_eventTime;
@property(nonatomic) __weak NSTextField *eventTitle; // @synthesize eventTitle=_eventTitle;
- (void).cxx_destruct;	// IMP=0x00000001000cb564
- (id)_dateStringForEvent:(id)arg1;	// IMP=0x00000001000cb016
- (id)_titleForEvent:(id)arg1;	// IMP=0x00000001000cae6b
- (id)_eventForCurrentMessage;	// IMP=0x00000001000caca9
- (void)openInCalendar:(id)arg1;	// IMP=0x00000001000caa9a
- (void)sendMeetingResponse:(id)arg1;	// IMP=0x00000001000ca6f7
@property(readonly, nonatomic) BOOL shouldHideMeetingCancellationOKButton;
@property(readonly, nonatomic) BOOL shouldHideMeetingRequestButtons;
- (void)updateBannerContents;	// IMP=0x00000001000ca3fe
- (id)_proposalStringForMessage:(id)arg1 withAttachments:(id)arg2;	// IMP=0x00000001000c9ecc
- (void)updateWantsDisplay;	// IMP=0x000000010003bf8e
- (double)bannerHeight;	// IMP=0x00000001000c9ea3

@end

