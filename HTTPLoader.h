//
//  HTTPLoader.h
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUCommon.h"

#define HTTPSUCCESSCODE 200
#define HTTPBADAUTH 401
#define HTTPSERVERERROR 500
#define TIMEOUT 90

extern NSString *ServerCode;
extern NSString *Output;


BOOL isNetworkReachable();

NSDictionary *getURL(NSURL *theURL, NSString *user, NSString *password);
