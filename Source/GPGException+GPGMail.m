/*
 GPGException+GPGMail.h
 GPGMail
 
 Copyright (c) 2012 Chris Fraire. All rights reserved.
 
 GPGMail is free software: you can redistribute it and/or modify
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

#import "GPGException+GPGMail.h"

@implementation GPGException (GPGMail)

- (BOOL)isCorruptedInputError {
    switch (self.errorCode) {
        case GPGErrorUnknownPacket:
        case GPGErrorChecksumError:
        case GPGErrorInvalidPacket:
        case GPGErrorInvalidArmor:
            return TRUE;
        default:
            return FALSE;
    }
}

@end
