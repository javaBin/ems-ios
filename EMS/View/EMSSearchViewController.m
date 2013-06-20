//
//  EMSSearchViewController.m
//

#import "EMSSearchViewController.h"

@interface EMSSearchViewController ()

@end

@implementation EMSSearchViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.search.text = self.currentSearch;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [self.keywords count];
            break;

        case 1:
            return [self.levels count];
            break;

        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SessionCell"];
    }

    switch (indexPath.section) {
        case 0:
        {
            NSString *keyword = [self.keywords objectAtIndex:indexPath.row];

            cell.textLabel.text = keyword;

            if ([self.currentKeywords containsObject:keyword]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }

            break;
        }

        case 1:
        {
            NSString *level = [self.levels objectAtIndex:indexPath.row];

            cell.textLabel.text = [level capitalizedString];

            if ([self.currentLevels containsObject:level]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }

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
            return @"Keywords";
            break;
        case 1:
            return @"Levels";
            break;

        default:
            break;
    }

    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            NSString *keyword = [self.keywords objectAtIndex:indexPath.row];

            // Keywords
            NSMutableSet *keywords = [NSMutableSet setWithSet:self.currentKeywords];

            if ([keywords containsObject:keyword]) {
                [keywords removeObject:keyword];
            } else {
                [keywords addObject:keyword];
            }

            self.currentKeywords = [NSSet setWithSet:keywords];

            break;
        }

        case 1:
        {
            NSString *level = [self.levels objectAtIndex:indexPath.row];

            // Keywords
            NSMutableSet *levels = [NSMutableSet setWithSet:self.currentLevels];

            if ([levels containsObject:level]) {
                [levels removeObject:level];
            } else {
                [levels addObject:level];
            }

            self.currentLevels = [NSSet setWithSet:levels];

            break;
        }

        default:
            break;
    }

    [tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	if ([searchText length] == 0) {
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:searchBar afterDelay:0];
	}
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";

    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void)apply:(id)sender {
    NSMutableSet *lowerCasedLevels = [[NSMutableSet alloc] init];
    
    [self.currentLevels enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *level = (NSString *)obj;
        
        [lowerCasedLevels addObject:[level lowercaseString]];
    }];
    
    [self.delegate setSearchText:self.search.text withKeywords:[NSSet setWithSet:self.currentKeywords] andLevels:[NSSet setWithSet:lowerCasedLevels]];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clear:(id)sender {
    self.search.text = @"";
    self.currentKeywords = nil;
    self.currentLevels = nil;

    [self apply:sender];
}

@end
