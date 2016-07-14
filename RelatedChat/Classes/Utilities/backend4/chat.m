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

#pragma mark - Private Chat methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString* StartPrivateChat(FUser *user2)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FUser *user1 = [FUser currentUser];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *userId1 = [user1 objectId];
	NSString *userId2 = [user2 objectId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *members = @[userId1, userId2];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *sorted = [members sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	NSString *groupId = [RELChecksum md5HashOfString:[sorted componentsJoinedByString:@""]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	CreateRecent(userId1, groupId, members, user2[FUSER_NAME], user2[FUSER_PICTURE], @"private");
	CreateRecent(userId2, groupId, members, user1[FUSER_NAME], user1[FUSER_PICTURE], @"private");
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return groupId;
}

#pragma mark - Multiple Chat methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString* StartMultipleChat(NSMutableArray *users)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[users addObject:[FUser currentUser]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSMutableArray *names = [[NSMutableArray alloc] init];
	NSMutableArray *members = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (FUser *user in users)
	{
		[names addObject:user[FUSER_NAME]];
		[members addObject:[user objectId]];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *sorted = [members sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	NSString *groupId = [RELChecksum md5HashOfString:[sorted componentsJoinedByString:@""]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *description = [names componentsJoinedByString:@", "];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	CreateRecents(groupId, members, description, [FUser picture], @"multiple");
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return groupId;
}

#pragma mark - Group Chat methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
void StartGroupChat(FObject *group)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *picture = (group[FGROUP_PICTURE] != nil) ? group[FGROUP_PICTURE] : [FUser picture];
	CreateRecents([group objectId], group[FGROUP_MEMBERS], group[FGROUP_NAME], picture, @"group");
}

#pragma mark - Restart Recent Chat methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
void RestartRecentChat(FObject *recent)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([recent[FRECENT_TYPE] isEqualToString:@"private"])
	{
		for (NSString *userId in recent[FRECENT_MEMBERS])
		{
			if ([userId isEqualToString:[FUser currentId]] == NO)
				CreateRecent(userId, recent[FRECENT_GROUPID], recent[FRECENT_MEMBERS], [FUser name], [FUser picture], @"private");
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([recent[FRECENT_TYPE] isEqualToString:@"multiple"])
	{
		CreateRecents(recent[FRECENT_GROUPID], recent[FRECENT_MEMBERS], recent[FRECENT_DESCRIPTION], recent[FRECENT_PICTURE], @"multiple");
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([recent[FRECENT_TYPE] isEqualToString:@"group"])
	{
		CreateRecents(recent[FRECENT_GROUPID], recent[FRECENT_MEMBERS], recent[FRECENT_DESCRIPTION], recent[FRECENT_PICTURE], @"group");
	}
}
