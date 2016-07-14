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

#import "GroupsCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface GroupsCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageGroup;
@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UILabel *labelMembers;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation GroupsCell

@synthesize imageGroup, labelName, labelMembers;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(FObject *)group
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelName.text = group[FGROUP_NAME];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	labelMembers.text = [NSString stringWithFormat:@"%ld members", [group[FGROUP_MEMBERS] count]];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadImage:(FObject *)group TableView:(UITableView *)tableView IndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *path = [DownloadManager pathImage:group[FGROUP_PICTURE]];
	if (path == nil)
	{
		imageGroup.image = [UIImage imageNamed:@"groups_blank"];
		[self downloadImage:group TableView:tableView IndexPath:indexPath];
	}
	else imageGroup.image = [[UIImage alloc] initWithContentsOfFile:path];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadImage:(FObject *)group TableView:(UITableView *)tableView IndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:group[FGROUP_PICTURE] completion:^(NSString *path, NSError *error, BOOL network)
	{
		if ((error == nil) && ([tableView.indexPathsForVisibleRows containsObject:indexPath]))
		{
			GroupsCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageGroup.image = [[UIImage alloc] initWithContentsOfFile:path];
		}
	}];
}

@end
