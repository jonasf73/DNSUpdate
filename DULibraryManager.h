//
//  DULibraryManager.h
//  DNSUpdate2
//
//  Created by jalon on Sat Apr 07 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDistributedNotificationCenter (DUAddition)

- (void)widePostNotification:(NSString *)notificationName;

@end

@class DUUser;

@interface DULibraryManager : NSObject {

}

+ (NSString *)libraryPath;
+ (NSDictionary *)filesAttributes;

+ (NSString *)usersPath;
+ (NSString *)userExtension;
+ (NSDirectoryEnumerator *)usersEnumerator;
+ (NSString *)fileNameForUser:(DUUser *)theUser;

+ (NSString *)fileNameForInterfaces;

@end
