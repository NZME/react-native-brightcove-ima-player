#import <XCTest/XCTest.h>
#import "UIApplication+CurrentViewController.h"

@interface UIApplication_CurrentViewControllerTests : XCTestCase

@property (nonatomic, strong) UIWindow *window;

@end

@implementation UIApplication_CurrentViewControllerTests

- (void)setUp {
    [super setUp];
    
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [[UIApplication sharedApplication] connectedScenes]) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        self.window = window;
                        break;
                    }
                }
                if (self.window) {
                    break;
                }
            }
        }
    } else {
        self.window = [UIApplication sharedApplication].keyWindow;
    }
    
    self.window.hidden = NO;
}

- (void)tearDown {
    self.window = nil;
    [super tearDown];
}

- (void)testTopViewController {
    UIViewController *rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    UIViewController *topViewController = [[UIApplication sharedApplication] topViewController];
    XCTAssertEqual(topViewController, rootViewController, @"Top view controller should be the root view controller");
}

- (void)testCurrentViewControllerWithNavigationController {
    UIViewController *rootViewController = [[UIViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    
    UIViewController *currentViewController = [[UIApplication sharedApplication] currentViewController];
    XCTAssertEqual(currentViewController, rootViewController, @"Current view controller should be the root view controller of the navigation controller");
    
    UIViewController *secondViewController = [[UIViewController alloc] init];
    [navController pushViewController:secondViewController animated:NO];
    
    currentViewController = [[UIApplication sharedApplication] currentViewController];
    XCTAssertEqual(currentViewController, secondViewController, @"Current view controller should be the top view controller of the navigation controller");
}

- (void)testCurrentViewControllerWithTabBarController {
    UIViewController *firstViewController = [[UIViewController alloc] init];
    UIViewController *secondViewController = [[UIViewController alloc] init];
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[firstViewController, secondViewController];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    tabBarController.selectedIndex = 1;
    UIViewController *currentViewController = [[UIApplication sharedApplication] currentViewController];
    XCTAssertEqual(currentViewController, secondViewController, @"Current view controller should be the selected view controller of the tab bar controller");
}

- (void)testCurrentViewControllerWithPresentedViewController {
    UIViewController *rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    UIViewController *presentedViewController = [[UIViewController alloc] init];
    [rootViewController presentViewController:presentedViewController animated:NO completion:nil];
    
    UIViewController *currentViewController = [[UIApplication sharedApplication] currentViewController];
    XCTAssertEqual(currentViewController, presentedViewController, @"Current view controller should be the presented view controller");
}
@end
