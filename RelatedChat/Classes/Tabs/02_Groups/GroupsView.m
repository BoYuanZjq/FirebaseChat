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

#import "GroupsView.h"
#import "GroupsCell.h"
#import "CreateGroupView.h"
#import "GroupDetailsView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface GroupsView()
{
	BOOL seaching;
	NSMutableArray *groups;
	NSMutableArray *searches;

	UIRefreshControl *refreshControl;
}

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation GroupsView

@synthesize searchBar;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		[self.tabBarItem setImage:[UIImage imageNamed:@"tab_groups"]];
		self.tabBarItem.title = @"Groups";
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_USER_LOGGED_OUT];
	}
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Groups";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
																						   action:@selector(actionNew)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView registerNib:[UINib nibWithNibName:@"GroupsCell" bundle:nil] forCellReuseIdentifier:@"GroupsCell"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	refreshControl = [[UIRefreshControl alloc] init];
	[refreshControl addTarget:self action:@selector(loadGroups) forControlEvents:UIControlEventValueChanged];
	[self.tableView addSubview:refreshControl];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableFooterView = [[UIView alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	groups = [[NSMutableArray alloc] init];
	searches = [[NSMutableArray alloc] init];
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
			[self loadGroups];
		}
		else OnboardUser(self);
	}
	else LoginUser(self);
}

#pragma mark - Backend actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadGroups
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[Groups load:^(NSMutableArray *objects)
	{
		[groups removeAllObjects];
		[groups addObjectsFromArray:objects];
		if (seaching) [self searchGroup];
		[self.tableView reloadData];
		[refreshControl endRefreshing];
	}];
}

#pragma mark - Searching methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	seaching = YES;
	[searches removeAllObjects];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (FObject *group in groups)
	{
		NSString *text_lower = [searchBar.text lowercaseString];
		NSString *name_lower = [group[FGROUP_NAME] lowercaseString];
		if ([name_lower rangeOfString:text_lower].location != NSNotFound)
		{
			[searches addObject:group];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)stopSearching
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	seaching = NO;
	[self.tableView reloadData];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionNew
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	CreateGroupView *createGroupView = [[CreateGroupView alloc] init];
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:createGroupView];
	[self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[groups removeAllObjects];
	[searches removeAllObjects];
	[self.tableView reloadData];
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
	return seaching ? [searches count] : [groups count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	GroupsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupsCell" forIndexPath:indexPath];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FObject *group = seaching ? searches[indexPath.row] : groups[indexPath.row];
	[cell bindData:group];
	[cell loadImage:group TableView:tableView IndexPath:indexPath];
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
	FObject *group = seaching ? searches[indexPath.row] : groups[indexPath.row];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[groups removeObject:group];
	[searches removeObject:group];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[group deleteInBackground:^(NSError *error)
	{
		if (error != nil) [ProgressHUD showError:@"Network error."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FObject *group = seaching ? searches[indexPath.row] : groups[indexPath.row];
	GroupDetailsView *groupDetailsView = [[GroupDetailsView alloc] initWithGroup:group Chat:YES];
	groupDetailsView.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:groupDetailsView animated:YES];
}

#pragma mark - UISearchBarDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([searchText length] > 0)
		[self searchGroup];
	else [self stopSearching];
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
	[self stopSearching];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[searchBar resignFirstResponder];
}

@end
