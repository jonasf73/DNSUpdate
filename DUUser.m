//
//  DUUser.m
//  DNSUpdate2
//
//  Created by jalon on Sun Apr 01 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import "DUUser.h"
#import "DUInterface.h"
#import "DUServiceUpdater.h"
#import "DUHost.h"
#import "DULibraryManager.h"
#import "DUCommon.h"
#import "DULibraryManager.h"

NSMutableDictionary *_users=nil;
BOOL duNeedNotification=NO;
BOOL duUpdating=NO;

@implementation DUUser

+ (void)initialize {
    [DUUser users];
}

+ (NSDictionary *)users {
    if(_users==nil) {
        _users=[[NSMutableDictionary alloc] initWithCapacity:1];
    }
    return _users;
}

+ (DUUser *)addUserWithName:(NSString *)theName andPassword:(NSString *)thePassword andService:(DUServiceUpdater *)theService {
    NSString *userRef=[NSString stringWithFormat:@"%@@%@",theName,[theService getServiceName]];
    DUUser *newUser;
    
    [DUUser users];
    if([_users objectForKey:userRef]) {
        NSLog(@"user %@ already in use",userRef);
        return nil;
    }
    
    newUser=[[[DUUser alloc] init] autorelease];
    [newUser setName:theName];
    [newUser setPassword:thePassword];
    [newUser setService:theService];
    [_users setObject:newUser forKey:userRef];
    NSLog(@"Registering user %@",userRef);
    return newUser;
}

- init {
    [super init];
    active=NO;
    userStatus=@"Not tested";
    hosts=[[NSMutableArray alloc] initWithCapacity:1];
    dirty=YES;
    isUpdating=NO;
    tries=0;
    return self;
}

- (BOOL)isUser {
    return YES;
}

- (void)setName:(NSString *)theName {
    [name release];
    name=[theName copy];
}

- (NSString *)getName {
    return name;
}

- (void)setPassword:(NSString *)thePassword {
    if(![password isEqualToString:thePassword]) {
        dirty=YES;
    }
    [password release];
    password=[thePassword copy];
}

- (NSString *)getPassword {
    return password;
}

- (NSString *)getUserStatus {
    return userStatus;
}

- (void)setUserStatus:(NSString *)theStatus {
    if(![userStatus isEqualToString:theStatus]) {
        [userStatus release];
        userStatus=[theStatus copy];
        dirty=YES;
    }
}

- (void)setActive:(BOOL)flag {
    if(active!=flag) {
        dirty=YES;
    }
    active=flag;
}

- (BOOL)isActive {
    return active;
}

- (DUServiceUpdater *)getService {
    return service;
}

- (void)setService:(DUServiceUpdater *)theService {
    service=theService;
}

- description {
    return [NSString stringWithFormat:@"%@@%@",[self getName],[service getServiceName]];
}

- (void)addHost:(DUHost *)theHost {
    [hosts addObject:theHost];
    [theHost setUser:self];
    NSLog(@"Registering host %@ for user %@",theHost,self);
    dirty=YES;
}

- (void)removeHost:(DUHost *)theHost {
    NSLog(@"Removing host %@ for user %@",theHost,self);
    [hosts removeObject:theHost];
    dirty=YES;
}

- (NSArray *)hosts {
    return hosts;
}

- (BOOL)isDirty {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSEnumerator *hostEnumerator=[hosts objectEnumerator];
    DUHost *theHost;
    BOOL totalDirty=dirty;
    
    while(theHost=[hostEnumerator nextObject]) {
        totalDirty=totalDirty||[theHost isDirty];
    }
    
    [pool release];
    return totalDirty;
}

- (void)setDirty:(BOOL)flag {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSEnumerator *hostEnumerator=[hosts objectEnumerator];
    DUHost *theHost;
    
    dirty=flag;
    while(theHost=[hostEnumerator nextObject]) {
        [theHost setDirty:flag];
    }
    
    [pool release];
}

- (BOOL)isUpdating {
    return isUpdating;
}

- (void)setUpdating:(BOOL)flag {
    isUpdating=flag;
}

- (unsigned char)tries {
    return tries;
}

- (void)addATry {
    tries++;
}

- (void)resetTries {
    tries=0;
}

- (void)update {
    if(active) {
        [service updateUser:self];
    }
}

+ (void)update {
    duUpdating=NO;
    [DUInterface resetCachedAddresses];
    [[_users allValues] makeObjectsPerformSelector:@selector(update)];
    if(duUpdating||[DUInterface mustNotifyObservers]) {
        NSLog(@"Notifying observers...");
        [[NSDistributedNotificationCenter defaultCenter] widePostNotification:DUDataUpdated];
    }
    [DUInterface resetMustNotifyObservers];
}

+ (void)updating {
    if(!duUpdating) {
        duUpdating=YES;
        [[NSDistributedNotificationCenter defaultCenter] widePostNotification:DUUpdating];
    }
}

