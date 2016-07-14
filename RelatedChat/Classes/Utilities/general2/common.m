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

//-------------------------------------------------------------------------------------------------------------------------------------------------
void PresentAudioRecorder(id target)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	IQAudioRecorderController *controller = [[IQAudioRecorderController alloc] init];
	controller.delegate = target;
	[target presentViewController:controller animated:YES completion:nil];
}

#pragma mark -

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString* Filename(NSString *type, NSString *ext)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	int interval = (int) [[NSDate date] timeIntervalSince1970];
	return [NSString stringWithFormat:@"%@/%@/%d.%@", [FUser currentId], type, interval, ext];
}

#pragma mark -

//-------------------------------------------------------------------------------------------------------------------------------------------------
void CleanupExpiredCache(void)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([FUser currentId] != nil)
	{
		if ([FUser keepMedia] == KEEPMEDIA_WEEK)
			[CacheManager cleanupExpired:7];

		if ([FUser keepMedia] == KEEPMEDIA_MONTH)
			[CacheManager cleanupExpired:30];
	}
}
