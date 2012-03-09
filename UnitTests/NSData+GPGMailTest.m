//
//  NSData+GPGMailTest.m
//  GPGMail
//
//  Created by Chris Fraire on 3/5/12.
//  Copyright (c) 2012 Chris Fraire. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "NSData+GPGMail.h"

@interface NSData_GPGMailTest : SenTestCase

- (NSData *)dataForResourceAtPath:(NSString *)path ofType:(NSString *)rtype;

@end

@implementation NSData_GPGMailTest

- (NSData *)dataForResourceAtPath:(NSString *)path ofType:(NSString *)rtype {
    NSBundle *execBundl = [NSBundle bundleForClass:[self class]];
    NSString *file = [execBundl pathForResource:path ofType:rtype];
    NSData *data = [NSData dataWithContentsOfFile:file];
    return data;
}

- (void)testMightContainPGPEncryptedDataOrSignatures_1 {
    NSData *data = [self dataForResourceAtPath:@"PGPMessageBlockGood" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    BOOL rc = [data mightContainPGPEncryptedDataOrSignatures];
    STAssertTrue(rc, @"Unexpected rc!");
}

- (void)testMightContainPGPEncryptedDataOrSignatures_2 {
    NSData *data = [self dataForResourceAtPath:@"PGPMessageBlockBad" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    BOOL rc = [data mightContainPGPEncryptedDataOrSignatures];
    STAssertFalse(rc, @"Unexpected rc!");
}

- (void)testMightContainPGPEncryptedDataOrSignatures_3 {
    NSData *data = [self dataForResourceAtPath:@"PGPMessageBlockGood2" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    BOOL rc = [data mightContainPGPEncryptedDataOrSignatures];
    STAssertTrue(rc, @"Unexpected rc!");
}

- (void)testMightContainPGPEncryptedDataOrSignatures_4 {
    NSData *data = [self dataForResourceAtPath:@"PGPSignatureBlockGood" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    BOOL rc = [data mightContainPGPEncryptedDataOrSignatures];
    STAssertTrue(rc, @"Unexpected rc!");
}

- (void)testMightContainPGPEncryptedDataOrSignatures_5 {
    NSData *data = [self dataForResourceAtPath:@"PGPSignatureBlockBad" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    BOOL rc = [data mightContainPGPEncryptedDataOrSignatures];
    STAssertFalse(rc, @"Unexpected rc!");
}

- (void)testRangeOfPGPPublicKey {
    NSData *data = [self dataForResourceAtPath:@"PGPPublicKey" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPPublicKey];
    STAssertEquals(21ul, match.location, @"Did not match public key!");
    STAssertEquals(72ul, match.length, @"Did not match public key!");
}

- (void)testRangeOfPGPInlineSignaturesUTF8Good {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineSignatureUTF8Good" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineSignatures];
    STAssertTrue(match.location != NSNotFound, @"Did not find signature as expected!");

    NSData *signature = [data subdataWithRange:match];
    // This first does a UTF8 guess, so it's good
    NSString *decoded = [[NSString alloc] initWithData:signature encoding:NSUTF8StringEncoding];
    // existing implementation should pass, but was broken before RegexKit
    STAssertTrue([decoded hasPrefix:PGP_SIGNED_MESSAGE_BEGIN], decoded);
    STAssertTrue([decoded hasSuffix:PGP_MESSAGE_SIGNATURE_END], decoded);
    [decoded release];
}

- (void)testRangeOfPGPInlineSignaturesASCIIGood {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineSignatureASCIIGood" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineSignatures];
    STAssertTrue(match.location != NSNotFound, @"Did not find signature as expected!");
    
    NSData *signature = [data subdataWithRange:match];
    NSString *decoded = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
    STAssertTrue([decoded hasPrefix:PGP_SIGNED_MESSAGE_BEGIN], decoded);
    STAssertTrue([decoded hasSuffix:PGP_MESSAGE_SIGNATURE_END], decoded);
    [decoded release];
}

- (void)testRangeOfPGPInlineSignaturesUTF8quoted {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineSignatureUTF8quoted" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineSignatures];
    STAssertTrue(match.location == NSNotFound, @"Found unexpected signature!");
}

- (void)testRangeOfPGPInlineSignaturesASCIIquoted {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineSignatureASCIIquoted" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineSignatures];
    STAssertTrue(match.location == NSNotFound, @"Found unexpected signature!");
}

- (void)testRangeOfPGPSignaturesUTF8Good {
    NSData *data = [self dataForResourceAtPath:@"PGPSignatureUTF8Good" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPSignatures];
    STAssertTrue(match.location != NSNotFound, @"Did not find signature as expected!");
    
    NSData *signature = [data subdataWithRange:match];
    NSString *decoded = [[NSString alloc] initWithData:signature encoding:NSUTF8StringEncoding];
    // existing implementation should pass, but was broken before RegexKit
    STAssertTrue([decoded hasPrefix:PGP_MESSAGE_SIGNATURE_BEGIN], decoded);
    STAssertTrue([decoded hasSuffix:PGP_MESSAGE_SIGNATURE_END], decoded);
    [decoded release];
}

- (void)testRangeOfPGPSignaturesASCIIGood {
    NSData *data = [self dataForResourceAtPath:@"PGPSignatureASCIIGood" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPSignatures];
    STAssertTrue(match.location != NSNotFound, @"Did not find signature as expected!");
    
    NSData *signature = [data subdataWithRange:match];
    NSString *decoded = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
    STAssertTrue([decoded hasPrefix:PGP_MESSAGE_SIGNATURE_BEGIN], decoded);
    STAssertTrue([decoded hasSuffix:PGP_MESSAGE_SIGNATURE_END], decoded);
    [decoded release];
}

- (void)testRangeOfPGPInlineEncryptedDataUTF8Good {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineDataUTF8Good" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineEncryptedData];
    STAssertTrue(match.location != NSNotFound, @"Did not find data as expected!");
    
    NSData *pgpBlock = [data subdataWithRange:match];
    NSString *decoded = [[NSString alloc] initWithData:pgpBlock encoding:NSUTF8StringEncoding];
    // existing implementation should pass, but was broken before RegexKit
    STAssertTrue([decoded hasPrefix:PGP_MESSAGE_BEGIN], decoded);
    STAssertTrue([decoded hasSuffix:PGP_MESSAGE_END], decoded);
}

- (void)testRangeOfPGPInlineEncryptedDataASCIIGood {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineDataASCIIGood" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineEncryptedData];
    STAssertTrue(match.location != NSNotFound, @"Did not find data as expected!");
    
    NSData *pgpBlock = [data subdataWithRange:match];
    NSString *decoded = [[NSString alloc] initWithData:pgpBlock encoding:NSASCIIStringEncoding];
    // existing implementation should pass, but was broken before RegexKit
    STAssertTrue([decoded hasPrefix:PGP_MESSAGE_BEGIN], decoded);
    STAssertTrue([decoded hasSuffix:PGP_MESSAGE_END], decoded);
}

- (void)testRangeOfPGPInlineEncryptedDataUTF8quoted {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineDataUTF8quoted" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineEncryptedData];
    STAssertTrue(match.location == NSNotFound, @"Found unexpected data!");
}

- (void)testRangeOfPGPInlineEncryptedDataASCIIquoted {
    NSData *data = [self dataForResourceAtPath:@"PGPInlineDataASCIIquoted" ofType:@"txt"];
    STAssertNotNil(data, @"Did not read Resource!");
    NSRange match = [data rangeOfPGPInlineEncryptedData];
    STAssertTrue(match.location == NSNotFound, @"Found unexpected data!");
}

- (void)testPGPVersionMarker {
    NSString *case1 = @"éúêø version: 1 Å";
    NSData *encoded = [case1 dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:FALSE];
    STAssertNotNil(encoded, @"Failed to UTF8 encode!");
    STAssertTrue([encoded containsPGPVersionMarker:1], @"version match failed!");
    STAssertFalse([encoded containsPGPVersionMarker:2], @"version match passed unexpectedly!");

    case1 = @"éúêø VERSION : 1 Å";
    encoded = [case1 dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:TRUE];
    STAssertNotNil(encoded, @"Failed to ASCII-lossy encode!");
    STAssertTrue([encoded containsPGPVersionMarker:1], @"version match failed!");
    STAssertFalse([encoded containsPGPVersionMarker:2], @"version match passed unexpectedly!");
}

@end
