/* NSAttributedString+GPGMail.h created by Lukas Pitschl (@lukele) on Wed 03-Aug-2011 */

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

@interface NSAttributedString (GPGMail)

/**
 Creates an icon just like the S/MIME sign icon, which performs an action
 on click. Based on the given link a different action is performed.
 
 It's not possible to use the SignedTextAttachment which is used by mail for the
 signed icon, because it calls a hard coded method, which can't be changed. Instead
 this behaviour is emulated using an NSAttachment with a GPGTextAttachmentCell and
 the NSAttributedString link attribute.
 
 A click on the icon calls the method - (BOOL)textView:clickedOnLink:atIndex: on the delegate
 of the view displaying the attributed string. 
 */
+ (NSAttributedString *)attributedStringWithAttachment:(NSTextAttachment *)attachment image:(NSImage *)image link:(NSString *)link offset:(float)offset;

/**
 Returns an autoreleased attributed string based on a given string.
 */
+ (NSAttributedString *)attributedStringWithString:(NSString *)string;

// Only < macOS 10.15
+ (id)headerAttributes;

@end
