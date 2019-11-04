//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class MCMimePart, NSMutableData;

@interface _MCMimeHeaderScanContext : NSObject
{
    const char *_current;	// 8 = 0x8
    const char *_end;	// 16 = 0x10
    unsigned long long _encodingHint;	// 24 = 0x18
    NSMutableData *_dataBuf;	// 32 = 0x20
    MCMimePart *_mimePart;	// 40 = 0x28
}

@property(retain, nonatomic) MCMimePart *mimePart; // @synthesize mimePart=_mimePart;
@property(retain, nonatomic) NSMutableData *dataBuf; // @synthesize dataBuf=_dataBuf;
@property(nonatomic) unsigned long long encodingHint; // @synthesize encodingHint=_encodingHint;
@property(nonatomic) const char *end; // @synthesize end=_end;
@property(nonatomic) const char *current; // @synthesize current=_current;
- (void).cxx_destruct;	// IMP=0x0000000000072964
- (id)description;	// IMP=0x0000000000072762
- (id)debugDescription;	// IMP=0x0000000000072694

@end

