//
//  EMSConferenceDetailViewController.m
//

#import "EMS-Swift.h"

#import "EMSConferenceDetailViewController.h"

#import "EMSAppDelegate.h"
#import "EMSTracking.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

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
    [super viewDidAppear:animated];

    [EMSTracking trackScreen:@"Conference Detail Screen"];
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
            cell.textLabel.text = NSLocalizedString(@"Name", @"Conference detail name label.");
            cell.detailTextLabel.text = conference.name;
            break;
        }
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"Venue", @"Conference detail venue label.");
            cell.detailTextLabel.text = conference.venue;
            break;
        }
        case 2: {
            cell.textLabel.text = NSLocalizedString(@"# Sessions", @"Conference detail #Sessions label.");
            if (conference.sessions.count > 0) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long) conference.sessions.count];
            } else {
                NSString *string = NSLocalizedString(@"~ %@ available for download", @"~ {Number of sessions} available for download");
                cell.detailTextLabel.text = [NSString stringWithFormat:string, conference.hintCount];
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

            cell.textLabel.text = NSLocalizedString(@"Dates", @"Conference detail dates label.");
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
            cell.textLabel.text = NSLocalizedString(@"Delete all sessions", @"Conference detail delete all sessions button title.");
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
            return NSLocalizedString(@"Details", @"Conference Details Section Header");

        case 1:
            return NSLocalizedString(@"Actions", @"Conference Actions Section Header");

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
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete all sessions", @"Delete Conference Confirmation Dialog Title")
                                                                       message:NSLocalizedString(@"This will remove all sessions including any favourite marks. Session information will then have to be downloaded again.", @"Delete Conference Confirmation Dialog Description")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Delete Conference Confirmation Dialog Cancel")
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete Conference Confirmation Dialog Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            
            DDLogVerbose(@"Deleting all sessions for conference %@", conference.href);
            
            EMSModel *model = [[EMSAppDelegate sharedAppDelegate] model];
            
            [model clearConference:conference];
            
            [self.tableView reloadData];
        }];

        [alert addAction:deleteAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
