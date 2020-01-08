//
//  GMDevice.m
//  GPGMail
//
//  Created by Lukas Pitschl on 23.10.19.
//

#import <Foundation/Foundation.h>

@interface GMDevice : NSObject

+ (instancetype)currentDeviceWithApplicationInfo:(NSDictionary *)applicationInfo;
- (instancetype)initWithApplicationInfo:(NSDictionary *)applicationInfo;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationWithMAC;

@property (nonatomic, copy) NSString *primaryMACAddress;
@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, copy) NSString *macOSVersion;
@property (nonatomic, copy) NSDictionary *GPGSuiteVersion;
@property (nonatomic, copy) NSDictionary *GPGMailVersion;
@property (nonatomic, copy) NSString *computerName;

@end
