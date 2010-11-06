//
//  DUServiceUpdater.h
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DUUser;
@class DUHost;

extern NSString *authorMail;

@class DUUser;

@interface DUServiceUpdater : NSObject {
}

+ (void)registerServiceUpdater:(DUServiceUpdater *)theUpdater;
+ (NSDictionary *)serviceUpdaters;
+ (DUServiceUpdater *)getServiceUpdaterFor:(NSString *)theName;
+ (void)registerService;

- (NSString *)getServiceName;
- (void)updateUser:(DUUser *)theUser;
- (BOOL)needUpdate:(DUHost *)theHost;

@end
