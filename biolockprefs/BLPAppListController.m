#import "BLPAppListController.h"
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

@implementation BLPAppListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        [self loadAppList];
        _specifiers = [self buildSpecifiersFromArray:self.filteredApps];
    }
    return _specifiers;
}

- (void)loadAppList {
    NSString *cachePath = @"/var/mobile/Library/Preferences/com.batues.biolock.applist.plist";
    NSArray *cached = [NSArray arrayWithContentsOfFile:cachePath];
    
    if (!cached || cached.count == 0) {
        self.allApps = @[];
        self.filteredApps = @[];
        return;
    }
    
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    self.allApps = [cached sortedArrayUsingDescriptors:@[sortDesc]];
    self.filteredApps = self.allApps;
}

- (NSArray *)buildSpecifiersFromArray:(NSArray *)apps {
    NSMutableArray *specs = [NSMutableArray array];
    
    PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:@"选择要保护的应用"
                                                        target:self
                                                           set:NULL
                                                           get:NULL
                                                        detail:Nil
                                                          cell:PSGroupCell
                                                          edit:Nil];
    [specs addObject:group];
    
    for (NSDictionary *app in apps) {
        NSString *bundleID = app[@"bundleID"];
        NSString *name = app[@"name"];
        
        PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                           target:self
                                                              set:@selector(setProtected:forSpecifier:)
                                                              get:@selector(getProtectedForSpecifier:)
                                                           detail:Nil
                                                             cell:PSSwitchCell
                                                             edit:Nil];
        [spec setProperty:bundleID forKey:@"bundleID"];
        [spec setProperty:bundleID forKey:@"id"];
        [specs addObject:spec];
    }
    
    return [specs copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择应用";
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 56)];
    self.searchBar.placeholder = @"搜索应用名称";
    self.searchBar.delegate = self;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.tableHeaderView = self.searchBar;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.filteredApps = self.allApps;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
        self.filteredApps = [self.allApps filteredArrayUsingPredicate:predicate];
    }
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

- (id)getProtectedForSpecifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"bundleID"];
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.batues.biolock.plist";
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    NSArray *protectedApps = prefs[@"ProtectedApps"] ?: @[];
    return @([protectedApps containsObject:bundleID]);
}

- (void)setProtected:(id)value forSpecifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"bundleID"];
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.batues.biolock.plist";
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath] ?: [NSMutableDictionary dictionary];
    NSMutableArray *protectedApps = [prefs[@"ProtectedApps"] mutableCopy] ?: [NSMutableArray array];
    
    BOOL enabled = [value boolValue];
    if (enabled && ![protectedApps containsObject:bundleID]) {
        [protectedApps addObject:bundleID];
    } else if (!enabled) {
        [protectedApps removeObject:bundleID];
    }
    
    prefs[@"ProtectedApps"] = protectedApps;
    [prefs writeToFile:prefsPath atomically:YES];
    
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.batues.biolock/ReloadPrefs"),
        NULL, NULL, YES
    );
}

@end
