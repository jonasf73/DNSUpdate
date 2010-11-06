/*
 *  DUProtocols.h
 *  DNSUpdate2
 *
 *  Created by jalon on Sun Apr 08 2001.
 *  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@class DUUser;
@class DUServiceUpdater;
@class DUHost;
@class DUInterface;

#define DNSUPDATE @"DNSUPDATE Connexion"
#define KEYFILE @"/var/run/DNSUpdate_key"

@class DUUser;
@class DUServiceUpdater;

@protocol DUProxy <NSObject>

- (NSDictionary *)users;
- (oneway void)saveUsers;
- (DUUser *)addUserWithName:(NSString *)theName andPassword:(NSString *)thePassword andService:(DUServiceUpdater *)theService;
- (DUHost *)newHostWithName:(NSString *)theName andInterface:(DUInterface *)interface forUser:(DUUser *)user;
- (oneway void)removeHost:(DUHost *)host;

- (NSDictionary *)interfaces;

- (BOOL)isPaused;
- (oneway void)pause;
- (oneway void)daemonStart;
- (oneway void)quitDaemon;

- (NSDictionary *)services;

- (BOOL)registerAsApplication:idObject;

- (int)startOption;
- (oneway void)setStartOption:(int)theOption;

@end

@protocol DUGuardian

- (id <DUProxy>)getProxyWithKey:(NSString *)theKey;

@end

@protocol DUIdentify

- (BOOL)isUser;

@end

@protocol DUDaemonDelegate

- (void)setConnection:(NSConnection *)theConnection;

@end