//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPResponse.h>

@class NSSet;

@interface IMAPFlagsResponse : IMAPResponse
{
    NSSet *_flags;	// 8 = 0x8
}

+ (BOOL)handlesResponseWithName:(const char *)arg1 ofLength:(unsigned long long)arg2;	// IMP=0x000000000000788b
@property(copy, nonatomic) NSSet *flags; // @synthesize flags=_flags;
- (void).cxx_destruct;	// IMP=0x000000000000b2de
- (id)description;	// IMP=0x0000000000031546

@end

