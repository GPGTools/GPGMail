//
//  GMDevice.m
//  GPGMail
//
//  Created by Lukas Pitschl on 23.10.19.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>

#import "GMSPCommon.h"
#import "GMDevice.h"


#ifdef DEBUG
NSString * const kGMDeviceSalt = @"UX5XSWtSRTk2VT8wai9wKGx3ey8pMD5uczx8WCU8XWJ8KS84RHZVUysrLXU7Li1hUS0lflt7e1pTUExWTTYqIg==";
#else
#ifdef GMDEVICE_SALT
NSString * const kGMDeviceSalt = GMSPStringFromPreprocessor(GMDEVICE_SALT);
#else
#ifdef NO_SUPPORT_PLAN
NSString * const kGMDeviceSalt = @"";
#else
#error GMDEVICE_SALT is not defined in Release build!
#endif
#endif
#endif

@interface GMDevice ()

@property (nonatomic, copy) NSDictionary *applicationInfo;

@end

@implementation GMDevice

+ (instancetype)currentDeviceWithApplicationInfo:(NSDictionary *)applicationInfo {
    return [[self alloc] initWithApplicationInfo:applicationInfo];
}

- (instancetype)initWithApplicationInfo:(NSDictionary *)applicationInfo {
    if((self = [super init])) {
        _applicationInfo = [applicationInfo copy];
    }

    return self;
}

- (NSString *)deviceID {
    if(!_deviceID) {
        io_registry_entry_t entry = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
        CFStringRef uuid = IORegistryEntryCreateCFProperty(entry, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
        IOObjectRelease(entry);

        _deviceID = [self anonymizedValue:CFBridgingRelease(uuid)];
    }

    return _deviceID;
}

- (NSString *)computerName {
    if(!_computerName) {
        _computerName = [[NSHost currentHost] localizedName];
    }
    return _computerName;
}

- (NSString *)primaryMACAddress {
#ifdef DEBUG
    _primaryMACAddress = [[[NSUserDefaults standardUserDefaults] valueForKey:@"GPGMailSimulateDeviceID"] copy];
    if([_primaryMACAddress length] != 0) {
        return _primaryMACAddress;
    }
#endif
    if(!_primaryMACAddress) {
        CFMutableDictionaryRef serviceMatching = IOServiceMatching(kIOEthernetInterfaceClass);
        CFMutableDictionaryRef matchingProperties = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

        CFDictionarySetValue(matchingProperties, CFSTR(kIOPrimaryInterface), kCFBooleanTrue);
        CFDictionarySetValue(serviceMatching, CFSTR(kIOPropertyMatchKey), matchingProperties);
        CFRelease(matchingProperties);

        NSString *MACAddressString;

        io_iterator_t iterator;
        if(IOServiceGetMatchingServices(kIOMasterPortDefault, serviceMatching, &iterator) != KERN_SUCCESS) {
            return @"";
        }
        io_object_t service;
        while((service = IOIteratorNext(iterator)) != 0) {
            io_object_t parent;
            if(IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent) != KERN_SUCCESS) {
                continue;
            }

            CFTypeRef MACAddress = IORegistryEntryCreateCFProperty(parent, CFSTR(kIOMACAddress), kCFAllocatorDefault, 0);
            CFShow(MACAddress);
            unsigned char MAC[6];
            CFDataGetBytes(MACAddress, CFRangeMake(0, kIOEthernetAddressSize), MAC);
            MACAddressString = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
                                MAC[0], MAC[1], MAC[2], MAC[3], MAC[4], MAC[5]];
            CFRelease(MACAddress);
            IOObjectRelease(parent);
        }

        _primaryMACAddress = MACAddressString;
    }

    return _primaryMACAddress;
}

- (NSString *)macOSVersion {
    if(![_macOSVersion length]) {
        _macOSVersion = [[[NSProcessInfo processInfo] operatingSystemVersionString] copy];
    }

    return _macOSVersion;
}

- (NSDictionary *)GPGSuiteVersion {
    if(!_GPGSuiteVersion) {
        NSString *versionPath = @"/Library/Application Support/GPGTools/version.plist";
        NSDictionary *version = [NSDictionary dictionaryWithContentsOfFile:versionPath];

        _GPGSuiteVersion = @{@"build": version[@"BuildNumber"], @"version": version[@"CFBundleShortVersionString"], @"commit": version[@"CommitHash"]};
    }
    return _GPGSuiteVersion;
}

- (NSDictionary *)GPGMailVersion {
    if(!_GPGMailVersion) {
        _GPGMailVersion = @{@"build": _applicationInfo[@"CFBundleVersion"], @"version": _applicationInfo[@"CFBundleShortVersionString"], @"commit": _applicationInfo[@"CommitHash"]};
    }
    return _GPGMailVersion;
}

- (NSString *)appName {
    return _applicationInfo[@"CFBundleIdentifier"];
}

- (NSString *)anonymizedValue:(NSString *)value {
    return [[value stringByAppendingString:[kGMDeviceSalt GMSP_base64Decode]] GMSP_SHA256];
}

- (NSDictionary *)dictionaryRepresentationWithMAC {
    NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithDictionary:[self dictionaryRepresentation]];
    info[@"mac"] = [[self primaryMACAddress] GMSP_base64Encode];

    return info;
}


- (NSDictionary *)dictionaryRepresentation {
    NSDictionary *info = @{
                           @"gpgsuite": [[self stringForVersionDict:[self GPGSuiteVersion]] GMSP_base64Encode],
                           @"macos": [[self macOSVersion] GMSP_base64Encode],
                           @"gpgmail": [[self stringForVersionDict:[self GPGMailVersion]] GMSP_base64Encode],
                           @"udid": [[self deviceID] GMSP_base64Encode],
                           @"name": [[self computerName] GMSP_base64Encode],
                           @"app": [[self appName] GMSP_base64Encode],
                           @"app_s": [self anonymizedValue:[self appName]]
                           };

    return info;
}

- (NSString *)stringForVersionDict:(NSDictionary *)versionDictionary {
    NSString *version = [NSString stringWithFormat:@"%@:%@", versionDictionary[@"version"], versionDictionary[@"build"]];
    if(versionDictionary[@"commit"]) {
        version = [version stringByAppendingFormat:@":%@", versionDictionary[@"commit"]];
    }

    return version;
}

@end
