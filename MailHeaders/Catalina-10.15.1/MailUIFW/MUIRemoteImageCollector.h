//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class NSMutableArray, NSOperationQueue;

@interface MUIRemoteImageCollector : NSObject
{
    NSMutableArray *_attachments;	// 8 = 0x8
    NSOperationQueue *_downloadQueue;	// 16 = 0x10
}

@property(readonly, nonatomic) NSOperationQueue *downloadQueue; // @synthesize downloadQueue=_downloadQueue;
- (void).cxx_destruct;	// IMP=0x000000000001dbba
- (id)init;	// IMP=0x000000000001dae1
- (id)initWithAttachments:(id)arg1;	// IMP=0x000000000001d730

@end

