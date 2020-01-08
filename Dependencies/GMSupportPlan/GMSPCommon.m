/* GMSPCommon.m created by Lukas on Fri 2019-10-02 */

/*
 * Copyright (c) 2019, GPGTools Team <team@gpgtools.org>
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of GPGTools Project Team nor the names of GPGMail
 *       contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE GPGTools Project Team ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE GPGTools Project Team BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <CommonCrypto/CommonDigest.h>
#import "GMSPCommon.h"

@implementation NSString (GMSupportPlan)

- (NSString *)GMSP_SHA256 {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];

    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if(!CC_SHA256([data bytes], (CC_LONG)[data length], digest)) {
        return nil;
    }

    NSMutableString *sha = [NSMutableString new];
    for(unsigned int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [sha appendFormat:@"%02x", digest[i]];
    }

    return (NSString *)sha;
}

- (NSString *)GMSP_base64Encode {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

- (NSString *)GMSP_base64Decode {
    return [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:self options:0] encoding:NSUTF8StringEncoding];
}

@end

@implementation NSArray (GMSupportPlan)

- (NSString *)GMSP_hashBaseWithSeparator:(NSString *)separator {
    if(!separator) {
        separator = @"-";
    }

    NSMutableArray *base = [NSMutableArray new];
    NSArray *sortedArray = [self sortedArrayUsingComparator:^(id obj1, id obj2) {
        NSString *stringValue1 = obj1;
        if([obj1 isKindOfClass:[NSNumber class]]) {
            stringValue1 = [obj1 stringValue];
        }
        NSString *stringValue2 = obj2;
        if([obj2 isKindOfClass:[NSNumber class]]) {
            stringValue2 = [obj2 stringValue];
        }
        return [stringValue1 caseInsensitiveCompare:stringValue2];
    }];

    [sortedArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [base addObject:obj];
    }];

    return [base componentsJoinedByString:separator];
}

@end

@implementation NSDictionary (GMSupportPlan)

- (NSString *)GMSP_hashBaseWithSeparator:(NSString *)separator {
    if(!separator) {
        separator = @"-";
    }
    NSMutableArray *base = [NSMutableArray new];

    NSArray *sortedKeys = [[self allKeys] sortedArrayUsingComparator: ^(id obj1, id obj2) {
        return [obj1 caseInsensitiveCompare:obj2];
    }];

    [sortedKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [self objectForKey:obj];
        if([value isKindOfClass:[NSDictionary class]]) {
            [base addObject:[NSString stringWithFormat:@"%@|%@|", obj, [value GMSP_hashBaseWithSeparator:nil]]];
        }
        else if([value isKindOfClass:[NSArray class]]) {
            [base addObject:[NSString stringWithFormat:@"%@|%@|", obj, [value GMSP_hashBaseWithSeparator:@"+"]]];
        }
        else {
            [base addObject:[NSString stringWithFormat:@"%@+%@", obj, [self objectForKey:obj]]];
        }
    }];

    return [base componentsJoinedByString:@"-"];
}

@end
