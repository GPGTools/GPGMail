//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPMailboxCommand.h>

@class MCActivityMonitor, NSArray, NSData, NSDate, NSDictionary;

@interface IMAPAppendCommand : IMAPMailboxCommand
{
    BOOL _shouldTryCreate;	// 24 = 0x18
    NSDate *_dateReceived;	// 32 = 0x20
    NSArray *_serverFlags;	// 40 = 0x28
    NSDictionary *_messageInfo;	// 48 = 0x30
    MCActivityMonitor *_progressMonitor;	// 56 = 0x38
    NSData *_data;	// 64 = 0x40
}

@property(readonly, copy, nonatomic) NSData *data; // @synthesize data=_data;
@property BOOL shouldTryCreate; // @synthesize shouldTryCreate=_shouldTryCreate;
@property(retain) MCActivityMonitor *progressMonitor; // @synthesize progressMonitor=_progressMonitor;
@property(copy) NSDictionary *messageInfo; // @synthesize messageInfo=_messageInfo;
@property(copy) NSArray *serverFlags; // @synthesize serverFlags=_serverFlags;
@property(retain) NSDate *dateReceived; // @synthesize dateReceived=_dateReceived;
- (void).cxx_destruct;	// IMP=0x0000000000037a2d
- (BOOL)executeOnConnection:(id)arg1;	// IMP=0x0000000000037940
- (id)newCommandDataForLiteralPlus:(BOOL)arg1;	// IMP=0x000000000003772b
- (id)debugCommandStringWithAccount:(id)arg1;	// IMP=0x0000000000037652
- (BOOL)shouldSendAgainOnError;	// IMP=0x0000000000037647
- (id)detailsString;	// IMP=0x000000000003753c
- (id)activityString;	// IMP=0x00000000000374cf
- (id)commandTypeString;	// IMP=0x00000000000374b0
- (id)initWithMailboxName:(id)arg1;	// IMP=0x00000000000373e1
- (id)initWithMailboxName:(id)arg1 flags:(id)arg2 dateReceived:(id)arg3 data:(id)arg4;	// IMP=0x0000000000037089

@end

