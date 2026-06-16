#import <UIKit/UIKit.h>

@interface BLPAppListController : UITableViewController <UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allApps;
@property (nonatomic, strong) NSArray *filteredApps;
@property (nonatomic, strong) UISearchBar *searchBar;
@end
