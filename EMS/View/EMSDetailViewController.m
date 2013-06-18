//
//  EMSDetailViewController.m
//

#import "EMSDetailViewController.h"

#import "EMSAppDelegate.h"

#import "EMSRetriever.h"

@interface EMSDetailViewController ()

@end

@implementation EMSDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [self.session valueForKey:@"title"];
    
    self.room.text = [self.session valueForKey:@"roomName"];
    self.level.text = [[self.session valueForKey:@"level"] capitalizedString];

    UIImage *normalImage = [UIImage imageNamed:@"28-star-grey"];
    UIImage *selectedImage = [UIImage imageNamed:@"28-star-yellow"];
    UIImage *highlightedImage = [UIImage imageNamed:@"28-star"];
    
    if ([[self.session valueForKey:@"format"] isEqualToString:@"lightning-talk"]) {
        normalImage = [UIImage imageNamed:@"64-zap-grey"];
        selectedImage = [UIImage imageNamed:@"64-zap-yellow"];
        highlightedImage = [UIImage imageNamed:@"64-zap"];
    }
    
    [self.button setImage:normalImage forState:UIControlStateNormal];
    [self.button setImage:selectedImage forState:UIControlStateSelected];
    [self.button setImage:highlightedImage forState:UIControlStateHighlighted];
    
    [self.button setSelected:[[self.session valueForKey:@"favourite"] boolValue]];
    
    NSDateFormatter *dateFormatterTime = [[NSDateFormatter alloc] init];
    
    [dateFormatterTime setDateFormat:@"HH:mm"];
    
    NSManagedObject *slot = [self.session valueForKey:@"slot"];
    
    self.time.text = [NSString stringWithFormat:@"%@ - %@",
                      [dateFormatterTime stringFromDate:[slot valueForKey:@"start"]],
                      [dateFormatterTime stringFromDate:[slot valueForKey:@"end"]]];
    
    [self buildPage];
    
    [self retrieve];
}

- (IBAction)toggleFavourite:(id)sender {
    CLS_LOG(@"Trying to toggle favourite for %@", self.session);
    
    BOOL isFavourite = [[self.session valueForKey:@"favourite"] boolValue];
    
    if (isFavourite == YES) {
        [self.session setValue:[NSNumber numberWithBool:NO] forKey:@"favourite"];
    } else {
        [self.session setValue:[NSNumber numberWithBool:YES] forKey:@"favourite"];
    }
    
    NSError *error;
    if (![[self.session managedObjectContext] save:&error]) {
        CLS_LOG(@"Failed to toggle favourite for %@, %@, %@", self.session, error, [error userInfo]);
        
        // TODO - die?
    }
    
    [self.button setSelected:[[self.session valueForKey:@"favourite"] boolValue]];
}

- (void) buildPage {
    NSString *path = [[NSBundle mainBundle] bundlePath];
	NSURL *baseURL = [NSURL fileURLWithPath:path];
    [self.webView loadHTMLString:[self buildPage:self.session] baseURL:baseURL];
}

- (void) retrieve {
    EMSRetriever *retriever = [[EMSRetriever alloc] init];
    
    retriever.delegate = self;
    
    CLS_LOG(@"Retrieving speakers");
    
    [retriever refreshSpeakers:[NSURL URLWithString:[self.session valueForKey:@"speakerCollection"]]];
}

