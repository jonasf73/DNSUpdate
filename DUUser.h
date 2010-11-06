//
//  DUUser.h
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 01 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUProtocols.h"

@class DUHost;
@class DUServiceUpdater;

extern NSString *DUUserOk;
extern NSString *DUUserBadAuth;

#define MAX_TRIES 3

@class DUServiceUpdater;

@interface DUUser : NSObject <DUIdentify> {
    BOOL active;
    NSString *name;
    NSString *password;
    DUServiceUpdater *service;
    NSString *userStatus;
    NSMutableArray *hosts;
    BOOL dirty;
    BOOL isUpdating;
    unsigned char tries;
}

+ (NSDictionary *)users;
+ (DUUser *)addUserWithName:(NSString *)theName andPassword:(NSString *)thePassword andService:(DUServiceUpdater *)theService;

- (void)setName:(NSString *)theName;
- (NSString *)getName;
- (void)setPassword:(NSString *)thePassword;
- (NSString *)getPassword;
- (void)setActive:(BOOL)flag;
- (BOOL)isActive;
- (NSString *)getUserStatus;
- (void)setUserStatus:(NSString *)theStatus;
- (DUServiceUpdater *)getService;
- (void)setService:(DUServiceUpdater *)theService;

- (void)addHost:(DUHost *)theHost;
- (void)removeHost:(DUHost *)theHost;
- (NSArray *)hosts;
//- (DUHost *)hostWithName:(NSString *)theName;

- (BOOL)isDirty;
- (void)setDirty:(BOOL)flag;

- (BOOL)isUpdating;
- (void)setUpdating:(BOOL)flag;

- (unsigned char)tries;
- (void)addATry;
- (void)resetTries;

- (void)update;
+ (void)update;
+ (void)updating;
- (void)saveUser;
+ (void)saveUsers;
+ (void)loadUsers;
- (void)removeUser;

@end
