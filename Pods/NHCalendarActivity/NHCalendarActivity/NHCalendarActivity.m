//
//  NHCalendarActivity.m
//  Noite Hoje for iPad
//
//  Created by Otavio Cordeiro on 11/25/12.
//  Copyright (c) 2012 Noite Hoje. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES fOR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NHCalendarActivity.h"

@interface NHCalendarActivity ()
@property (strong) NSMutableArray *events;
@end

@implementation NHCalendarActivity

-(id)init
{
    self = [super init];
    
    if (self) {
        self.events = [NSMutableArray array];
        self.activityImage = [UIImage imageNamed:@"NHCalendarActivity.bundle/NHCalendarActivityIcon"];
    }
    
    return self;
}

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
    return NSLocalizedString(@"Save to Calendar", @"Save to Calendar localized string.");
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    
    for (id item in activityItems) {
        if ([item isKindOfClass:[NHCalendarEvent class]] &&
            (status == EKAuthorizationStatusNotDetermined || status == EKAuthorizationStatusAuthorized)) {
            return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id item in activityItems)
        if ([item isKindOfClass:[NHCalendarEvent class]])
            [self.events addObject:item];
}

- (void)performActivity
{
    EKEventStore *ekEventStore = [[EKEventStore alloc] init];
    
    [ekEventStore requestAccessToEntityType:EKEntityTypeEvent
                                 completion:^(BOOL granted, NSError *kError)
    {
        if (granted) {
            for (NHCalendarEvent *event in self.events) {
                EKEvent *ekEvent = [EKEvent eventWithEventStore:ekEventStore];
                
                ekEvent.title = event.title;
                ekEvent.location = event.location;
                ekEvent.notes = event.notes;
                ekEvent.startDate = event.startDate;
                ekEvent.endDate = event.endDate;
                ekEvent.allDay = event.allDay;
                ekEvent.timeZone = event.timeZone;
                ekEvent.URL = event.URL;
                
                for (id alarm in event.alarms)
                    if ([alarm isKindOfClass:[EKAlarm class]])
                        [ekEvent addAlarm:alarm];
                
                [ekEvent setCalendar:[ekEventStore defaultCalendarForNewEvents]];
                
                NSError *error = nil;
                [ekEventStore saveEvent:ekEvent
                                   span:EKSpanThisEvent
                                  error:&error];
                
                if (error == nil) {
                    if ([self.delegate respondsToSelector:@selector(calendarActivityDidFinish:)])
                        [self.delegate calendarActivityDidFinish:event];
                } else {
                    if ([self.delegate respondsToSelector:@selector(calendarActivityDidFail:withError:)])
                        [self.delegate calendarActivityDidFail:event withError:error];
                }
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(calendarActivityDidFailWithError:)])
                [self.delegate calendarActivityDidFailWithError:kError];
        }
    }];
    
    [self activityDidFinish:YES];
}

@end
