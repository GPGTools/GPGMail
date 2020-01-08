/* MCMessageGenerator+GPGMail.m created by Lukas Pitschl (@lukele) on Sat 04-Oct-2014 */

/*
 * Copyright (c) 2000-2014, GPGTools Team <team@gpgtools.org>
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of GPGTools Team nor the names of GPGMail
 *       contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE GPGTools Team ``AS IS'' AND ANY
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

#import <objc/runtime.h>

#import "MCMessageGenerator+GPGMail.h"
#import "MCMessageGenerator.h"
#import "MCMimePart.h"
#import "NSObject+LPDynamicIvars.h"
#import "GPGConstants.h"
#import "GMComposeMessagePreferredSecurityProperties.h"

//#import "GPGKey.h"
#import "EAEmailAddressParser.h"
#import "MCMutableMessageHeaders.h"
#import "MCMutableMessageHeaders+GPGMail.h"
#import "MCActivityMonitor.h"

#import "MimePart+GPGMail.h"

#import "GPGMailBundle.h"

#define mailself ((MCMessageGenerator *)self)

@class GPGKey;

const static NSString *kMCMessageGeneratorSigningKeyKey = @"MCMessageGeneratorSigningKey";
NSString * const kMCMessageGeneratorSecurityMethodKey = @"kMCMessageGeneratorSecurityMethod";

@implementation MCMessageGenerator_GPGMail

- (id)MA_newDataForMimePart:(id)mimePart withPartData:(id)partData NS_RETURNS_RETAINED {
	// MailTags likes to duplicate the headers of the mime part for some reason.
	// It looks like it's easily detectable by checking for the header and body separator \n\n.
	// If we find two header separators and the two headers look exactly the same,
	// we can assume that a duplicate header was added and will remove the first one.
	//
	// It's crucial that the first two part headers are identical, otherwise we're simply dealing
	// with a normal multipart message and would remove too many headers and thus mangle the original
	// message.
	
	NSData *newData = [self MA_newDataForMimePart:mimePart withPartData:partData];
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return newData;
    }
	// If MailTags is not installed, let's get out of here.
	if(NSClassFromString(@"MailTagsBundle") == nil)
		return newData;
	// The bug has only been seen in combinations with encryted drafts yet, so in any other case,
	// we'll just call into the original method and return the result.
	// TODO: Figure out what replaces encryptsOutput and uncomment following line.
//    if([mimePart parentPart] || ![[self getIvar:@"IsDraft"] boolValue] || !(BOOL)[(GM_CAST_CLASS(MCMessageGenerator *, id))self encryptsOutput])
//		return newData;
	
	[self removeIvar:@"IsDraft"];
	
	NSData *NL = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
	
	NSUInteger messageSeparatorsFound = 0;
	NSData *firstHeader, *secondHeader = nil;
	NSRange firstHeaderEndRange = [newData rangeOfData:NL options:0 range:NSMakeRange(0, [newData length])];
	// One header separator is found. Expected, so on to the next check.
	if(firstHeaderEndRange.location != NSNotFound) {
		// The first header is found between location 0 and the first occurence of \n\n which is firstHeaderEndRange.location
		firstHeader = [newData subdataWithRange:NSMakeRange(0, firstHeaderEndRange.location)];
		messageSeparatorsFound++;
		NSRange secondHeaderEndRange = [newData rangeOfData:NL options:0 range:NSMakeRange(firstHeaderEndRange.location + firstHeaderEndRange.length, [newData length] - firstHeaderEndRange.location - firstHeaderEndRange.length)];
		// Oh oh, a second one has been found.
		if(secondHeaderEndRange.location != NSNotFound) {
			// The second header is found between firstHeaderEndRange.location + firstHeaderEndRange.length and spreads until secondHeaderEndRange.location.
			secondHeader = [newData subdataWithRange:NSMakeRange(firstHeaderEndRange.location + firstHeaderEndRange.length, secondHeaderEndRange.location - (firstHeaderEndRange.location + firstHeaderEndRange.length))];
			messageSeparatorsFound++;
		}
	}
	// Two header separators and the headers are equal? Let's only keep the data after the first one.
	if(messageSeparatorsFound > 1 && [firstHeader isEqualToData:secondHeader])
		newData = [newData subdataWithRange:NSMakeRange(firstHeaderEndRange.location + firstHeaderEndRange.length, [newData length] - firstHeaderEndRange.location - firstHeaderEndRange.length)];
	return newData;
}

- (void)MASetSigningIdentity:(id)identitiy {
    if(![identitiy isKindOfClass:[GPGKey class]]) {
        return [self MASetSigningIdentity:identitiy];
    }
    
    [self setIvar:kMCMessageGeneratorSigningKeyKey value:identitiy];
}

- (id)MA_newOutgoingMessageFromTopLevelMimePart:(MCMimePart *)topLevelPart topLevelHeaders:(MCMutableMessageHeaders *)topLevelHeaders withPartData:(NSMapTable *)partData {
    // This method is already used when a received message is also used
    // from +[Library_GPGMail GMLocalMessageDataForMessage:topLevelPart:error].
    // In that case `securityMethod` is not set on the writer and the native Mail
    // method can be called.
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial] || ![self ivarExists:kMCMessageGeneratorSecurityMethodKey]) {
        return [self MA_newOutgoingMessageFromTopLevelMimePart:topLevelPart topLevelHeaders:topLevelHeaders withPartData:partData];
    }
    if(!topLevelHeaders) {
        topLevelHeaders = [MCMutableMessageHeaders new];
    }
    GPGMAIL_SECURITY_METHOD securityMethod = (GPGMAIL_SECURITY_METHOD)[[self getIvar:kMCMessageGeneratorSecurityMethodKey] unsignedIntegerValue];
    NSMutableArray *encryptionCertificates = [mailself.encryptionCertificates count] != 0 ? [NSMutableArray new] : nil;
    // Remove the reply-to dummy keys.
    for(id key in mailself.encryptionCertificates) {
        if([key isKindOfClass:[GMComposeMessageReplyToDummyKey class]]) {
            continue;
        }
        [encryptionCertificates addObject:key];
    }
    mailself.encryptionCertificates = encryptionCertificates;

    if(securityMethod != GPGMAIL_SECURITY_METHOD_OPENPGP) {
        return [self MA_newOutgoingMessageFromTopLevelMimePart:topLevelPart topLevelHeaders:topLevelHeaders withPartData:partData];
    }

    id signingIdentity = [mailself getIvar:kMCMessageGeneratorSigningKeyKey];

    // Since the message is supposed to be protected using PGP, the first step is to sign it.
    MCActivityMonitor *activityMonitor = [MCActivityMonitor currentMonitor];
    if([activityMonitor shouldCancel]) {
        return nil;
    }
    
    MCMimePart *parentMimePart = topLevelPart;
    if(signingIdentity) {
        NSString *senderAddress = [EAEmailAddressParser rawAddressFromFullAddress:[topLevelHeaders firstAddressForKey:@"resent-from"]];
        if(!senderAddress) {
            senderAddress = [EAEmailAddressParser rawAddressFromFullAddress:[topLevelHeaders firstAddressForKey:@"from"]];
        }
        
        NSMutableData *newData = [mailself _newDataForMimePart:topLevelPart withPartData:partData];
        if(!newData || [activityMonitor shouldCancel]) {
            return nil;
        }
        
        NSData *signatureData = nil;
        MCMimePart *multipartSignedMimePart = [(MimePart_GPGMail *)topLevelPart newSignedPartWithData:newData sender:senderAddress signingKey:signingIdentity signatureData:&signatureData];
        MCMimePart *signaturePart = [[multipartSignedMimePart firstChildPart] nextSiblingPart];
        if(!multipartSignedMimePart || !signatureData || !signaturePart) {
            return nil;
        }
        [partData setObject:signatureData forKey:signaturePart];
        parentMimePart = multipartSignedMimePart;
    }
    
    if(encryptionCertificates && [encryptionCertificates count]) {
        NSMutableData *newData = [mailself _newDataForMimePart:parentMimePart withPartData:partData];
        if(!newData || [activityMonitor shouldCancel]) {
            return nil;
        }
        [topLevelHeaders appendHeaderData:nil recipients:[NSMutableArray new]];
        NSMapTable *encryptedPartData = nil;
        MCMimePart *multipartEncryptedMimePart = [(MimePart_GPGMail *)parentMimePart newEncryptedPartWithData:newData certificates:encryptionCertificates partData:&encryptedPartData];
        MCMimePart *encryptedDataMimePart = [[multipartEncryptedMimePart firstChildPart] nextSiblingPart];
        if(!multipartEncryptedMimePart || !encryptedDataMimePart || !encryptedPartData || ![encryptedPartData objectForKey:encryptedDataMimePart]) {
            return nil;
        }
        for(MCMimePart *mimePart in encryptedPartData) {
            [partData setObject:[encryptedPartData objectForKey:mimePart] forKey:mimePart];
        }
        parentMimePart = multipartEncryptedMimePart;
    }
    
    // Since the protection using PGP is already taken care of, Mail can be instructed to just take the information
    // as is and not run any cryptographic protection itself on the passed in mime parts and data.
    // In order to make sure of that, the `signingIdentity` and `encryptionCertificates` are niled out.
    
    // Since _signingIdentity is a struct, it's not possible to use setValue:forKey:
    [mailself setSigningIdentity:nil];
    mailself.encryptionCertificates = nil;
    
    // Last but not least, let Mail create the message.
    id outgoingMessage = [self MA_newOutgoingMessageFromTopLevelMimePart:parentMimePart topLevelHeaders:topLevelHeaders withPartData:partData];
    
    // In case of Mail-Act-On, this method is called a few times in order to create
    // temporary outgoing messages.
    // Since the encryption certificates were reset, in order to prevent Mail from encrypting
    // the message itself, they have to be re-added now, that the message has been created,
    // so it's possible for future calls of this method, to have the contents encrypted as well.
    [mailself setSigningIdentity:(__bridge struct __SecIdentity *)(signingIdentity)];
    mailself.encryptionCertificates = encryptionCertificates;
    
    return outgoingMessage;
    /*
    
    if(!topLevelHeaders) {
        topLevelHeaders = [MCMutableMessageHeaders new];
    }
    
    // Create a new empty outgoing message.
    MCOutgoingMessage *outgoingMessage = [mailself _newOutgoingMessage];
    MCMimeBody *mimeBody = [outgoingMessage mimeBody];
    NSMutableData *bodyData = [NSMutableData data];
    
    MCActivityMonitor *activityMonitor = [MCActivityMonitor currentMonitor];
    [outgoingMessage setMessageFlags:0x1 mask:0x386ffbfffdf];
    [outgoingMessage setMutableHeaders:topLevelHeaders];
    [outgoingMessage setRawData:bodyData];
    
    NSString *senderAddress = [EAEmailAddressParser rawAddressFromFullAddress:[topLevelHeaders firstAddressForKey:@"resent-from"]];
    if(!senderAddress) {
        [EAEmailAddressParser rawAddressFromFullAddress:[topLevelHeaders firstAddressForKey:@"from"]];
    }
    if(topLevelHeaders) {
        id signingIdentity = [self valueForKey:@"_signingIdentity"];
        if(signingIdentity) {
            NSMutableData *newData = [self _newDataForMimePart:topLevelPart withPartData:partData];
            if(newData && ![activityMonitor shouldCancel]) {
                NSData *signatureData = nil;
                MCMimePart *multipartSignedPart = [topLevelPart newSignedPartWithData:newData sender:senderAddress identity:signingIdentity signatureData:&signatureData];
                MCMimePart *signaturePart = [[multipartSignedPart firstChildPart] nextSiblingPart];
                if(multipartSignedPart && signatureData && signaturePart) {
                    [partData setObject:signatureData forKey:signaturePart];
                }
                else {
                    outgoingMessage = nil;
                }
            }
            else {
                outgoingMessage = nil;
            }
        }
    }
    
    if(!outgoingMessage) {
        // We could bail out early here. Makes the rest of the code more readable.
        return nil;
    }
     
    NSArray *encryptionCertificates = [self encryptionCertificates];
    if(encrpytionCertificates) {
        MCMimePart *parentMimePart = multipartSignedPart != nil ? multipartSignedPart : topLevelMimePart;
        NSMutableData newData = [self _newDataForMimePart:parentMimePart withPartData:partData];
        if(newData && ![activityMonitor shouldCancel]) {
            [self appendHeaderData:nil recipients:[NSMutableArray new]];
            NSData *encryptedData = nil;
            MCMimePart *multipartEncryptedPart = [parentMimePart _newEncryptedPartWithData:newData certificates:encryptionCertificates encryptedData:&encryptedData];
            if(multipartEncryptedPart && encryptedData) {
                [partData setObject:encryptedData forKey:multipartEncryptedPart];
            }
        }
    }
    if(topLevelHeaders && outgoingMessage) {
        
    }
    */
    /*
    if(!)
    
    
    void * -[MCMessageGenerator _newOutgoingMessageFromTopLevelMimePart:topLevelHeaders:withPartData:](void * self, void * _cmd, void * arg2, void * arg3, void * arg4) {
        rsi = _cmd;
        r15 = self;
        r12 = _objc_retain;
        var_48 = [arg2 retain];
        r13 = [arg3 retain];
        var_50 = [arg4 retain];
        if (r13 != 0x0) {
            rax = [r13 retain];
        }
        else {
            rax = [MCMutableMessageHeaders new];
        }
        r14 = rax;
        var_68 = r14;
        rbx = _objc_msgSend;
        var_70 = r15;
        r15 = [r15 _newOutgoingMessage];
        var_78 = r15;
        var_A0 = [[r15 mimeBody] retain];
        r12 = [[NSMutableData data] retain];
        var_90 = r12;
        var_60 = [[MCActivityMonitor currentMonitor] retain];
        rax = [r15 setMessageFlags:0x1 mask:0x386ffbfffdf];
        rax = [r15 setMutableHeaders:r14];
        rax = [r15 setRawData:r12];
        rdx = @"resent-from";
        r14 = @selector(firstAddressForKey:);
        rax = _objc_msgSend(r13, r14);
        rax = [rax retain];
        var_80 = rax;
        rcx = 0x0;
        rbx = r13;
        if (rax != 0x0) {
            rcx = [[EAEmailAddressParser rawAddressFromFullAddress:var_80] retain];
            if (rcx == 0x0) {
                var_58 = rcx;
                rdx = @"from";
                var_88 = 0x0;
                r12 = [_objc_msgSend(0x0, r14) retain];
                rbx = 0x0;
                if (r12 != 0x0) {
                    r14 = var_48;
                    rbx = [[EAEmailAddressParser rawAddressFromFullAddress:r12] retain];
                    r15 = 0x1;
                }
                else {
                    r14 = var_48;
                    r15 = 0x0;
                }
                r13 = [rbx retain];
                rax = [var_58 release];
                if (r15 != 0x0) {
                    rax = [rbx release];
                }
                rax = [r12 release];
                rcx = r13;
                rbx = var_88;
                var_48 = r14;
            }
        }
        else {
            var_58 = rcx;
            rdx = @"from";
            var_88 = 0x0;
            r12 = [_objc_msgSend(0x0, r14) retain];
            rbx = 0x0;
            if (r12 != 0x0) {
                r14 = var_48;
                rbx = [[EAEmailAddressParser rawAddressFromFullAddress:r12] retain];
                r15 = 0x1;
            }
            else {
                r14 = var_48;
                r15 = 0x0;
            }
            r13 = [rbx retain];
            rax = [var_58 release];
            if (r15 != 0x0) {
                rax = [rbx release];
            }
            rax = [r12 release];
            rcx = r13;
            rbx = var_88;
            var_48 = r14;
        }
        if (rbx != 0x0) {
            r14 = *_OBJC_IVAR_$_MCMessageGenerator._signingIdentity;
            r15 = var_70;
            if (*(r15 + r14) != 0x0) {
                var_88 = rbx;
                var_58 = rcx;
                r12 = [r15 _newDataForMimePart:var_48 withPartData:var_50];
                rdi = var_60;
                if ((r12 != 0x0) && ([rdi shouldCancel] == 0x0)) {
                    rbx = _objc_msgSend;
                    r14 = [var_48 newSignedPartWithData:r12 sender:var_58 identity:*(r15 + r14) signatureData:0x0];
                    var_98 = [0x0 retain];
                    r13 = [[r14 firstChildPart] retain];
                    rdi = r13;
                    r13 = [[r13 nextSiblingPart] retain];
                    rax = [rdi release];
                    if ((var_98 != 0x0) && (r13 != 0x0)) {
                        rax = [var_50 setObject:var_98 forKey:r13];
                    }
                    rax = [var_48 release];
                    if (r14 == 0x0) {
                        rax = [0x0 release];
                        var_78 = 0x0;
                    }
                    rbx = _objc_release;
                    rax = [r13 release];
                    rax = [var_98 release];
                    r13 = var_78;
                }
                else {
                    rax = [var_78 release];
                    r13 = 0x0;
                    r14 = var_48;
                }
                rax = [r12 release];
                var_48 = r14;
                rbx = var_88;
            }
            else {
                var_58 = rcx;
                r13 = var_78;
            }
        }
        else {
            var_58 = rcx;
            r13 = var_78;
            r15 = var_70;
        }
        rax = [r15 encryptionCertificates];
        rax = [rax retain];
        if (r13 != 0x0) {
            var_98 = rax;
            if (rax != 0x0) {
                r14 = rbx;
                r12 = [r15 _newDataForMimePart:var_48 withPartData:var_50];
                if ((r12 != 0x0) && ([var_60 shouldCancel] == 0x0)) {
                    var_78 = r13;
                    rbx = _objc_msgSend;
                    rax = [NSMutableArray new];
                    var_88 = rax;
                    rax = [var_68 appendHeaderData:0x0 recipients:rax];
                    rbx = [var_48 newEncryptedPartWithData:r12 certificates:var_98 encryptedData:0x0];
                    r13 = _objc_retain;
                    r13 = [0x0 retain];
                    rbx = [rbx retain];
                    rax = [var_48 release];
                    if ((rbx != 0x0) && (r13 != 0x0)) {
                        rax = [var_50 setObject:r13 forKey:rbx];
                    }
                    else {
                        rax = [0x0 release];
                        var_78 = 0x0;
                    }
                    r15 = _objc_release;
                    rax = [rbx release];
                    rax = [r13 release];
                    rax = [var_88 release];
                    var_48 = rbx;
                    r13 = var_78;
                    r15 = var_70;
                }
                else {
                    rax = [0x0 release];
                    r13 = 0x0;
                }
                rax = [r12 release];
                rbx = r14;
            }
        }
        else {
            var_98 = rax;
        }
        r14 = rbx;
        if ((rbx != 0x0) && (r13 != 0x0)) {
            r15 = @"message-id";
            rbx = _objc_msgSend;
            var_A8 = [[MCMessageGenerator domainHintForResentIDFromHeaders:r14 hasResentFromHeaders:0x0] retain];
            rbx = [[var_68 firstMessageIDForKey:@"message-id"] retain];
            rax = [rbx release];
            if (rbx == 0x0) {
                var_88 = r14;
                rbx = _objc_msgSend;
                r12 = [[NSString messageIDStringWithDomainHint:var_A8] retain];
                if ([r12 length] != 0x0) {
                    r14 = var_68;
                    if (0x0 != 0x0) {
                        rbx = _objc_msgSend;
                        rax = [r14 firstMessageIDForKey:@"message-id"];
                        rax = [rax retain];
                        rbx = [rax length];
                        rax = [rax release];
                        if (rbx != 0x0) {
                            rcx = @"resent-message-id";
                            rsi = @selector(setHeader:forKey:);
                            rdi = r14;
                            rdx = r12;
                        }
                        else {
                            rsi = @selector(setHeader:forKey:);
                            rdi = r14;
                            rdx = r12;
                            rcx = @"message-id";
                        }
                    }
                    else {
                        rsi = @selector(setHeader:forKey:);
                        rdi = r14;
                        rdx = r12;
                        rcx = @"message-id";
                    }
                    rax = _objc_msgSend(rdi, rsi);
                }
                rax = [r12 release];
                r14 = var_88;
            }
            rbx = [[r14 firstHeaderForKey:@"mime-version"] retain];
            rax = [rbx release];
            if (rbx == 0x0) {
                if (*__newOutgoingMessageFromTopLevelMimePart:topLevelHeaders:withPartData:.predicate != 0xffffffffffffffff) {
                    rax = dispatch_once(__newOutgoingMessageFromTopLevelMimePart:topLevelHeaders:withPartData:.predicate, ^ { } });
                }
                rax = [r14 setHeader:*__newOutgoingMessageFromTopLevelMimePart:topLevelHeaders:withPartData:.mimeVersion forKey:@"mime-version"];
            }
            rax = [var_A8 release];
            r13 = r15;
            r15 = var_70;
        }
        r12 = 0x0;
        if (r13 == 0x0) goto loc_4825e;
        
    loc_48221:
        if (([r15 _encodeDataForMimePart:var_48 withPartData:var_50] == 0x0) || ([var_60 shouldCancel] != 0x0)) goto loc_48252;
        
    loc_482be:
        var_78 = _objc_msgSend;
        r13 = _objc_msgSend;
        rax = [r15 _appendHeadersForMimePart:var_48 toHeaders:var_68];
        r12 = [[_objc_msgSend headers] retain];
        r15 = [[r12 encodedHeadersIncludingFromSpace:0x0] retain];
        rax = [r12 release];
        r12 = var_90;
        rax = [r12 appendData:r15];
        rcx = r12;
        if ([var_70 appendDataForMimePart:var_48 toData:rcx withPartData:var_50] == 0x0) goto loc_4847a;
        
    loc_48354:
        var_A8 = r15;
        var_88 = r14;
        rbx = @selector(length);
        r15 = r12;
        if (_objc_msgSend(r12, rbx) != 0x0) {
            r13 = _objc_msgSend;
            r14 = rbx;
            rbx = objc_retainAutorelease(r15);
            r12 = [rbx bytes];
            rdi = rbx;
            rbx = r14;
            if ((*(int8_t *)(r12 + _objc_msgSend(rdi, rbx) + 0xffffffffffffffff) & 0xff) != 0xa) {
                if ([var_70 allowsBinaryMimeParts] == 0x0) {
                    rcx = 0x1;
                    rax = [r15 appendBytes:"\n" length:rcx];
                }
            }
        }
        else {
            if ([var_70 allowsBinaryMimeParts] == 0x0) {
                rcx = 0x1;
                rax = [r15 appendBytes:"\n" length:rcx];
            }
        }
        r13 = _objc_msgSend;
        rax = [var_78 setRawData:_objc_release, rcx];
        r12 = _objc_msgSend(var_A8, rbx, _objc_release, rcx);
        rbx = _objc_msgSend(_objc_release, rbx, _objc_release, rcx) - r12;
        rbx = [[MCSubdata alloc] initWithParent:_objc_release range:r12, rbx];
        rax = [var_A0 setRawData:rbx, r12];
        r15 = _objc_release;
        rax = [rbx release];
        rax = [var_A8 release];
        r12 = var_78;
        r14 = var_88;
        
    loc_4825e:
        rbx = _objc_release;
        rax = [var_98 release];
        rax = [var_58 release];
        rax = [var_80 release];
        rax = [var_60 release];
        rax = [var_90 release];
        rax = [var_A0 release];
        rax = [var_68 release];
        rax = [var_50 release];
        rax = [r14 release];
        rax = [var_48 release];
        rax = r12;
        rbx = stack[2042];
        r12 = stack[2043];
        r13 = stack[2044];
        r14 = stack[2045];
        r15 = stack[2046];
        rsp = rsp + 0xb8;
        rbp = stack[2047];
        return rax;
        
    loc_4847a:
        rbx = _objc_release;
        rax = [var_78 release];
        rax = [r15 release];
        r12 = 0x0;
        
    loc_48252:
        rax = [r13 release];
    }
    
    
    
    
    
    
    
    

    id outgoingMessage = [self MA_newOutgoingMessageFromTopLevelMimePart:topLevelPart topLevelHeaders:topLevelHeaders withPartData:partData];
    
    return outgoingMessage;
*/
}

