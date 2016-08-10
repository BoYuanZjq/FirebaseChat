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

#import "ProfileView.h"
#import "ChatView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ProfileView()
{
	FUser *user;
	NSString *userId;
	BOOL isChatEnabled;
}

@property (strong, nonatomic) IBOutlet UIView *viewHeader;
@property (strong, nonatomic) IBOutlet UIImageView *imageUser;
@property (strong, nonatomic) IBOutlet UILabel *labelInitials;
@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UILabel *labelStatus;

@property (strong, nonatomic) IBOutlet UITableViewCell *cellCountry;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellLocation;

@property (strong, nonatomic) IBOutlet UITableViewCell *cellChat;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ProfileView

@synthesize viewHeader, imageUser, labelInitials, labelName, labelStatus;
@synthesize cellCountry, cellLocation, cellChat;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWithUser:(FUser *)user_ Chat:(BOOL)chat_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	user = user_;
	isChatEnabled = chat_;
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWithUserId:(NSString *)userId_ Chat:(BOOL)chat_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	userId = userId_;
	isChatEnabled = chat_;
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Profile";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableHeaderView = viewHeader;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (userId != nil) [self fetchUser];
	else if (user != nil) [self loadUser];
}

#pragma mark - Backend actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)fetchUser
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	user = [FUser userWithId:userId];
	[user fetchInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[self loadUser];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadUser
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelInitials.text = [user initials];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[DownloadManager image:user[FUSER_PICTURE] completion:^(NSString *path, NSError *error, BOOL network)
	{
		if (error == nil)
		{
			imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
			labelInitials.text = nil;
		}
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelName.text = user[FUSER_FULLNAME];
	labelStatus.text = user[FUSER_STATUS];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	cellCountry.detailTextLabel.text = user[FUSER_COUNTRY];
	cellLocation.detailTextLabel.text = user[FUSER_LOCATION];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView reloadData];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChat
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (user != nil)
	{
		NSDictionary *dictionary = StartPrivateChat(user);
		ChatView *chatView = [[ChatView alloc] initWith:dictionary];
		[self.navigationController pushViewController:chatView animated:YES];
	}
}

#pragma mark - Table view data source

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return 2;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (section == 0) return 2;
	if (section == 1) return 1;
	return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ((indexPath.section == 0) && (indexPath.row == 0)) return cellCountry;
	if ((indexPath.section == 0) && (indexPath.row == 1)) return cellLocation;
	if ((indexPath.section == 1) && (indexPath.row == 0)) return cellChat;
	return nil;
}

#pragma mark - Table view delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ((indexPath.section == 1) && (indexPath.row == 0))
	{
		if (isChatEnabled) [self actionChat]; else [self.navigationController popViewControllerAnimated:YES];
	}
}

@end
