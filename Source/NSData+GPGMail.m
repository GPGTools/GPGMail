/* NSData+GPGMail.h created by Lukas Pitschl (@lukele) on Wed 24-Aug-2011 */

/*
 * Copyright (c) 2000-2011, GPGTools Project Team <gpgtools-devel@lists.gpgtools.org>
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

#define restrict
#import <RegexKit/RegexKit.h>
#import <Libmacgpg/Libmacgpg.h>
#import <NSString-NSStringUtils.h>
#import "NSData+GPGMail.h"

@implementation NSData (GPGMail)

- (NSString *)stringByGuessingEncodingWithHint:(NSStringEncoding)encoding {
    if([self length] == 0)
        return @"";
    
    // Attempt to convert with hint encoding.
    NSString *string = [NSString stringWithData:self encoding:encoding];
    if(![string length])
        return [self stringByGuessingEncoding];
    
    return string;
}

- (NSString *)stringByGuessingEncoding {
    NSString *retString;
    
	if ([self length] == 0) {
		return @"";
	}
	
    int items = 10;
    int encodings[10] = {NSUTF8StringEncoding, 
        NSISOLatin1StringEncoding, NSISOLatin2StringEncoding,
        NSWindowsCP1251StringEncoding, NSWindowsCP1252StringEncoding, NSWindowsCP1253StringEncoding,
        NSWindowsCP1254StringEncoding, NSWindowsCP1250StringEncoding, NSISO2022JPStringEncoding,
        NSASCIIStringEncoding};

    for(int i = 0; i < items; i++) {
        retString = [NSString stringWithData:self encoding:encodings[i]];
        if([retString length] > 0)
            return retString;
        
    }
    
    @throw [NSException exceptionWithName:@"GPGUnknownStringEncodingException" 
                                   reason:@"It was not possible to recognize the string encoding." userInfo:nil];
}

- (NSRange)rangeOfPGPInlineSignatures  {
    // Use the regular expression to ignore all signatures contained in a reply.
    NSString *signatureRegex = [NSString stringWithFormat:@"(?sm)(^%@\\r?\\n(.*)\\r?\n%@)", 
                                PGP_SIGNED_MESSAGE_BEGIN, PGP_MESSAGE_SIGNATURE_END];
    RKRegex *sigRKRegex = [RKRegex regexWithRegexString:signatureRegex options:RKCompileNoOptions];
    NSRange match = NSMakeRange(NSNotFound, 0);
    @try {
        match = [self rangeOfRegex:sigRKRegex];
    }
    @catch (NSException *exception) {
        // Ignore...
    }
    
    return match;
}

- (NSRange)rangeOfPGPSignatures  {
    NSString *signatureRegex = [NSString stringWithFormat:@"(?sm)(%@.*%@)", 
                                PGP_MESSAGE_SIGNATURE_BEGIN, PGP_MESSAGE_SIGNATURE_END];
    RKRegex *sigRKRegex = [RKRegex regexWithRegexString:signatureRegex options:RKCompileNoOptions];
    NSRange match = NSMakeRange(NSNotFound, 0);
    @try {
        match = [self rangeOfRegex:sigRKRegex];
    }
    @catch (NSException *exception) {
        // Ignore...
    }
    
    return match;
}

- (NSRange)rangeOfPGPInlineEncryptedData {
    // Use the regular expression to ignore all signatures contained in a reply.
    NSString *messageRegex = [NSString stringWithFormat:@"(?sm)(^%@\\r?\\n(.*)\\r?\\n%@)", 
                                PGP_MESSAGE_BEGIN, PGP_MESSAGE_END];
    RKRegex *sigRKRegex = [RKRegex regexWithRegexString:messageRegex options:RKCompileNoOptions];
    NSRange match = NSMakeRange(NSNotFound, 0);
    @try {
        match = [self rangeOfRegex:sigRKRegex];
    }
    @catch (NSException *exception) {
        // Ignore...
    }
    
    return match;
}

- (BOOL)mightContainPGPEncryptedDataOrSignatures {
    NSString *signatureRegex = [NSString stringWithFormat:@"(?sm)(-----BEGIN PGP (?<prefix>MESSAGE|SIGNATURE)-----"
                                ".*-----END PGP \\k<prefix>-----)"];
    RKRegex *sigRKRegex = [RKRegex regexWithRegexString:signatureRegex options:RKCompileNoOptions];
    BOOL isMatched = NO;
    @try {
        isMatched = [self isMatchedByRegex:sigRKRegex];
    }
    @catch (NSException *exception) {
        // Ignore...
    }
    
    return isMatched;
}

- (NSRange)rangeOfPGPPublicKey {
    NSString *signatureRegex = [NSString stringWithFormat:@"(?sm)(%@.*%@)", 
                                PGP_MESSAGE_PUBLIC_KEY_BEGIN, PGP_MESSAGE_PUBLIC_KEY_END];
    RKRegex *sigRKRegex = [RKRegex regexWithRegexString:signatureRegex options:RKCompileNoOptions];
    NSRange match = NSMakeRange(NSNotFound, 0);
    @try {
        match = [self rangeOfRegex:sigRKRegex];
    }
    @catch (NSException *exception) {
        // Ignore...
    }
    
    return match;
}

- (BOOL)containsPGPVersionMarker:(int)version {
    NSString *versionRegex = [NSString stringWithFormat:@"(?smi)(version[ ]?: %d)", version];
    RKRegex *versionRKRegex = [RKRegex regexWithRegexString:versionRegex options:RKCompileNoOptions];
    BOOL isMatched = NO;
    @try {
        isMatched = [self isMatchedByRegex:versionRKRegex];
    }
    @catch (NSException *exception) {
        // Ignore...
    }
    
    return isMatched;
}

- (BOOL)hasSignaturePacketsWithSignaturePacketsExpected:(BOOL)signaturePacketsExpected {
    NSData *packetData = [self copy];
    
    NSArray *packets = [GPGPacket packetsWithData:packetData];
    
    // Parsing packets failed due to unsupported packets.
    if(![packets count]) {
        [packetData release];
        return signaturePacketsExpected;
    }
    
    BOOL hasSignature = NO;
    
    for(GPGPacket *packet in packets) {
        if(packet.type == GPGSignaturePacket) {
            hasSignature = YES;
            break;
        }
    }
    [packetData release];
    
    return hasSignature;
}

@end
