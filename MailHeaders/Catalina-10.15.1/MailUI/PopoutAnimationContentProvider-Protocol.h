//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "NSObject-Protocol.h"

@class NSDictionary;

@protocol PopoutAnimationContentProvider <NSObject>
- (NSDictionary *)getContentGeometryData;
- (void)getSnapshotParts:(void (^)(NSDictionary *))arg1;
@end

