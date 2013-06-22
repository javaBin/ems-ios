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

- (void) viewDidAppear:(BOOL)animated {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendView:@"Search Screen"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
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

        case 2:
            return [self.types count];
            break;

        default:
            return 0;
            break;
    }
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
             fromList:(NSArray *)list andCurrentList:(NSSet *)currentList
          capitalized:(BOOL)capitalized
              cleaned:(BOOL)cleaned
            withImage:(BOOL)imageFlag {
    NSString *value = [list objectAtIndex:indexPath.row];
    
    if (capitalized) {
        value = [value capitalizedString];
    }

    if (cleaned) {
        value = [value stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    }
    
    cell.textLabel.text = value;
    
    if ([currentList containsObject:[list objectAtIndex:indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    if (imageFlag) {
        cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", [list objectAtIndex:indexPath.row]]];
    } else {
        cell.imageView.image = nil;
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
            [self configureCell:cell forIndexPath:indexPath fromList:self.keywords andCurrentList:self.currentKeywords capitalized:NO cleaned:NO withImage:NO];
            break;
        }

        case 1:
        {
            [self configureCell:cell forIndexPath:indexPath fromList:self.levels andCurrentList:self.currentLevels capitalized:YES cleaned:NO withImage:YES];
            break;
        }
            
        case 2:
        {
            [self configureCell:cell forIndexPath:indexPath fromList:self.types andCurrentList:self.currentTypes capitalized:YES cleaned:YES withImage:NO];
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
        case 2:
            return @"Types";
            break;

        default:
            break;
    }

    return nil;
}

- (NSSet *) selectRowForIndexPath:(NSIndexPath *)indexPath forList:(NSArray *)list andCurrentList:(NSSet *)currentList {
    NSString *value = [list objectAtIndex:indexPath.row];

    NSMutableSet *values = [NSMutableSet setWithSet:currentList];

    if ([currentList containsObject:value]) {
        [values removeObject:value];
    } else {
        [values addObject:value];
    }
    
    return [NSSet setWithSet:values];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            self.currentKeywords = [self selectRowForIndexPath:indexPath forList:self.keywords andCurrentList:self.currentKeywords];
            break;
        }

        case 1:
        {
            self.currentLevels = [self selectRowForIndexPath:indexPath forList:self.levels andCurrentList:self.currentLevels];
            break;
        }
            
        case 2:
        {
            self.currentTypes = [self selectRowForIndexPath:indexPath forList:self.types andCurrentList:self.currentTypes];
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

    NSMutableSet *lowerCasedTypes = [[NSMutableSet alloc] init];
    
    [self.currentTypes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSString *type = (NSString *)obj;
        
        [lowerCasedTypes addObject:[type lowercaseString]];
    }];
    
    [self.delegate setSearchText:self.search.text
                    withKeywords:[NSSet setWithSet:self.currentKeywords]
                       andLevels:[NSSet setWithSet:lowerCasedLevels]
                        andTypes:[NSSet setWithSet:lowerCasedTypes]];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clear:(id)sender {
    self.search.text = @"";
    self.currentKeywords = nil;
    self.currentLevels = nil;
    self.currentTypes = nil;

    [self apply:sender];
}

@end
