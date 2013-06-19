//
//  EMSSearchViewDelegate.h
//

#import <Foundation/Foundation.h>

@protocol EMSSearchViewDelegate <NSObject>

@required

- (void) setSearchText:(NSString *)searchText withKeywords:(NSSet *)keywords andLevels:(NSSet *)levels;

@end
