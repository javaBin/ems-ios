//
//  EMSConferenceDetailViewController.m
//

#import "EMSConferenceDetailViewController.h"

#import "EMSAppDelegate.h"
#import "EMSFeatureConfig.h"

@interface EMSConferenceDetailViewController ()

@end

@implementation EMSConferenceDetailViewController

@synthesize conference;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    if ([EMSFeatureConfig isGoogleAnalyticsEnabled]) {
        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker set:kGAIScreenName value:@"Conference Detail Screen"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (conference.sessions.count > 0)
        return 2;

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            int count = 3;

            if (conference.start != nil || conference.end != nil) {
                count++;
            }

            return count;
        }
        case 1:
            return 1;

        default:
            break;
    }
    return 0;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = @"Name";
            cell.detailTextLabel.text = conference.name;
            break;
        }
        case 1: {
            cell.textLabel.text = @"Venue";
            cell.detailTextLabel.text = conference.venue;
            break;
        }
        case 2: {
            cell.textLabel.text = @"# Sessions";
            if (conference.sessions.count > 0) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long) conference.sessions.count];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"~ %@ available for download", conference.hintCount];
            }
            break;
        }
        case 3: {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.timeStyle = NSDateFormatterNoStyle;

            NSMutableArray *dates = [[NSMutableArray alloc] init];

            if (conference.start != nil) {
                [dates addObject:[dateFormatter stringFromDate:conference.start]];
            }

            if (conference.end != nil) {
                [dates addObject:[dateFormatter stringFromDate:conference.end]];
            }

            cell.textLabel.text = @"Dates";
            cell.detailTextLabel.text = [dates componentsJoinedByString:@" - "];

            break;
        }


        default:
            break;
    }
}

- (void)configureActionCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Delete all sessions";
            cell.textLabel.textColor = [UIColor redColor];
            break;

        default:
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    switch (indexPath.section) {
        case 0: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ConferenceDetailCell"];

            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"ConferenceCell"];
            }

            [self configureCell:cell atIndexPath:indexPath];

            break;
        }

        case 1: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ConferenceDetailActionCell"];

            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ConferenceDetailActionCell"];
            }

            [self configureActionCell:cell atIndexPath:indexPath];

            break;
        }

        default:
            break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Details";

        case 1:
            return @"Actions";

        default:
            return @"";
    }
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1)
        return indexPath;

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                        message:@"This will remove all sessions including any favourite marks. Session information will then have to be downloaded again."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Delete", nil];
        [alert show];
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        EMS_LOG(@"Deleting all sessions for conference %@", conference.href);

        EMSModel *model = [[EMSAppDelegate sharedAppDelegate] model];

        [model clearConference:conference];

        [self.tableView reloadData];
    }
}

@end