- (void) finishedSpeakers:(NSArray *)speakers forHref:(NSURL *)href {
    CLS_LOG(@"Storing speakers %d", [speakers count]);
    
    [[[EMSAppDelegate sharedAppDelegate] model] storeSpeakers:speakers forHref:[href absoluteString] error:nil];

    // TODO - should saving of pics be in model? No - it needs to be in background. We could just save in the retrieve - but that's poor. At this point we have the URL for the pic and we have the href of the speaker. We should probably make a custom retriever.
    
    [self buildPage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)share:(id)sender {
    // More info - http://blogs.captechconsulting.com/blog/steven-beyers/cocoaconf-dc-recap-sharing-uiactivityviewcontroller

    NSString *shareString = [NSString stringWithFormat:@"%@ - %@", [[self.session valueForKey:@"conference"] valueForKey:@"name"], [self.session valueForKey:@"title"]];
    
    CLS_LOG(@"About to share for %@", shareString);
    
//TODO - image?    UIImage *shareImage = [UIImage imageNamed:@"captech-logo.jpg"];
    // TODO - web URL?
    NSURL *shareUrl = [NSURL URLWithString:@"http://www.java.no"];
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, /*shareImage, */shareUrl, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:nil];
    
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint,
                                                     UIActivityTypeCopyToPasteboard,
                                                     UIActivityTypeAssignToContact,
                                                     UIActivityTypeSaveToCameraRoll];
    
    [activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        CLS_LOG(@"Sharing of %@ via %@ - completed %d", shareString, activityType, completed);
    }];
    
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (NSString *)buildPage:(NSManagedObject *)session {
    
	NSString *page = [NSString stringWithFormat:@""
					  "<html>"
					  "<head>"
					  "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\"/>"
                      "<meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=1.0;'>"
					  "</head>"
					  "<body>"
					  "<h1>%@</h1>"
					  "%@"
					  "%@"
					  "%@"
					  "</body>"
					  "</html>",
					  [session valueForKey:@"title"],
					  [self paraContent:[session valueForKey:@"body"]],
					  [self keywordContent:[session valueForKey:@"keywords"]],
					  [self speakerContent:[session valueForKey:@"speakers"]]];
	
	return page;
}

- (NSString *)paraContent:(NSString *)text {
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    
    return [NSString stringWithFormat:@"<p>%@</p>", [lines componentsJoinedByString:@"</p><p>"]];
}

- (NSString *)keywordContent:(NSArray *)keywords {
	NSMutableString *result = [[NSMutableString alloc] init];

    if (keywords != nil && [keywords count] > 0) {
        [result appendString:@"<h2>Keywords</h2>"];

        [result appendString:@"<ul>"];

        NSMutableArray *listItems = [[NSMutableArray alloc] init];

        [keywords enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSManagedObject *speaker = (NSManagedObject *)obj;

            [listItems addObject:[speaker valueForKey:@"name"]];
        }];

        [result appendFormat:@"<li>%@</li>", [listItems componentsJoinedByString:@"</li><li>"]];

        [result appendString:@"</ul>"];
    }

    return [NSString stringWithString:result];
}

- (NSString *)speakerContent:(NSArray *)speakers {
	NSMutableString *result = [[NSMutableString alloc] init];

    if (speakers != nil && [speakers count] > 0) {
        [result appendString:@"<h2>Speakers</h2>"];
    
        [speakers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSManagedObject *speaker = (NSManagedObject *)obj;
            
            NSString *name = [speaker valueForKey:@"name"];
            if (name != nil) {
                [result appendString:[NSString stringWithFormat:@"<h3>%@</h3>", name]];
            }

            NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];

            NSString *pngFilePath = [NSString stringWithFormat:@"%@/%@.png",[docDir stringByAppendingPathComponent:@"bioIcons"],[speaker valueForKey:@"name"]]; // TODO - name as filename?

            NSFileManager *fileManager = [NSFileManager defaultManager];

            if ([fileManager fileExistsAtPath:pngFilePath]) {
                NSError *fileError = nil;
                
                NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:pngFilePath error:&fileError];
                
                if (fileError != nil) {
                    CLS_LOG(@"Got a file error reading file attributes for file %@", pngFilePath);
                } else {
                    if ([fileAttributes fileSize] > 0) {
                        [result appendString:[NSString stringWithFormat:@"<img src='file://%@' width='50px' style='float: left; margin-right: 3px; margin-bottom: 3px'/>", pngFilePath]];
                    } else {
                        CLS_LOG(@"Empty bioPic %@", pngFilePath);
                    }
                }
            }
           
            NSString *bio = [speaker valueForKey:@"bio"];
            if (bio != nil) {
                [result appendString:[self paraContent:bio]];
            }
        }];
        
	}
    
	return [NSString stringWithString:result];
}



@end
