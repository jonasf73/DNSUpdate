//
//  DUGenericHTTPUpdater.h
//  DNSUpdate2
//
//  Created by Julien Jalon on Tue Feb 12 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUServiceUpdater.h"

@interface DUGenericHTTPUpdater : DUServiceUpdater {

}

- (void)updateHosts:(NSArray *)hosts user:(DUUser *)theUser withKey:(NSString *)key;
- (BOOL)isValidOption:(NSString *)theOption;
- (BOOL)canGroupHosts;

- (NSString *)ipOption;

@end
