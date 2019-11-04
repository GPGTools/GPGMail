//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <MailCore/MCRemoteMessage.h>

#import <IMAP/IMAPMessage-Protocol.h>

@class ECSubject, NSDate, NSString;
@protocol IMAPAccount, IMAPMessageDataSource;

@interface IMAPMessage : MCRemoteMessage <IMAPMessage>
{
    unsigned int _uid;	// 104 = 0x68
    long long _originalFlags;	// 112 = 0x70
}

+ (void)initialize;	// IMP=0x000000000000f910
@property(readonly, nonatomic) long long originalFlags; // @synthesize originalFlags=_originalFlags;
- (void)setDataSource:(id)arg1;	// IMP=0x000000000000fa50
@property(readonly) id <IMAPMessageDataSource> dataSource;
@property(readonly, nonatomic) id <IMAPAccount> account;
- (id)remoteMailboxURLString;	// IMP=0x000000000000fc57
- (id)remoteID;	// IMP=0x000000000000fca7
@property(readonly, copy, nonatomic) NSString *mailboxName;
- (BOOL)isMessageContentLocallyAvailable;	// IMP=0x0000000000042558
@property unsigned int uid;
@property(readonly, copy, nonatomic) NSString *messageID;
@property(readonly, copy) NSString *description;
- (id)initWithFlags:(long long)arg1 size:(unsigned long long)arg2 uid:(unsigned int)arg3;	// IMP=0x000000000000f927

// Remaining properties
@property(readonly) NSDate *dateReceived;
@property(readonly, copy) NSString *debugDescription;
@property(readonly, nonatomic) BOOL hasAttachments;
@property(readonly) unsigned long long hash;
@property BOOL isPartial;
@property(readonly) unsigned long long messageSize;
@property BOOL partsHaveBeenCached;
@property(readonly, nonatomic) BOOL shouldDeferBodyDownload;
@property(readonly, copy) ECSubject *subject;
@property(readonly) Class superclass;

@end

