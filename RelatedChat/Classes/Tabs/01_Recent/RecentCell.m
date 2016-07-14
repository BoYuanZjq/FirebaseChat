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

#import "RecentCell.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface RecentCell()

@property (strong, nonatomic) IBOutlet UIImageView *imageUser;
@property (strong, nonatomic) IBOutlet UILabel *labelDescription;
@property (strong, nonatomic) IBOutlet UILabel *labelLastMessage;
@property (strong, nonatomic) IBOutlet UILabel *labelElapsed;
@property (strong, nonatomic) IBOutlet UILabel *labelCounter;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation RecentCell

@synthesize imageUser;
@synthesize labelDescription, labelLastMessage;
@synthesize labelElapsed, labelCounter;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)bindData:(FObject *)recent
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	labelDescription.text = recent[FRECENT_DESCRIPTION];
	labelLastMessage.text = [RELCryptor decryptText:recent[FRECENT_LASTMESSAGE] groupId:recent[FRECENT_GROUPID]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSDate *date = Number2Date(recent[FRECENT_UPDATEDAT]);
	NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:date];
	labelElapsed.text = TimeElapsed(seconds);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSInteger counter = [recent[FRECENT_COUNTER] integerValue];
	labelCounter.text = (counter != 0) ? [NSString stringWithFormat:@"%ld new", counter] : nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadImage:(FObject *)recent TableView:(UITableView *)tableView IndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *path = [DownloadManager pathImage:recent[FRECENT_PICTURE]];
	if (path == nil)
	{
		imageUser.image = [UIImage imageNamed:@"recent_blank"];
		[self downloadImage:recent TableView:tableView IndexPath:indexPath];
	}
	else imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadImage:(FObject *)recent TableView:(UITableView *)tableView IndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[DownloadManager image:recent[FRECENT_PICTURE] completion:^(NSString *path, NSError *error, BOOL network)
	{
		if ((error == nil) && ([tableView.indexPathsForVisibleRows containsObject:indexPath]))
		{
			RecentCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageUser.image = [[UIImage alloc] initWithContentsOfFile:path];
		}
	}];
}

@end
