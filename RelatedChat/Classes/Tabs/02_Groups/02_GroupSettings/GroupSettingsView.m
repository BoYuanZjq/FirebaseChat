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

#import "GroupSettingsView.h"
#import "SelectMultipleView.h"
#import "ChatView.h"
#import "ProfileView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface GroupSettingsView()
{
	FObject *group;
	NSMutableArray *users;
}

@property (strong, nonatomic) IBOutlet UIView *viewHeader;
@property (strong, nonatomic) IBOutlet UIImageView *imageGroup;
@property (strong, nonatomic) IBOutlet UILabel *labelName;

@property (strong, nonatomic) IBOutlet UITableViewCell *cellName;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation GroupSettingsView

@synthesize viewHeader, imageGroup, labelName;
@synthesize cellName;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(FObject *)group_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	group = group_;
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	self.title = @"Group Settings";
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"groupsettings_more"]
																	  style:UIBarButtonItemStylePlain target:self action:@selector(actionMore)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.tableView.tableHeaderView = viewHeader;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	users = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadGroup];
	[self loadUsers];
}

#pragma mark - Backend actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:group[FGROUP_PICTURE] completion:^(NSString *path, NSError *error, BOOL network)
	{
		if (error == nil) imageGroup.image = [[UIImage alloc] initWithContentsOfFile:path];
	}];
	labelName.text = group[FGROUP_NAME];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadUsers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[users removeAllObjects];
	for (FUser *user in [Users objects])
	{
		if ([group[FGROUP_MEMBERS] containsObject:[user objectId]])
			[users addObject:user];
	}
	[self.tableView reloadData];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[ProgressHUD show:nil Interaction:NO];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[group deleteInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[ProgressHUD dismiss];
			[self.navigationController popViewControllerAnimated:YES];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionMore
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Add members" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionAddMembers]; }];
	UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Rename group" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionRenameGroup]; }];
	UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"Change picture" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { [self actionChangePicture]; }];
	UIAlertAction *action4 = [UIAlertAction actionWithTitle:@"Delete group" style:UIAlertActionStyleDestructive
													handler:^(UIAlertAction *action) { [self deleteGroup]; }];
	UIAlertAction *action5 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[alert addAction:action1]; [alert addAction:action2]; [alert addAction:action3]; [alert addAction:action4]; [alert addAction:action5];
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionAddMembers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	SelectMultipleView *selectMultipleView = [[SelectMultipleView alloc] init];
	selectMultipleView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectMultipleView];
	[self presentViewController:navController animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionRenameGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rename Group" message:@"Enter a new name for this Group" delegate:self
										  cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField *textField = [alert textFieldAtIndex:0];
	textField.text = group[FGROUP_NAME];
	NSDictionary *attributes = @{NSForegroundColorAttributeName:[UIColor lightGrayColor]};
	textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Name" attributes:attributes];
	[alert show];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChangePicture
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Open camera" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { PresentPhotoCamera(self, YES); }];
	UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Photo library" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) { PresentPhotoLibrary(self, YES); }];
	UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[alert addAction:action1]; [alert addAction:action2]; [alert addAction:action3];
	[self presentViewController:alert animated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionChat
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	StartGroupChat(group);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	ChatView *chatView = [[ChatView alloc] initWith:[group objectId]];
	[self.navigationController pushViewController:chatView animated:YES];
}

#pragma mark - SelectMultipleDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectMultipleUsers:(NSMutableArray *)users_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	for (FUser *user in users_)
	{
		if ([group[FGROUP_MEMBERS] containsObject:[user objectId]] == NO)
			[group[FGROUP_MEMBERS] addObject:[user objectId]];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[group saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			[self loadUsers];
			UpdateGroupMembers(group);
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - UIAlertViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (buttonIndex != alertView.cancelButtonIndex)
	{
		UITextField *textField = [alertView textFieldAtIndex:0];
		NSString *name = textField.text;
		if ([name length] != 0)
		{
			group[FGROUP_NAME] = name;
			[group saveInBackground:^(NSError *error)
			{
				if (error == nil) labelName.text = name;
				else [ProgressHUD showError:@"Network error."];
			}];
		}
		else [ProgressHUD showError:@"Group name must be specified."];
	}
}

#pragma mark - UIImagePickerControllerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIImage *image = info[UIImagePickerControllerEditedImage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIImage *imagePicture = [RELImage square:image size:100];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataPicture = UIImageJPEGRepresentation(imagePicture, 0.6);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"group", @"jpg")];
	[reference putData:dataPicture metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		if (error == nil)
		{
			group[FGROUP_PICTURE] = metadata.downloadURL.absoluteString;
			[group saveInBackground:^(NSError *error)
			{
				if (error == nil) imageGroup.image = imagePicture;
				else [ProgressHUD showError:@"Network error."];
			}];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[picker dismissViewControllerAnimated:YES completion:nil];
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
	if (section == 0) return 1;
	if (section == 1) return [users count];
	return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (section == 0) return nil;
	if (section == 1) return [self titleForUsersHeader];
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ((indexPath.section == 0) && (indexPath.row == 0)) return cellName;
	if (indexPath.section == 1)
	{
		return [self tableView:tableView cellForRowAtIndexPath1:indexPath];
	}
	return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath1:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];

	FUser *user = users[indexPath.row];
	cell.textLabel.text = user[FUSER_NAME];

	return cell;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (indexPath.section == 1)
	{
		FUser *user = users[indexPath.row];
		return ([user isCurrent] == NO);
	}
	return NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FUser *user = users[indexPath.row];
	[users removeObject:user];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[group[FGROUP_MEMBERS] removeObject:[user objectId]];
	[group saveInBackground:^(NSError *error)
	{
		if (error == nil) UpdateGroupMembers(group);
		else [ProgressHUD showError:@"Network error."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self.tableView headerViewForSection:1].textLabel.text = [self titleForUsersHeader];
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
	if ((indexPath.section == 0) && (indexPath.row == 0)) [self actionChat];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (indexPath.section == 1)
	{
		FUser *user = users[indexPath.row];
		if ([user isCurrent] == NO)
		{
			ProfileView *profileView = [[ProfileView alloc] initWith:nil User:user];
			[self.navigationController pushViewController:profileView animated:YES];
		}
		else [ProgressHUD showSuccess:@"This is you."];
	}
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)titleForUsersHeader
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = ([users count] > 1) ? @"MEMBERS" : @"MEMBER";
	return [NSString stringWithFormat:@"%ld %@", [users count], text];
}

@end
