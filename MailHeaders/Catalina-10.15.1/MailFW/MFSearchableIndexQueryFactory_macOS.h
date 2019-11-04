//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class NSString;

@interface MFSearchableIndexQueryFactory_macOS : NSObject
{
    BOOL _searchableIndexEnabled;	// 8 = 0x8
    NSString *_emailContentType;	// 16 = 0x10
    NSString *_attachmentFormatString;	// 24 = 0x18
}

+ (id)lowestPriorityMessageExpression;	// IMP=0x00000000001fdedd
+ (id)highestPriorityMessageExpression;	// IMP=0x00000000001fdec6
+ (id)expressionForMessagePriority:(long long)arg1;	// IMP=0x00000000001fde4f
+ (id)mailboxScopedExpressionWithExpression:(id)arg1 mailboxURLStrings:(id)arg2;	// IMP=0x00000000001fdded
+ (id)accountScopedExpressionWithExpression:(id)arg1 accountIdentifiers:(id)arg2;	// IMP=0x00000000001fdd8b
+ (id)_scopedExpressionWithExpression:(id)arg1 identifiers:(id)arg2 attribute:(id)arg3;	// IMP=0x00000000001fdb1e
+ (id)defaultFactory;	// IMP=0x00000000001fd95c
@property(readonly, nonatomic, getter=isSearchableIndexEnabled) BOOL searchableIndexEnabled; // @synthesize searchableIndexEnabled=_searchableIndexEnabled;
@property(readonly, nonatomic) NSString *attachmentFormatString; // @synthesize attachmentFormatString=_attachmentFormatString;
@property(readonly, nonatomic) NSString *emailContentType; // @synthesize emailContentType=_emailContentType;
- (void).cxx_destruct;	// IMP=0x00000000001fe315
- (id)expressionForQueryString:(id)arg1 includeAttachmentCriterion:(BOOL)arg2;	// IMP=0x00000000001fe1fc
- (id)queryStringForAllMailboxesWithQueryString:(id)arg1 excludedMailboxesQueryString:(id)arg2 forUnreadCount:(BOOL)arg3 includeAttachmentCriterion:(BOOL)arg4;	// IMP=0x00000000001fdfec
- (id)expressionForAllMailboxesWithExpression:(id)arg1 excludedMailboxesExpression:(id)arg2 forUnreadCount:(BOOL)arg3 includeAttachmentCriterion:(BOOL)arg4;	// IMP=0x00000000001fdef4
- (id)initWithSearchableIndexEnabled:(BOOL)arg1;	// IMP=0x00000000001fda17

@end

