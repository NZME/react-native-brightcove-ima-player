#import "UIApplication+CurrentNonAdViewController.h"

@implementation UIApplication (CurrentNonAdViewController)

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

- (UIViewController *)getVisibleNonAdViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleNonAdViewControllerFrom:[(UINavigationController *)vc visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getVisibleNonAdViewControllerFrom:[(UITabBarController *)vc selectedViewController]];
    } else if (vc.presentedViewController) {
        return [self getVisibleNonAdViewControllerFrom:vc.presentedViewController];
    } else if ([vc isKindOfClass:[UIPageViewController class]]) {
        UIPageViewController *pageViewController = (UIPageViewController *)vc;
        for (UIViewController *childVC in pageViewController.viewControllers) {
            if (childVC.view.window) {
                return [self getVisibleNonAdViewControllerFrom:childVC];
            }
        }
    } else if (vc.childViewControllers.count > 0 ) {
        // Avoid the IMAAdViewController since we cannot attached views to it.
        if(![NSStringFromClass([vc.childViewControllers.firstObject class]) isEqualToString:@"IMAAdViewController"]){
            return [self getVisibleNonAdViewControllerFrom:vc.childViewControllers.firstObject];
        }
    }
    
    return vc;
}

- (UIViewController *)currentNonAdViewController {
    UIViewController *currentViewController = [self topViewController];
    currentViewController = [self getVisibleNonAdViewControllerFrom:currentViewController];
    return currentViewController;
}

@end
