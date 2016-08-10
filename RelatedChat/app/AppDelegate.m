//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AppDelegate.h"
#import "RecentView.h"
#import "GroupsView.h"
#import "PeopleView.h"
#import "SettingsView.h"
#import "NavigationController.h"

@implementation AppDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[FIRApp configure];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
	{
		UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
		UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
		[application registerUserNotificationSettings:settings];
		[application registerForRemoteNotifications];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	// This can be removed once Firebase auth issue is resolved
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([UserDefaults boolForKey:@"Initialized"] == NO)
	{
		[UserDefaults setObject:@YES forKey:@"Initialized"];
		[FUser logOut];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.reachability = [Reachability reachabilityForInternetConnection];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	self.recentView = [[RecentView alloc] initWithNibName:@"RecentView" bundle:nil];
	self.groupsView = [[GroupsView alloc] initWithNibName:@"GroupsView" bundle:nil];
	self.peopleView = [[PeopleView alloc] initWithNibName:@"PeopleView" bundle:nil];
	self.settingsView = [[SettingsView alloc] initWithNibName:@"SettingsView" bundle:nil];

	NavigationController *navController1 = [[NavigationController alloc] initWithRootViewController:self.recentView];
	NavigationController *navController3 = [[NavigationController alloc] initWithRootViewController:self.groupsView];
	NavigationController *navController4 = [[NavigationController alloc] initWithRootViewController:self.peopleView];
	NavigationController *navController5 = [[NavigationController alloc] initWithRootViewController:self.settingsView];

	self.tabBarController = [[UITabBarController alloc] init];
	self.tabBarController.viewControllers = @[navController1, navController3, navController4, navController5];
	self.tabBarController.tabBar.translucent = NO;
	self.tabBarController.selectedIndex = DEFAULT_TAB;

	self.window.rootViewController = self.tabBarController;
	[self.window makeKeyAndVisible];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.recentView view];
	[self.groupsView view];
	[self.peopleView view];
	[self.settingsView view];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)applicationWillResignActive:(UIApplication *)application
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)applicationDidEnterBackground:(UIApplication *)application
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)applicationWillEnterForeground:(UIApplication *)application
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)applicationDidBecomeActive:(UIApplication *)application
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[FBSDKAppEvents activateApp];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	CleanupExpiredCache();
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter post:NOTIFICATION_APP_STARTED];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self locationManagerStart];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)applicationWillTerminate:(UIApplication *)application
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	
}

#pragma mark - Facebook responses

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url
												sourceApplication:sourceApplication annotation:annotation];
}

#pragma mark - Push notification methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
//-------------------------------------------------------------------------------------------------------------------------------------------------
{

}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	//NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", error);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
//-------------------------------------------------------------------------------------------------------------------------------------------------
{

}

#pragma mark - Location manager methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)locationManagerStart
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (self.locationManager == nil)
	{
		self.locationManager = [[CLLocationManager alloc] init];
		[self.locationManager setDelegate:self];
		[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
		[self.locationManager requestWhenInUseAuthorization];
	}
	[self.locationManager startUpdatingLocation];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)locationManagerStop
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self.coordinate = newLocation.coordinate;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initUserStatuses
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self initUserStatus:@"Available"];
	[self initUserStatus:@"Busy"];
	[self initUserStatus:@"At school"];
	[self initUserStatus:@"At the movies"];
	[self initUserStatus:@"At work"];
	[self initUserStatus:@"Battery about to die"];
	[self initUserStatus:@"Can't talk now"];
	[self initUserStatus:@"In a meeting"];
	[self initUserStatus:@"At the gym"];
	[self initUserStatus:@"Sleeping"];
	[self initUserStatus:@"Urgent calls only"];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initUserStatus:(NSString *)name
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *object = [FObject objectWithPath:FUSERSTATUS_PATH];
	object[FUSERSTATUS_NAME] = name;
	[object saveInBackground:^(NSError *error)
	{
		if (error != nil) NSLog(@"initUserStatus error: %@", error);
	}];
}

@end
