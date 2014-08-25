//
//  SpeakerPic.h
//  EMS
//
//  Created by Chris Searle on 25/08/14.
//  Copyright (c) 2014 Chris Searle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SpeakerPic : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSDate * lastUpdated;

@end