- (void)MA_appendHeadersForMimePart:(MCMimePart *)mimePart toHeaders:(MCMutableMessageHeaders *)headers {
    // Bug: #885 - rdar://XXXX
    // Mail breaks S/MIME and PGP/MIME signature when creating partial emlx files.
    //
    // Mail creates the partial message from the original message in
    // +[MFLibrary mimeMessageDataSnippingPartsData:mimePartBlock:].
    // It does so, by looping through all the mime parts, checking if the mime part
    // is an attachment, and if so, writing the attachment data to disk.
    // If the mime part is not an attachment, the body data of the mime part
    // is added to the partData NSMapTable.
    // After this procedure it creates a new message, using the MCMessageGenerator and
    // caling -[MCMessageGenerator appendDataForMimePart:toData:withPartData:].
    // -[MCMessageGenerator appendDataForMimePart:toData:withPartData:] builds a
    // new message based on the mime tree.
    // Within -[MCMessageGenerator appendDataForMimePart:toData:withPartData:] Mail calls
    // -[MCMessageGenerator _appendHeadersForMimePart:toHeaders:] to re-create the header data
    // for each mime part, instead of taking advantage of the already populated -[MimePart headerData]
    // property which is availabe in this specific case (when creating a partial message from the original message).
    // As a result the newly created headers might be in different in order or format
    // than on the original message, which invalidates the S/MIME or PGP/MIME signature.
    //
    // == Example ==
    //
    // > Content-Type: application/zip;
	// >     x-unix-mode=0644;
	// >     name="Untitled.txt.zip"
    //
    // Might be converted into:
    //
    // > Content-Type: application/zip;
    // >     name=Untitle.txt.zip;
    // >     x-unix-mode=0644
    //
    // The difference is subtle but enough to break any signature.
    //
    //
    // == Workaround ==
    // Upon calling -[MCMessageGenerator _appendHeadersForMimePart:toHeaders:] Mail invokes
    // -[MCMutableMessageHeaders encodedHeadersIncludingFromSpace:NO] to convert the MCMutableMessageHeaders
    // object in to the headers data that is appended to the message data for the current mime part.
    // GPGMail takes advantage of that fact, by storing the header data of the current mime part on
    // the MCMutableMessageHeaders object, and instead of returning the re-created MCMutableMessageHeaders
    // in -[MCMutableMessageHeaders encodedHeadersIncludingFromSpace:NO] it returns the headerData of the
    // current mime part which was previously stored on the MCMutableMessageHeaders object.
    //
    // == Improvements ==
    // The workaround could be further improved by checking the mime tree and only
    // using the original header data if a PGP/MIME tree is detected.
    NSData *headerData = [mimePart headerData];
    [(MCMutableMessageHeaders_GPGMail *)headers setGMHeaderData:headerData];

    return [self MA_appendHeadersForMimePart:mimePart toHeaders:headers];
}

@end
