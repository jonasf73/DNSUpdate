//
//  DUFakeInterface.h
//  DNSUpdate2
//
//  Created by Julien Jalon on Sat Mar 30 2002.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUInterface.h"

@interface DUFakeInterface : DUInterface {
    NSString *fakeAddress;
}

+ (DUInterface *)fakeOfflineInterface;
- initWithName:(NSString *)theName address:(NSString *)theAddress;

@end
