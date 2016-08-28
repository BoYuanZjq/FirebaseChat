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
NSDictionary* StartPrivateChat(FUser *user2)
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
	[RELPassword init:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Recent fetchMembers:groupId completion:^(NSMutableArray *userIds)
	{
		if ([userIds containsObject:userId1] == NO) [Recent createPrivate:userId1 GroupId:groupId Sender:user2 Members:members];
		if ([userIds containsObject:userId2] == NO) [Recent createPrivate:userId2 GroupId:groupId Sender:user1 Members:members];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return @{@"groupId":groupId, @"members":members, @"description":user2[FUSER_FULLNAME], @"type":CHAT_PRIVATE};
}

#pragma mark - Multiple Chat methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSDictionary* StartMultipleChat(NSMutableArray *users)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[users addObject:[FUser currentUser]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSMutableArray *members = [[NSMutableArray alloc] init];
	for (FUser *user in users) [members addObject:[user objectId]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSArray *sorted = [members sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	NSString *groupId = [RELChecksum md5HashOfString:[sorted componentsJoinedByString:@""]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[RELPassword init:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Recent createMultiple:groupId Members:members];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return @{@"groupId":groupId, @"members":members, @"description":@"", @"type":CHAT_MULTIPLE};
}

#pragma mark - Group Chat methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSDictionary* StartGroupChat(FObject *group)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSArray *members = group[FGROUP_MEMBERS];
	NSString *groupId = [group objectId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSString *picture = (group[FGROUP_PICTURE] != nil) ? group[FGROUP_PICTURE] : [FUser picture];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[RELPassword init:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Recent createGroup:groupId Picture:picture Description:group[FGROUP_NAME] Members:members];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return @{@"groupId":groupId, @"members":members, @"description":group[FGROUP_NAME], @"type":CHAT_GROUP};
}

#pragma mark - Restart Recent Chat methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSDictionary* RestartRecentChat(DBRecent *dbrecent)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSArray *members = [dbrecent.members componentsSeparatedByString:@","];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return @{@"groupId":dbrecent.groupId, @"members":members, @"description":dbrecent.description, @"type":dbrecent.type};
}
