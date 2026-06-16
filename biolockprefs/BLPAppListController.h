#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface BLPAppListController : PSListController <UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allApps;
@property (nonatomic, strong) NSArray *filteredApps;
@property (nonatomic, strong) UISearchBar *searchBar;
@end
