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
void SendPushNotification1(FObject *message)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *groupId = message[FMESSAGE_GROUPID];
	NSString *text = [RELCryptor decryptText:message[FMESSAGE_TEXT] groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Recent fetchMembers:groupId completion:^(NSMutableArray *userIds)
	{
		[userIds removeObject:[FUser currentId]];
		SendPushNotification2(userIds, text);
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void SendPushNotification2(NSArray *userIds, NSString *text)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	//for (NSString *userId in userIds)
	//{
	//	NSLog(@"SendPushNotification2: %@ - %@", userId, text);
	//}
}
