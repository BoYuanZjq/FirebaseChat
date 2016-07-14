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

#import "RecentView.h"
#import "RecentCell.h"
#import "ChatView.h"
#import "SelectSingleView.h"
#import "SelectMultipleView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface RecentView()
{
	BOOL initialized;
	FIRDatabaseReference *firebase;

	NSMutableArray *recents;
	NSMutableArray *recentIds;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation RecentView

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	{
		[self.tabBarItem setImage:[UIImage imageNamed:@"tab_recent"]];
		self.tabBarItem.title = @"Recent";
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[NotificationCenter addObserver:self selector:@selector(initRecents) name:NOTIFICATION_APP_STARTED];
		[NotificationCenter addObserver:self selector:@selector(initRecents) name:NOTIFICATION_USER_LOGGED_IN];
		[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_USER_LOGGED_OUT];
	}
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Recent";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self
																						   action:@selector(actionCompose)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"RecentCell" bundle:nil] forCellReuseIdentifier:@"RecentCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CGFLOAT_MIN)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	recents = [[NSMutableArray alloc] init];
	recentIds = [[NSMutableArray alloc] init];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser currentId] != nil)
	{

	}
	else LoginUser(self);
}

#pragma mark - Backend methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)initRecents
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([FUser currentId] != nil)
	{
		if (initialized == NO)
		{
			initialized = YES;
			[self loadRecents];
		}
		else [self.tableView reloadData];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadRecents
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[Recents load:^(NSMutableArray *objects)
	{
		for (FObject *recent in objects)
			[self insertRecent:recent];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[self.tableView reloadData];
		[self updateTabCounter];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[self createRecentObservers];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createRecentObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	firebase = [[FIRDatabase database] referenceWithPath:FRECENT_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FRECENT_USERID] queryEqualToValue:[FUser currentId]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot)
	{
		FObject *recent = [FObject objectWithPath:FRECENT_PATH dictionary:snapshot.value];
		if ([recentIds containsObject:recent[FRECENT_GROUPID]] == NO)
		{
			[self insertRecent:recent];
			[self.tableView reloadData];
			[self updateTabCounter];
		}
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[query observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot)
	{
		FObject *recent = [FObject objectWithPath:FRECENT_PATH dictionary:snapshot.value];
		[self removeRecent:recent];
		[self insertRecent:recent];
		[self.tableView reloadData];
		[self updateTabCounter];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[query observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot)
	{
		FObject *recent = [FObject objectWithPath:FRECENT_PATH dictionary:snapshot.value];
		[self removeRecent:recent];
		[self.tableView reloadData];
		[self updateTabCounter];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)insertRecent:(FObject *)recent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[recents insertObject:recent atIndex:0];
	[recentIds insertObject:recent[FRECENT_GROUPID] atIndex:0];
	[RELPassword set:recent[FRECENT_PASSWORD] groupId:recent[FRECENT_GROUPID]];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)removeRecent:(FObject *)recent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	for (FObject *temp in recents)
	{
		if ([[recent objectId] isEqualToString:[temp objectId]])
		{
			[recents removeObject:temp];
			[recentIds removeObject:recent[FRECENT_GROUPID]];
			break;
		}
	}
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateTabCounter
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSInteger total = 0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (FObject *recent in recents)
	{
		total += [recent[FRECENT_COUNTER] integerValue];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UITabBarItem *item = self.tabBarController.tabBar.items[0];
	item.badgeValue = (total != 0) ? [NSString stringWithFormat:@"%ld", total] : nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIUserNotificationSettings *currentUserNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
	if (currentUserNotificationSettings.types & UIUserNotificationTypeBadge)
	{
		[UIApplication sharedApplication].applicationIconBadgeNumber = total;
	}
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChat:(NSString *)groupId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ChatView *chatView = [[ChatView alloc] initWith:groupId];
	chatView.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:chatView animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCompose
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Single recipient" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionSelectSingle]; }];
	UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Multiple recipients" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionSelectMultiple]; }];
	UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[alert addAction:action1]; [alert addAction:action2]; [alert addAction:action3];
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSelectSingle
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	SelectSingleView *selectSingleView = [[SelectSingleView alloc] init];
	selectSingleView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectSingleView];
	[self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - SelectSingleDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectSingleUser:(FUser *)user2
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = StartPrivateChat(user2);
	[self actionChat:groupId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSelectMultiple
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	SelectMultipleView *selectMultipleView = [[SelectMultipleView alloc] init];
	selectMultipleView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectMultipleView];
	[self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - SelectMultipleDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectMultipleUsers:(NSMutableArray *)users
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = StartMultipleChat(users);
	[self actionChat:groupId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase removeAllObservers]; firebase = nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[recents removeAllObjects];
	[recentIds removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
	[self updateTabCounter];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	initialized = NO;
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 1;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [recents count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RecentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[cell bindData:recents[indexPath.row]];
	[cell loadImage:recents[indexPath.row] TableView:tableView IndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return cell;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *recent = recents[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self removeRecent:recent];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self updateTabCounter];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self performSelector:@selector(delayedDeleteRecentItem:) withObject:recent afterDelay:0.5];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)delayedDeleteRecentItem:(FObject *)recent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[recent deleteInBackground:^(NSError *error)
	{
		if (error != nil) [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FObject *recent = recents[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	RestartRecentChat(recent);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self actionChat:recent[FRECENT_GROUPID]];
}

@end
