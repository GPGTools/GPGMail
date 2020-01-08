//
//  GMMessageSecurityParseResult.h
//  GPGMail
//
//  Created by Lukas Pitschl on 01.10.16.
//
//

#import <Foundation/Foundation.h>

@class GMMessageProtectionStatus;

// TODO: Should probably be called security properties. 
@interface GMMessageSecurityFeatures : NSObject

+ (GMMessageSecurityFeatures *)securityFeaturesFromMimeBody:(GM_CAST_CLASS(MimePart *, id))mimeBody;
+ (GMMessageSecurityFeatures *)securityFeaturesFromTopLevelMimePart:(MCMimePart *)topLevelMimePart;
+ (GMMessageSecurityFeatures *)securityFeaturesFromMessageProtectionStatus:(GMMessageProtectionStatus *)messageProtectionStatus topLevelMimePart:(MCMimePart *)topLevelMimePart;

@property (assign) BOOL PGPInfoCollected;
@property (assign) BOOL PGPEncrypted;
@property (assign) BOOL PGPPartlyEncrypted;
@property (assign) BOOL PGPSigned;
@property (assign) BOOL PGPPartlySigned;
@property (assign) BOOL PGPDecrypted;
@property (assign) BOOL PGPVerified;
@property (retain) NSArray *PGPSignatures;
@property (retain, readonly) NSArray *PGPSignatureLabels;
@property (retain) NSArray *PGPErrors;
@property (assign) NSUInteger numberOfPGPAttachments;
@property (retain) NSArray *PGPAttachments;
@property (retain) NSError *PGPMainError;

@end
