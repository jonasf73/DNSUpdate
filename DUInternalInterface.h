//
//  DUInternalInterface.h
//  DNSUpdate2
//
//  Created by jalon on Sat Mar 31 2001.
//  Copyright (c) 2001-2003 Julien Jalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUInterface.h"

@interface DUInternalInterface : DUInterface {
    NSString *interface;
}

+ (DUInterface *)internalInterfaceWithName: (NSString *)theName interface:(NSString *)theInterface;
- (DUInterface *)initWithName:(NSString *)theName interface:(NSString *)theInterface;

@end
