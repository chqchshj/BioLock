#import "BLPRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <AudioToolbox/AudioServices.h>
#import <CoreFoundation/CFNotificationCenter.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@implementation BLPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Face ID 应用锁";

    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

- (void)clearAuthCache:(id)sender {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"清除缓存"
                                        message:@"将要求所有受保护的应用重新进行身份验证，并重置计时器。是否继续？"
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"清除"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.batues.biolock/ClearCache"),
            NULL,
            NULL,
            YES
        );

        [self showCompletionAlert:@"身份验证缓存已清除。"];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetSettings:(id)sender {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"重置设置"
                                        message:@"将所有设置恢复为默认值。此操作不可撤销。"
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"重置"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        NSString *prefsPath = @"/var/mobile/Library/Preferences/com.batues.biolock.plist";
        [[NSFileManager defaultManager] removeItemAtPath:prefsPath error:nil];

        CFStringRef appID = CFSTR("com.batues.biolock");
        CFPreferencesAppSynchronize(appID);

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.batues.biolock/ReloadPrefs"),
            NULL,
            NULL,
            YES
        );

        [self reloadSpecifiers];
        [self showCompletionAlert:@"所有设置已恢复为默认值。"];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openGitHub:(id)sender {
    NSString *urlString = @"https://github.com/chqchshj/BioLock";
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)showCompletionAlert:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"成功"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"好的"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
