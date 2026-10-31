//
//  ZBSceneDelegate.m
//  Zebra
//

#import "ZBSceneDelegate.h"
#import "ZBAppDelegate.h"

API_AVAILABLE(ios(13.0))
@implementation ZBSceneDelegate

- (ZBAppDelegate *)_appDelegate {
    return (ZBAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *rootVC = [storyboard instantiateInitialViewController];

    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];

    [ZBAppDelegate configureWindow:self.window withLaunchURL:connectionOptions.URLContexts.anyObject.URL];

    if (connectionOptions.userActivities.count > 0) {
        NSUserActivity *userActivity = [connectionOptions.userActivities anyObject];
        [self._appDelegate continueUserActivity:userActivity];
    }

    NSSet <UIOpenURLContext *> *urlContexts = connectionOptions.URLContexts;
    UIApplicationShortcutItem *shortcutItem = connectionOptions.shortcutItem;
    if (urlContexts.count > 0 || shortcutItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (urlContexts.count > 0) {
                [self _openURLContexts:urlContexts];
            }
            if (shortcutItem) {
                UIApplication *app = [UIApplication sharedApplication];
                [self._appDelegate application:app performActionForShortcutItem:shortcutItem completionHandler:^(__unused BOOL succeeded) {}];
            }
        });
    }
}

- (void)_openURLContexts:(NSSet <UIOpenURLContext *> *)urlContexts {
    UIOpenURLContext *context = urlContexts.anyObject;
    if (!context) {
        return;
    }

    NSDictionary *options = @{
        UIApplicationOpenURLOptionsOpenInPlaceKey: @(context.options.openInPlace)
    };
    UIApplication *app = [UIApplication sharedApplication];
    [self._appDelegate application:app openURL:context.URL options:options];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)urlContexts {
    [self _openURLContexts:urlContexts];
}

- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    UIApplication *app = [UIApplication sharedApplication];
    [self._appDelegate application:app performActionForShortcutItem:shortcutItem completionHandler:completionHandler];
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    [self._appDelegate continueUserActivity:userActivity];
}

@end
