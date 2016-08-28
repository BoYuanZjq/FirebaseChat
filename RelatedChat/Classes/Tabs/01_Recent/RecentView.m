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
	BOOL refreshTableView;
	BOOL refreshTabCounter;

	SWTableViewCell *lastCell;

	NSTimer *timer;
	RLMResults *dbrecents;
	FIRDatabaseReference *firebase;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation RecentView

@synthesize searchBar;

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
	timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(refreshViewDetails) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidAppear:animated];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([FUser currentId] != nil)
	{
		if ([FUser isOnboardOk])
		{
			
		}
		else OnboardUser(self);
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
			[self createRecentObservers];
		}
		else [self refreshTableView];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadRecents
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = searchBar.text;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isArchived == NO AND isDeleted == NO AND description CONTAINS[c] %@", text];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dbrecents = [[DBRecent objectsWithPredicate:predicate] sortedResultsUsingProperty:FRECENT_LASTMESSAGEDATE ascending:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshTabCounter];
	[self refreshTableView];
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
		NSDictionary *recent = snapshot.value;
		[RELPassword set:recent[FRECENT_PASSWORD] groupId:recent[FRECENT_GROUPID]];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		dispatch_async(dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL), ^{
			[self updateRealm:recent];
			refreshTabCounter = YES;
			refreshTableView = YES;
		});
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[query observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot)
	{
		NSDictionary *recent = snapshot.value;
		dispatch_async(dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL), ^{
			[self updateRealm:recent];
			refreshTabCounter = YES;
			refreshTableView = YES;
		});
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateRealm:(NSDictionary *)recent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:recent];
	temp[FRECENT_MEMBERS] = [recent[FRECENT_MEMBERS] componentsJoinedByString:@","];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	[DBRecent createOrUpdateInRealm:realm withValue:temp];
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)archiveRealm:(DBRecent *)dbrecent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbrecent.isArchived = YES;
	[realm commitWriteTransaction];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteRealm:(DBRecent *)dbrecent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RLMRealm *realm = [RLMRealm defaultRealm];
	[realm beginWriteTransaction];
	dbrecent.isDeleted = YES;
	[realm commitWriteTransaction];
}

#pragma mark - Refresh methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshViewDetails
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (refreshTableView)	[self refreshTableView];
	if (refreshTabCounter)	[self refreshTabCounter];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.tableView reloadData];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	refreshTableView = NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)refreshTabCounter
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSInteger total = 0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (DBRecent *dbrecent in dbrecents)
		total += dbrecent.counter;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UITabBarItem *item = self.tabBarController.tabBar.items[0];
	item.badgeValue = (total != 0) ? [NSString stringWithFormat:@"%ld", (long) total] : nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIUserNotificationSettings *currentUserNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
	if (currentUserNotificationSettings.types & UIUserNotificationTypeBadge)
		[UIApplication sharedApplication].applicationIconBadgeNumber = total;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	refreshTabCounter = NO;
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChat:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	ChatView *chatView = [[ChatView alloc] initWith:dictionary];
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

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSelectMultiple
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	SelectMultipleView *selectMultipleView = [[SelectMultipleView alloc] init];
	selectMultipleView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectMultipleView];
	[self presentViewController:navController animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionArchive:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBRecent *dbrecent = dbrecents[index];
	NSString *recentId = dbrecent.objectId;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self archiveRealm:dbrecent];
	[self refreshTabCounter];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self performSelector:@selector(delayedArchive:) withObject:recentId afterDelay:0.25];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)delayedArchive:(NSString *)recentId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.tableView reloadData];
	[Recent archiveItem:recentId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	DBRecent *dbrecent = dbrecents[index];
	NSString *recentId = dbrecent.objectId;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self deleteRealm:dbrecent];
	[self refreshTabCounter];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self performSelector:@selector(delayedDelete:) withObject:recentId afterDelay:0.25];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)delayedDelete:(NSString *)recentId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.tableView reloadData];
	[Recent deleteItem:recentId];
}

#pragma mark - SelectSingleDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectSingleUser:(FUser *)user2
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSDictionary *dictionary = StartPrivateChat(user2);
	[self actionChat:dictionary];
}

#pragma mark - SelectMultipleDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectMultipleUsers:(NSMutableArray *)users
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSDictionary *dictionary = StartMultipleChat(users);
	[self actionChat:dictionary];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase removeAllObservers]; firebase = nil;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self refreshTabCounter];
	[self refreshTableView];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	initialized = NO;
}

#pragma mark - UIScrollViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.view endEditing:YES];
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
	return [dbrecents count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	RecentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecentCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	cell.leftUtilityButtons = nil;
	cell.rightUtilityButtons = [self rightButtons];
	cell.delegate = self;
	cell.tag = indexPath.row;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	DBRecent *dbrecent = dbrecents[indexPath.row];
	[cell bindData:dbrecent];
	[cell loadImage:dbrecent TableView:tableView IndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return cell;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSArray *)rightButtons
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSMutableArray *rightUtilityButtons = [NSMutableArray new];
	[rightUtilityButtons sw_addUtilityButtonWithColor:HEXCOLOR(0x3E70A7FF) title:@"Archive"];
	[rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor redColor] title:@"Delete"];
	return rightUtilityButtons;
}

#pragma mark - SWTableViewCellDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[cell hideUtilityButtonsAnimated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (index == 0) [self actionArchive:cell.tag];
	if (index == 1) [self actionDelete:cell.tag];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (state == kCellStateRight) lastCell = cell;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return YES;
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ((lastCell == nil) || [lastCell isUtilityButtonsHidden])
	{
		DBRecent *dbrecent = dbrecents[indexPath.row];
		NSDictionary *dictionary = RestartRecentChat(dbrecent);
		[self actionChat:dictionary];
	}
	else [lastCell hideUtilityButtonsAnimated:YES];
}

#pragma mark - UISearchBarDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self loadRecents];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:YES animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar setShowsCancelButton:NO animated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	[self loadRecents];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar resignFirstResponder];
}

@end
