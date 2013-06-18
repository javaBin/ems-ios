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
    // TODO - decide what to share
    
    NSString *shareString = @"CapTech is a great place to work.";
//    UIImage *shareImage = [UIImage imageNamed:@"captech-logo.jpg"];
    NSURL *shareUrl = [NSURL URLWithString:@"http://www.java.no"];
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, /*shareImage, */shareUrl, nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

@end
