//
//  DUServiceInterface.h
//  DNSUpdate2
//
//  Created by Julien Jalon on Mon Feb 11 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DUUser.h"
#import "DUHost.h"

@interface DUServiceInterface : NSObject {
    IBOutlet NSBox *duServiceUserView;
    IBOutlet NSBox *duServiceHostView;
}

+ (void)registerServiceInterface:(DUServiceInterface *)theInterface;
+ (NSDictionary *)serviceInterfaces;
+ (DUServiceInterface *)getServiceInterfaceFor:(NSString *)theName;
+ (void)registerService;

- (NSString *)getServiceName;

- (NSView *)serviceUserView;
- (NSView *)serviceHostView;

- (void)validateUser:(DUUser *)theUser;
- (void)validateHost:(DUHost *)theHost;

- (void)prepareHostViewForHost:(DUHost *)DUHost;
- (void)prepareUserViewForUser:(DUUser *)DUUser;
- (void)clearHostView;
- (void)clearUserView;

@end
