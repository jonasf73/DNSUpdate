//
//  DULibraryManager.m
//  DNSUpdate2
//
//  Created by jalon on Sat Apr 07 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DULibraryManager.h"
#import "DUUser.h"

#include <sys/stat.h>

#define DULIBRARY @"Preferences/DNSUpdate"
#define USEREXTENSION @"duuser"
#define USERSPATH @"Users"
#define INTERFACEPATH @"Interfaces.plist"

NSDictionary *_filesAttributes=nil;
NSString *_duLibraryPath=nil;

@implementation NSDistributedNotificationCenter (DUAddition)

- (void)widePostNotification:(NSString *)notificationName {
    [self postNotificationName:notificationName object:nil userInfo:nil options:NSNotificationPostToAllSessions];
}

@end

@implementation DULibraryManager

+ (NSString *)libraryPath {
    NSFileManager *fm=[NSFileManager defaultManager];
    
    if(!_duLibraryPath) {
        NSString *libPath=[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                                NSLocalDomainMask,YES)
                                                                objectAtIndex:0];
        _duLibraryPath=[[libPath stringByAppendingPathComponent:DULIBRARY] retain];
        
        // FIX for a previous "bug"
        [fm changeFileAttributes:[DULibraryManager filesAttributes] atPath:_duLibraryPath];
        [fm changeFileAttributes:[DULibraryManager filesAttributes] atPath:[DULibraryManager usersPath]];

    }
    if(![fm fileExistsAtPath:_duLibraryPath]) {
        [fm createDirectoryAtPath:_duLibraryPath
            attributes:[DULibraryManager filesAttributes]];
        NSLog(@"Creating %@",_duLibraryPath);
    }
    
    return _duLibraryPath;
}

+ (NSDictionary *)filesAttributes {
    if(!_filesAttributes) {
        _filesAttributes=[[NSDictionary dictionaryWithObjectsAndKeys:
                            @"admin",NSFileGroupOwnerAccountName,
                            [NSNumber numberWithInt:S_IXUSR|S_IRUSR|S_IWUSR|S_IXGRP|S_IRGRP|S_IWGRP],NSFilePosixPermissions,
                            [NSNumber numberWithBool:YES],NSFileExtensionHidden,NULL]
                            retain];
    }
    return _filesAttributes;
}

+ (NSString *)usersPath {
    NSFileManager *fm=[NSFileManager defaultManager];
    NSString *userPath=[[DULibraryManager libraryPath] stringByAppendingPathComponent:USERSPATH];
    
    if(![fm fileExistsAtPath:userPath]) {
        [fm createDirectoryAtPath:userPath
            attributes:[DULibraryManager filesAttributes]];
        NSLog(@"Creating %@",userPath);
    }
    
    return userPath;
}

+ (NSString *)userExtension {
    return USEREXTENSION;
}

+ (NSDirectoryEnumerator *)usersEnumerator {
    return [[NSFileManager defaultManager] enumeratorAtPath:[DULibraryManager usersPath]];
}

+ (NSString *)fileNameForUser:(DUUser *)theUser {
    return [[DULibraryManager usersPath] stringByAppendingPathComponent:
                    [[theUser description] stringByAppendingPathExtension:[DULibraryManager userExtension]]];
}

+ (NSString *)fileNameForInterfaces {
    return [[DULibraryManager libraryPath] stringByAppendingPathComponent:INTERFACEPATH];
}

@end