- (void)saveUser {
    NSString *fileName=[DULibraryManager fileNameForUser:self];
    
    if([self isDirty]) {
        NSDictionary *userDict;
        NSMutableArray *readableHosts=[[[NSMutableArray alloc] initWithCapacity:[hosts count]] autorelease];
        NSEnumerator *hostEnumerator=[hosts objectEnumerator];
        DUHost *host;
        
        while(host=[hostEnumerator nextObject]) {
            [readableHosts addObject:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                        [host getName], @"Hostname",
                        [host getAddress], @"Address",
                        [[host interface] getName], @"Interface",
                        [NSNumber numberWithBool:[host isActive]], @"Active",
                        [host lastUpdate], @"LastUpdate",
                        [host realStatus], @"Status",
                        [host hostProperties], @"Properties",
                        NULL]];
        }
        
        NSLog(@"Saving %@ in %@",self,fileName);
        duNeedNotification=YES;
        if(![DUInterface mustNotifyObservers]) {
            NSLog(@"Notifying observers...");
            [[NSDistributedNotificationCenter defaultCenter] widePostNotification:DUDataUpdated];
        }

        userDict=[NSDictionary dictionaryWithObjectsAndKeys:
                                        name, @"UserName",
                                        password, @"Password",
                                        [service getServiceName], @"Service",
                                        readableHosts, @"Hosts",
                                        [NSNumber numberWithBool:active], @"Active",
                                        userStatus, @"UserStatus",
                                        NULL];
                                        
        [userDict writeToFile:fileName atomically:NO];
        [[NSFileManager defaultManager] changeFileAttributes:[DULibraryManager filesAttributes]
                                        atPath:fileName];
        [self setDirty:NO];
    }
}

+ (void)saveUsers {
    duNeedNotification=NO;
    [[_users allValues] makeObjectsPerformSelector:@selector(saveUser)];
    if(duNeedNotification) {
    }
}

+ (void)loadUsers {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    
    NSDirectoryEnumerator *dirEnumerator=[DULibraryManager usersEnumerator];
    NSString *userExtension=[DULibraryManager userExtension];
    NSString *userFile;
    
    if(!dirEnumerator) {
        NSLog(@"No user referenced yet");
        return;
    }
    
    while(userFile=[dirEnumerator nextObject]) {
        if([[userFile pathExtension] isEqualToString:userExtension]) {
            NSDictionary *userDict=[NSDictionary dictionaryWithContentsOfFile:
                            [[DULibraryManager usersPath] stringByAppendingPathComponent:userFile]];
            if(!userDict) {
                NSLog(@"File %@ not a DU user file", userFile);
            } else {
                NSString *lname=[userDict objectForKey:@"UserName"];
                NSString *lpassword=[userDict objectForKey:@"Password"];
                DUServiceUpdater *lservice=[DUServiceUpdater getServiceUpdaterFor:[userDict objectForKey:@"Service"]];
                BOOL lactive=[[userDict objectForKey:@"Active"] boolValue];
                NSArray *lhosts=[userDict objectForKey:@"Hosts"];
                NSString *lstatus=[userDict objectForKey:@"UserStatus"];
                NSEnumerator *hostEnumerator=[lhosts objectEnumerator];
                NSDictionary *host;
                DUUser *theUser=[DUUser addUserWithName:lname andPassword:lpassword andService:lservice];

                if(lstatus) {
                    [theUser setUserStatus:lstatus];
                }
                
                if(theUser) {
                    NSLog(@"Loading user %@",theUser);
                    
                    [theUser setActive:lactive];
                    while(host=[hostEnumerator nextObject]) {
                        NSString *hostName=[host objectForKey:@"Hostname"];
                        NSString *address=[host objectForKey:@"Address"];
                        DUInterface *interface=[DUInterface  getInterface:[host objectForKey:@"Interface"]];
                        BOOL hostActive=[[host objectForKey:@"Active"] boolValue];
                        NSDate *lastUpdate=[host objectForKey:@"LastUpdate"];
                        NSString *hostStatus=[host objectForKey:@"Status"];
                        NSMutableDictionary *hostProperties=[host objectForKey:@"Properties"];
                        DUHost *theHost=[[DUHost alloc] initWithName:hostName];
                                                    
                        [theHost setInterface:interface];
                        [theHost setActive:hostActive];
                        [theHost setLastUpdate:lastUpdate];
                        [theHost setAddress:address];
                        [theHost setStatus:hostStatus];
                        
                        if(hostProperties) {
                            [theHost setHostProperties:hostProperties];
                        }
                        
                        [theUser addHost:theHost];
                        [theHost release];
                    }
                    [theUser setDirty:NO];
                }
            }
        }
    }
    [pool release];
}

- (void)removeUser {
    NSString *fileName=[DULibraryManager fileNameForUser:self];
    NSLog(@"Removing %@ and file %@",self,fileName);
    [self retain];
    [_users removeObjectForKey:[self description]];
    [[NSFileManager defaultManager] removeFileAtPath:fileName handler:nil];
    [self release];
    NSLog(@"Notifying observers...");
    [[NSDistributedNotificationCenter defaultCenter] widePostNotification:DUDataUpdated];
}

- (void)dealloc {
    NSLog(@"Deallocating user %@", self);
    [name release];
    [password release];
    [userStatus release];
    [hosts release];
    [super dealloc];
}

- retain {
    return [super retain];
}

- (void)release {
    [super release];
}

@end
