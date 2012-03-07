/*
 MimePartResult.m
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

#import "MimePartResult.h"

@implementation MimePartResult

@synthesize decryptedMessageBody=decryptedMessageBody_;
@synthesize decryptedBody=decryptedBody_;
@synthesize decryptedData=decryptedData_;
@synthesize decryptedContent=decryptedContent_;
@synthesize isPGPSigned=isPGPSigned_;
@synthesize isPGPEncrypted=isPGPEncrypted_;
@synthesize isPGPDecrypted=isPGPDecrypted_;
@synthesize isPGPVerified=isPGPVerified_;
@synthesize isPGPPartlySigned=isPGPPartlySigned_;
@synthesize isPGPPartlyEncrypted=isPGPPartlyEncrypted_;
@synthesize pgpSignatures=pgpSignatures_;
@synthesize pgpError=pgpError_;

- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (void)dealloc {
    self.decryptedMessageBody = nil;
    self.decryptedBody = nil;
    self.decryptedData = nil;
    self.decryptedContent = nil;
    self.isPGPSigned = nil;
    self.isPGPEncrypted = nil;
    self.isPGPDecrypted = nil;
    self.isPGPPartlySigned = nil;
    self.isPGPPartlyEncrypted = nil;
    self.pgpSignatures = nil;
    self.pgpError = nil;
    [super dealloc];
}

@end
