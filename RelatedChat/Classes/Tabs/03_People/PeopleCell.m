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

#import "PeopleCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface PeopleCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageUser;
@property (strong, nonatomic) IBOutlet UILabel *labelInitials;
@property (strong, nonatomic) IBOutlet UILabel *labelName;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation PeopleCell

@synthesize imageUser, labelInitials, labelName;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(FUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelName.text = user[FUSER_FULLNAME];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadImage:(FUser *)user TableView:(UITableView *)tableView IndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *path = [DownloadManager pathImage:user[FUSER_PICTURE]];
	if (path == nil)
	{
		imageUser.image = [UIImage imageNamed:@"people_blank"];
		labelInitials.text = [user initials];
		[self downloadImage:user TableView:tableView IndexPath:indexPath];
	}
	else
	{
		imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
		labelInitials.text = nil;
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadImage:(FUser *)user TableView:(UITableView *)tableView IndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:user[FUSER_PICTURE] completion:^(NSString *path, NSError *error, BOOL network)
	{
		if ((error == nil) && ([tableView.indexPathsForVisibleRows containsObject:indexPath]))
		{
			PeopleCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
			cell.labelInitials.text = nil;
		}
	}];
}

@end
