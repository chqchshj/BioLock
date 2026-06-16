#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface BLPAppListController : PSListController
@property (nonatomic, strong) NSArray *allApps;
@property (nonatomic, strong) NSArray *filteredApps;
@end
