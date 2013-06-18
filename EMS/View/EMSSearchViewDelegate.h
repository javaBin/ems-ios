//
//  EMSSearchViewDelegate.h
//  EMS
//
//  Created by Chris Searle on 6/18/13.
//  Copyright (c) 2013 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EMSSearchViewDelegate <NSObject>

@required

- (void) setSearchText:(NSString *)searchText withKeywords:(NSSet *)keywords andLevels:(NSSet *)levels;

@end
