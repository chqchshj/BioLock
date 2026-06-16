#import "BLPAppListController.h"

@implementation BLPAppListController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择应用";
    
    [self loadAppList];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 56)];
    self.searchBar.placeholder = @"搜索应用名称";
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
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

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        self.filteredApps = self.allApps;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
        self.filteredApps = [self.allApps filteredArrayUsingPredicate:predicate];
    }
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredApps.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"选择要保护的应用";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"AppCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    NSDictionary *app = self.filteredApps[indexPath.row];
    NSString *bundleID = app[@"bundleID"];
    NSString *name = app[@"name"];
    
    cell.textLabel.text = name;
    cell.detailTextLabel.text = bundleID;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    // Check if this app is protected
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.batues.biolock.plist";
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    NSArray *protectedApps = prefs[@"ProtectedApps"] ?: @[];
    BOOL isProtected = [protectedApps containsObject:bundleID];
    
    // Add switch
    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.on = isProtected;
    toggle.tag = indexPath.row;
    [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    
    return cell;
}

- (void)switchChanged:(UISwitch *)sender {
    NSInteger row = sender.tag;
    NSDictionary *app = self.filteredApps[row];
    NSString *bundleID = app[@"bundleID"];
    
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.batues.biolock.plist";
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:prefsPath] ?: [NSMutableDictionary dictionary];
    NSMutableArray *protectedApps = [prefs[@"ProtectedApps"] mutableCopy] ?: [NSMutableArray array];
    
    if (sender.on && ![protectedApps containsObject:bundleID]) {
        [protectedApps addObject:bundleID];
    } else if (!sender.on) {
        [protectedApps removeObject:bundleID];
    }
    
    prefs[@"ProtectedApps"] = protectedApps;
    [prefs writeToFile:prefsPath atomically:YES];
    
    // Notify Tweak to reload
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.batues.biolock/ReloadPrefs"),
        NULL, NULL, YES
    );
}

@end
