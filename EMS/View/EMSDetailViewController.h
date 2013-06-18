//
//  EMSDetailViewController.h
//

#import <UIKit/UIKit.h>

@interface EMSDetailViewController : UIViewController

@property (nonatomic, strong) NSManagedObject *session;

- (IBAction)share:(id)sender;

@end
