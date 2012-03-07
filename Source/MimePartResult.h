/*
 MimePartResult.h
 GPGMail
 
 Copyright (c) 2012 Chris Fraire. All rights reserved.
 
 Libmacgpg is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>

@class MimeBody, MFError;

// in order to defer assigning to MimePart results until the last moment before 
// returning MADecodeWithContext, write to a custom object passed between
// routines
@interface MimePartResult : NSObject {
    MimeBody *decryptedMessageBody_;
    MimeBody *decryptedBody_;
    NSData *decryptedData_;
    NSString *decryptedContent_;
    NSNumber *isPGPSigned_;
    NSNumber *isPGPEncrypted_;
    NSNumber *isPGPDecrypted_;
    NSNumber *isPGPVerified_;
    NSNumber *isPGPPartlySigned_;
    NSNumber *isPGPPartlyEncrypted_;
    NSArray *pgpSignatures_;
    MFError *pgpError_;
}

@property (retain) MimeBody *decryptedMessageBody;
@property (retain) MimeBody *decryptedBody;
@property (retain) NSData *decryptedData;
@property (retain) NSString *decryptedContent;
@property (retain) NSNumber *isPGPSigned;
@property (retain) NSNumber *isPGPEncrypted;
@property (retain) NSNumber *isPGPDecrypted;
@property (retain) NSNumber *isPGPVerified;
@property (retain) NSNumber *isPGPPartlySigned;
@property (retain) NSNumber *isPGPPartlyEncrypted;
@property (retain) NSArray *pgpSignatures;
@property (retain) MFError *pgpError;

@end
