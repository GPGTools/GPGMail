//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "NSCopying-Protocol.h"

@class MessageSortOrder, NSPredicate;

@interface MessageListContentProviderOptions : NSObject <NSCopying>
{
    BOOL _threadMessages;	// 8 = 0x8
    MessageSortOrder *_primarySortOrder;	// 16 = 0x10
    MessageSortOrder *_secondarySortOrder;	// 24 = 0x18
    NSPredicate *_filterPredicate;	// 32 = 0x20
}

@property(retain, nonatomic) NSPredicate *filterPredicate; // @synthesize filterPredicate=_filterPredicate;
@property(copy, nonatomic) MessageSortOrder *secondarySortOrder; // @synthesize secondarySortOrder=_secondarySortOrder;
@property(copy, nonatomic) MessageSortOrder *primarySortOrder; // @synthesize primarySortOrder=_primarySortOrder;
@property(nonatomic) BOOL threadMessages; // @synthesize threadMessages=_threadMessages;
- (void).cxx_destruct;	// IMP=0x00000001001f062b
- (id)copyWithZone:(struct _NSZone *)arg1;	// IMP=0x00000001001f050d

@end

