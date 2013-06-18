//
//  EMSDetailViewController.m
//

#import "EMSDetailViewController.h"

@interface EMSDetailViewController ()

@end

@implementation EMSDetailViewController

@synthesize session;

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [session valueForKey:@"title"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)share:(id)sender {
    NSString *shareString = [NSString stringWithFormat:@"%@ - %@", [[self.session valueForKey:@"conference"] valueForKey:@"name"], [self.session valueForKey:@"title"]];
    
    CLS_LOG(@"About to share for %@", shareString);
    
//TODO - image?    UIImage *shareImage = [UIImage imageNamed:@"captech-logo.jpg"];
    // TODO - web URL?
    NSURL *shareUrl = [NSURL URLWithString:@"http://www.java.no"];
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, /*shareImage, */shareUrl, nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

@end
