//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@interface MCDateParser : NSObject
{
}

+ (id)_dateStringByStrippingCommentsFromString:(id)arg1;	// IMP=0x0000000000021adb
+ (id)_fallbackDateFormaters;	// IMP=0x0000000000086cbb
+ (id)_commonDateFormatters;	// IMP=0x0000000000021e4d
+ (id)_imapDateFormatter;	// IMP=0x0000000000021796
+ (id)_dateFromString:(id)arg1 imapFirst:(BOOL)arg2;	// IMP=0x00000000000210a6
+ (id)dateFromInternetMessageDateString:(id)arg1;	// IMP=0x0000000000021ac7
+ (id)dateFromIMAPDateString:(id)arg1;	// IMP=0x000000000002108f

@end

