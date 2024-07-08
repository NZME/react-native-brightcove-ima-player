#import "UIApplication+CurrentViewController.h"

@implementation UIApplication (CurrentViewController)

- (UIViewController *)topViewController {
    UIViewController *topViewController = nil;
    
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [[UIApplication sharedApplication] connectedScenes]) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        topViewController = window.rootViewController;
                        break;
                    }
                }
                if (topViewController) {
                    break;
                }
            }
        }
    } else {
        topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    
    return topViewController;
}

- (UIViewController *)getVisibleViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleViewControllerFrom:[(UINavigationController *)vc visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getVisibleViewControllerFrom:[(UITabBarController *)vc selectedViewController]];
    } else if (vc.presentedViewController) {
        return [self getVisibleViewControllerFrom:vc.presentedViewController];
    } else if ([vc isKindOfClass:[UIPageViewController class]]) {
        UIPageViewController *pageViewController = (UIPageViewController *)vc;
        for (UIViewController *childVC in pageViewController.viewControllers) {
            if (childVC.view.window) {
                return [self getVisibleViewControllerFrom:childVC];
            }
        }
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)vc;
        UIViewController *visibleVC = splitViewController.viewControllers.lastObject; // Get the secondary view controller
        if (visibleVC.view.window) {
            return [self getVisibleViewControllerFrom:visibleVC];
        }
        UIViewController *primaryVC = splitViewController.viewControllers.firstObject; // Get the primary view controller
        if (primaryVC.view.window) {
            return [self getVisibleViewControllerFrom:primaryVC];
        }
    } else if (vc.childViewControllers.count > 0) {
        return [self getVisibleViewControllerFrom:vc.childViewControllers.firstObject];
    }
    
    return vc;
}

- (UIViewController *)currentViewController {
    UIViewController *currentViewController = [self topViewController];
    currentViewController = [self getVisibleViewControllerFrom:currentViewController];
    return currentViewController;
}

@end


