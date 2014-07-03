# NHCalendarActivity

**NHCalendarActivity** is an easy to use custom UIActivity (iOS 6+) that adds events and alarms to the iOS calendar.

## How to install it?

[CocoaPods](http://cocoapods.org) is the easiest way to install NHCalendarActivity. Run ```pod search NHCalendarActivity``` to search for the latest version.

Then, copy and past the ```pod``` line to your ```Podfile```. Your podfile shall look like this:

```
platform :ios, '6.0'
pod 'NHCalendarActivity', '~> 0.0.1'
```

Finally, install it running ```pod install```.

## How to use it?

First, create a NHCalendarEvent instance of an event (note that you can include alarms):

```objective-c
-(NHCalendarEvent *)createCalendarEvent
{
    NHCalendarEvent *calendarEvent = [[NHCalendarEvent alloc] init];
    
    calendarEvent.title = @"Long-expected Party";
    calendarEvent.location = @"The Shire";
    calendarEvent.notes = @"Bilbo's eleventy-first birthday.";
    calendarEvent.startDate = [NSDate dateWithTimeIntervalSinceNow:3600];
    calendarEvent.endDate = [NSDate dateWithTimeInterval:3600
                                               sinceDate:calendarEvent.startDate];
    calendarEvent.allDay = NO;

    // Add alarm
    NSArray *alarms = @[
        [EKAlarm alarmWithRelativeOffset:- 60.0f * 60.0f * 24],  // 1 day before
        [EKAlarm alarmWithRelativeOffset:- 60.0f * 15.0f]        // 15 minutes before
    ];
    calendarEvent.alarms = alarms;
    
    return calendarEvent;
}
```

Then, initialize the UIActivityViewController using both NHCalendarEvent and NHCalendarActivity:

```objective-c
- (IBAction)openBtnTouched:(id)sender
{
    NSString *msg = NSLocalizedString(@"NHCalendarActivity", nil);
    NSURL* url = [NSURL URLWithString:@"http://git.io/LV7YIQ"];
    
    NSArray *activities = @[
        [[NHCalendarActivity alloc] init]
    ];
    
    NSArray *items = @[
        msg,
        url,
        [self createCalendarEvent]
    ];
    
    UIActivityViewController* activity = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                           applicationActivities:activities];
    
    [self presentViewController:activity
                       animated:YES
                     completion:NULL];    
}
```

There's also a NHCalendarActivityDelegate protocol, which can be used to perform additional actions:

```objective-c
#pragma mark - NHCalendarActivityDelegate

-(void)calendarActivityDidFinish:(NHCalendarEvent *)event
{
    NSLog(@"Event created from %@ to %@", event.startDate, event.endDate);
}

-(void)calendarActivityDidFail:(NHCalendarEvent *)event
                     withError:(NSError *)error
{
    NSLog(@"Ops!");
}

- (void)calendarActivityDidFailWithError:(NSError *)error
{
    NSLog(@"Ops!");
}
```

And that's all.

## See it working

![NHCalendarActivity](http://f.cl.ly/items/1e003C2b1n1m1t3v1C2d/iOS%20Simulator%20Screen%20shot%20Nov%2029,%202012%208.11.15%20PM.jpg)

## License

Copyright (c) 2012 Otavio Cordeiro. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
