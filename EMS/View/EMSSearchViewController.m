//
//  EMSSearchViewController.m
//

#import "EMSSearchViewController.h"
#import "EMSTracking.h"

@interface EMSSearchViewController ()
@property(nonatomic, copy) NSArray *sections;
@end

@implementation EMSSearchViewController

static NSString *const DictionaryTitleKey = @"DictionaryTitleKey";
static NSString *const DictionaryIdKey = @"DictionaryIdKey";
static NSString *const DictionaryPredicateKey = @"DictionaryPredicateKey";
static NSString *const DictionaryMultiSelectKey = @"DictionaryMultiSelectKey";
static NSString *const DictionaryCapitalized = @"DictionaryCapitalized";
static NSString *const DictionaryCleaned = @"DictionaryCleaned";
static NSString *const DictionaryImage = @"DictionaryImage";

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *sections = [NSMutableArray array];

    if (self.keywords && [self.keywords count] > 0) {
        NSDictionary *keywords = @{DictionaryTitleKey : NSLocalizedString(@"Keywords", @"Filter View Keywords  section title"),
                DictionaryIdKey : @(emsKeyword),
                DictionaryPredicateKey : self.keywords,
                DictionaryMultiSelectKey : @NO,
                DictionaryCapitalized : @NO,
                DictionaryCleaned : @NO,
                DictionaryImage : @NO};
        [sections addObject:keywords];
    }
    if (self.levels && [self.levels count] > 0) {
        NSDictionary *levels = @{DictionaryTitleKey : NSLocalizedString(@"Levels", @"Filter View Levels section title"),
                DictionaryIdKey : @(emsLevel),
                DictionaryPredicateKey : self.levels,
                DictionaryMultiSelectKey : @YES,
                DictionaryCapitalized : @YES,
                DictionaryCleaned : @NO,
                DictionaryImage : @YES};

        [sections addObject:levels];
    }
    if (self.types && [self.types count] > 0) {
        NSDictionary *types = @{DictionaryTitleKey : NSLocalizedString(@"Types", @"Filter View Types section title"),
                DictionaryIdKey : @(emsType),
                DictionaryPredicateKey : self.types,
                DictionaryMultiSelectKey : @YES,
                DictionaryCapitalized : @YES,
                DictionaryCleaned : @YES,
                DictionaryImage : @NO};
        [sections addObject:types];
    }
    if (self.rooms && [self.rooms count] > 0) {
        NSDictionary *rooms = @{DictionaryTitleKey : NSLocalizedString(@"Rooms", @"Filter View Rooms section title"),
                DictionaryIdKey : @(emsRoom),
                DictionaryPredicateKey : self.rooms,
                DictionaryMultiSelectKey : @YES,
                DictionaryCapitalized : @NO,
                DictionaryCleaned : @NO,
                DictionaryImage : @NO};
        [sections addObject:rooms];
    }

    NSDictionary *language = @{DictionaryTitleKey : NSLocalizedString(@"Language", @"Filter View Language section title"),
            DictionaryIdKey : @(emsLang),
            DictionaryPredicateKey : @[@"English", @"Norwegian"],
            DictionaryMultiSelectKey : @YES,
            DictionaryCapitalized : @YES,
            DictionaryCleaned : @NO,
            DictionaryImage : @YES};
    [sections addObject:language];

    self.sections = sections;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [EMSTracking trackScreen:@"Search Screen"];
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

    NSArray *predicate = self.sections[sectionIndex][DictionaryPredicateKey];

    return [predicate count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell" forIndexPath:indexPath];

    NSDictionary *section = self.sections[(NSUInteger) indexPath.section];

    NSArray *predicates = section[DictionaryPredicateKey];

    NSString *value = predicates[(NSUInteger) indexPath.row];

    if (section[DictionaryCapitalized]) {
        value = [value capitalizedString];
    }

    if (section[DictionaryCleaned]) {
        value = [value stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    }

    cell.textLabel.text = value;


    EMSSearchField key = (EMSSearchField) [section[DictionaryIdKey] integerValue];

    NSSet *currentList = [self.advancedSearch fieldValuesForKey:key];

    if ([currentList containsObject:predicates[(NSUInteger) indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    if (section[DictionaryImage]) {
        cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", predicates[(NSUInteger) indexPath.row]]];
    } else {
        cell.imageView.image = nil;
    }

    /* We have to guess English here at the moment, since EMS doesn´t seem to support multiple languages for these values.*/
    cell.accessibilityLanguage = @"en";

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
    return self.sections[(NSUInteger) sectionIndex][DictionaryTitleKey];
}

- (void)selectRowForIndexPath:(NSIndexPath *)indexPath forList:(NSArray *)list andKey:(EMSSearchField)key {
    NSString *value = list[(NSUInteger) indexPath.row];

    NSMutableSet *values = [NSMutableSet setWithSet:[self.advancedSearch fieldValuesForKey:key]];

    if (![self.sections[(NSUInteger) indexPath.section][DictionaryMultiSelectKey] boolValue]) {
        [values removeAllObjects];
    }

    if ([[self.advancedSearch fieldValuesForKey:key] containsObject:value]) {
        [values removeObject:value];
    } else {
        [values addObject:value];
    }

    [self.advancedSearch setFieldValues:[NSSet setWithSet:values] forKey:key];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *predicates = self.sections[(NSUInteger) indexPath.section][DictionaryPredicateKey];
    EMSSearchField searchField = (EMSSearchField) [self.sections[(NSUInteger) indexPath.section][DictionaryIdKey] integerValue];

    [self selectRowForIndexPath:indexPath forList:predicates andKey:searchField];


    [tableView reloadData];
}


- (void)apply:(id)sender {
    [self.delegate advancedSearchUpdated];
}

- (void)clear:(id)sender {
    [self.advancedSearch clear];

    [self apply:sender];
}

@end
