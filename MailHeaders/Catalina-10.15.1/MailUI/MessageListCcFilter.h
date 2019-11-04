//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "MessageListFilter-Protocol.h"

@class NSImage, NSPredicate, NSString;

@interface MessageListCcFilter : NSObject <MessageListFilter>
{
}

@property(readonly, nonatomic) long long type;
@property(readonly, nonatomic) NSPredicate *predicate;
@property(readonly, copy, nonatomic) NSImage *icon;
@property(readonly, copy, nonatomic) NSString *name;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

