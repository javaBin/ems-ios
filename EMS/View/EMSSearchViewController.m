//
//  EMSSearchViewController.m
//

#import "EMSSearchViewController.h"

@interface EMSSearchViewController ()
@property(nonatomic, strong) NSMutableArray *sections;
@end

@implementation EMSSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.sections = [NSMutableArray arrayWithObjects:@"Keywords", @"Levels", @"Types", @"Rooms", @"Language", nil];

    if (self.keywords == nil || [self.keywords count] == 0) {
        [self.sections removeObject:@"Keywords"];
    }
    if (self.levels == nil || [self.levels count] == 0) {
        [self.sections removeObject:@"Levels"];
    }
    if (self.types == nil || [self.types count] == 0) {
        [self.sections removeObject:@"Types"];
    }
    if (self.rooms == nil || [self.rooms count] == 0) {
        [self.sections removeObject:@"Rooms"];
    }

    self.search.text = [self.advancedSearch search];

    for (UIView *searchBarSubview in [self.search subviews]) {

        if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {

            @try {
                [(UITextField *) searchBarSubview setReturnKeyType:UIReturnKeyDone];
                [(UITextField *) searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
            }
            @catch (NSException *e) {

                // ignore exception
            }
        }
    }

}

- (void)viewDidAppear:(BOOL)animated {
#ifndef DO_NOT_USE_GA
    id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Search Screen"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    NSString *section = [self.sections objectAtIndex:sectionIndex];

    if ([section isEqual:@"Keywords"]) {
        return self.keywords.count;
    }

    if ([section isEqual:@"Levels"]) {
        return self.levels.count;
    }

    if ([section isEqual:@"Types"]) {
        return self.types.count;
    }

    if ([section isEqual:@"Rooms"]) {
        return self.rooms.count;
    }

    if ([section isEqual:@"Language"]) {
        return 2;
    }

    return 0;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SessionCell"];
    }

    NSString *section = [self.sections objectAtIndex:indexPath.section];

    if ([section isEqual:@"Keywords"]) {
        [self configureCell:cell forIndexPath:indexPath fromList:self.keywords andCurrentList:[self.advancedSearch fieldValuesForKey:emsKeyword] capitalized:NO cleaned:NO withImage:NO];
    }

    if ([section isEqual:@"Levels"]) {
        [self configureCell:cell forIndexPath:indexPath fromList:self.levels andCurrentList:[self.advancedSearch fieldValuesForKey:emsLevel] capitalized:YES cleaned:NO withImage:YES];
    }

    if ([section isEqual:@"Types"]) {
        [self configureCell:cell forIndexPath:indexPath fromList:self.types andCurrentList:[self.advancedSearch fieldValuesForKey:emsType] capitalized:YES cleaned:YES withImage:NO];
    }

    if ([section isEqual:@"Rooms"]) {
        [self configureCell:cell forIndexPath:indexPath fromList:self.rooms andCurrentList:[self.advancedSearch fieldValuesForKey:emsRoom] capitalized:NO cleaned:NO withImage:NO];
    }

    if ([section isEqual:@"Language"]) {
        [self configureCell:cell forIndexPath:indexPath fromList:@[@"English", @"Norwegian"] andCurrentList:[self.advancedSearch fieldValuesForKey:emsLang] capitalized:YES cleaned:NO withImage:YES];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
    NSString *section = [self.sections objectAtIndex:sectionIndex];

    return section;
}

- (void)selectRowForIndexPath:(NSIndexPath *)indexPath forList:(NSArray *)list andKey:(EMSSearchField)key {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *section = [self.sections objectAtIndex:indexPath.section];

    if ([section isEqual:@"Keywords"]) {
        [self selectRowForIndexPath:indexPath forList:self.keywords andKey:emsKeyword];
    }

    if ([section isEqual:@"Levels"]) {
        [self selectRowForIndexPath:indexPath forList:self.levels andKey:emsLevel];
    }

    if ([section isEqual:@"Types"]) {
        [self selectRowForIndexPath:indexPath forList:self.types andKey:emsType];
    }

    if ([section isEqual:@"Rooms"]) {
        [self selectRowForIndexPath:indexPath forList:self.rooms andKey:emsRoom];
    }

    if ([section isEqual:@"Language"]) {
        [self selectRowForIndexPath:indexPath forList:@[@"English", @"Norwegian"] andKey:emsLang];
    }

    [tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:searchBar afterDelay:0];
    }
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar {
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
