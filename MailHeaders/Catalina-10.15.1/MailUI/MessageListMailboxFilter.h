//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "MessageListFilter-Protocol.h"

@class MFMailbox, NSImage, NSPredicate, NSString;

@interface MessageListMailboxFilter : NSObject <MessageListFilter>
{
    MFMailbox *_mailbox;	// 8 = 0x8
}

@property(readonly, nonatomic) MFMailbox *mailbox; // @synthesize mailbox=_mailbox;
- (void).cxx_destruct;	// IMP=0x00000001001f2c46
@property(readonly, nonatomic) long long type;
@property(readonly, nonatomic) NSPredicate *predicate;
@property(readonly, copy, nonatomic) NSImage *icon;
@property(readonly, copy, nonatomic) NSString *name;
- (id)init;	// IMP=0x00000001001f2944
- (id)initWithMailbox:(id)arg1;	// IMP=0x00000001001f28d9

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

