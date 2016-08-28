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

#import "utilities.h"

#import "WelcomeView.h"
#import "EditProfileView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
void LogoutUser(void)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ResignOneSignalId();
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser logOut])
	{
		[CacheManager cleanupManual];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		RLMRealm *realm = [RLMRealm defaultRealm];
		[realm beginWriteTransaction];
		[realm deleteAllObjects];
		[realm commitWriteTransaction];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[NotificationCenter post:NOTIFICATION_USER_LOGGED_OUT];
	}
	else [ProgressHUD showError:@"Network error."];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void LoginUser(id target)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	WelcomeView *welcomeView = [[WelcomeView alloc] init];
	[target presentViewController:welcomeView animated:YES completion:^{
		UIViewController *view = (UIViewController *)target;
		[view.tabBarController setSelectedIndex:DEFAULT_TAB];
	}];
}

#pragma mark -

//-------------------------------------------------------------------------------------------------------------------------------------------------
void OnboardUser(id target)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:[[EditProfileView alloc] initWith:YES]];
	[target presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark -

//-------------------------------------------------------------------------------------------------------------------------------------------------
void UserLoggedIn(NSString *loginMethod)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UpdateOneSignalId();
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UpdateUserSettings(loginMethod);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter post:NOTIFICATION_USER_LOGGED_IN];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser isOnboardOk])
		[ProgressHUD showSuccess:@"Welcome back!"];
	else [ProgressHUD showSuccess:@"Welcome!"];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void UpdateUserSettings(NSString *loginMethod)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	BOOL update = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FUser *user = [FUser currentUser];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (user[FUSER_LOGINMETHOD] == nil)		{	update = YES;	user[FUSER_LOGINMETHOD] = loginMethod;			}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (user[FUSER_KEEPMEDIA] == nil)		{	update = YES;	user[FUSER_KEEPMEDIA] = @(KEEPMEDIA_FOREVER);	}
	if (user[FUSER_NETWORKIMAGE] == nil)	{	update = YES;	user[FUSER_NETWORKIMAGE] = @(NETWORK_ALL);		}
	if (user[FUSER_NETWORKVIDEO] == nil)	{	update = YES;	user[FUSER_NETWORKVIDEO] = @(NETWORK_ALL);		}
	if (user[FUSER_NETWORKAUDIO] == nil)	{	update = YES;	user[FUSER_NETWORKAUDIO] = @(NETWORK_ALL);		}
	if (user[FUSER_AUTOSAVEMEDIA] == nil)	{	update = YES;	user[FUSER_AUTOSAVEMEDIA] = @NO;				}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (update) [user saveInBackground];
}

#pragma mark -

//-------------------------------------------------------------------------------------------------------------------------------------------------
void UpdateOneSignalId(void)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([FUser currentId] != nil)
	{
		if ([UserDefaults stringForKey:@"OneSignalId"] != nil)
			AssignOneSignalId();
		else ResignOneSignalId();
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void AssignOneSignalId(void)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FUser *user = [FUser currentUser];
	user[FUSER_ONESIGNALID] = [UserDefaults stringForKey:@"OneSignalId"];
	[user saveInBackground];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void ResignOneSignalId(void)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FUser *user = [FUser currentUser];
	user[FUSER_ONESIGNALID] = @"";
	[user saveInBackground];
}
