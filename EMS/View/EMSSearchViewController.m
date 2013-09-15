//
//  EMSSearchViewController.m
//

#import "EMSSearchViewController.h"

@interface EMSSearchViewController ()

@end

@implementation EMSSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.search.text = [self.advancedSearch search];

    for (UIView *searchBarSubview in [self.search subviews]) {

        if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {

            @try {

                [(UITextField *)searchBarSubview setReturnKeyType:UIReturnKeyDone];
                [(UITextField *)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
            }
            @catch (NSException * e) {

                // ignore exception
            }
        }
    }

}

- (void) viewDidAppear:(BOOL)animated {
#ifndef DO_NOT_USE_GA
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendView:@"Search Screen"];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return self.keywords.count;
            break;

        case 1:
            return self.levels.count;
            break;

        case 2:
            return self.types.count;
            break;
            
        case 3:
            return self.rooms.count;
            break;

        case 4:
            return 2;
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
            [self configureCell:cell forIndexPath:indexPath fromList:self.keywords andCurrentList:[self.advancedSearch fieldValuesForKey:emsKeyword] capitalized:NO cleaned:NO withImage:NO];
            break;
        }

        case 1:
        {
            [self configureCell:cell forIndexPath:indexPath fromList:self.levels andCurrentList:[self.advancedSearch fieldValuesForKey:emsLevel] capitalized:YES cleaned:NO withImage:YES];
            break;
        }
            
        case 2:
        {
            [self configureCell:cell forIndexPath:indexPath fromList:self.types andCurrentList:[self.advancedSearch fieldValuesForKey:emsType] capitalized:YES cleaned:YES withImage:NO];
            break;
        }
            
        case 3:
        {
            [self configureCell:cell forIndexPath:indexPath fromList:self.rooms andCurrentList:[self.advancedSearch fieldValuesForKey:emsRoom] capitalized:NO cleaned:NO withImage:NO];
            break;
        }
            
        case 4:
        {
            [self configureCell:cell forIndexPath:indexPath fromList:@[@"English", @"Norwegian"] andCurrentList:[self.advancedSearch fieldValuesForKey:emsLang] capitalized:YES cleaned:NO withImage:YES];
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
        case 3:
            return @"Rooms";
            break;
        case 4:
            return @"Language";
            break;

        default:
            break;
    }

    return nil;
}

- (void) selectRowForIndexPath:(NSIndexPath *)indexPath forList:(NSArray *)list andKey:(EMSSearchField)key {
    NSString *value = [list objectAtIndex:indexPath.row];

    NSMutableSet *values = [NSMutableSet setWithSet:[self.advancedSearch fieldValuesForKey:key]];

    if ([[self.advancedSearch fieldValuesForKey:key] containsObject:value]) {
        [values removeObject:value];
    } else {
        [values addObject:value];
    }
    
    [self.advancedSearch setFieldValues:[NSSet setWithSet:values] forKey:key];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            [self selectRowForIndexPath:indexPath forList:self.keywords andKey:emsKeyword];
            break;
        }

        case 1:
        {
            [self selectRowForIndexPath:indexPath forList:self.levels andKey:emsLevel];
            break;
        }
            
        case 2:
        {
            [self selectRowForIndexPath:indexPath forList:self.types andKey:emsType];
            break;
        }
            
        case 3:
        {
            [self selectRowForIndexPath:indexPath forList:self.rooms andKey:emsRoom];
            break;
        }
            
        case 4:
        {
            [self selectRowForIndexPath:indexPath forList:@[@"English", @"Norwegian"] andKey:emsLang];
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
    [self.advancedSearch setSearch:self.search.text];
    
    [self.delegate advancedSearchUpdated];

    
}

- (void)clear:(id)sender {
    [self.advancedSearch clear];

    self.search.text = [self.advancedSearch search];
    
    [self apply:sender];
}

@end
