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

#pragma mark - Create Recent methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
void CreateRecent(NSString *userId, NSString *groupId, NSArray *members, NSString *description, NSString *picture, NSString *type)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[RELPassword init:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FRECENT_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FRECENT_GROUPID] queryEqualToValue:groupId];
	[query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		BOOL create = YES;
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (snapshot.exists)
		{
			for (NSDictionary *dictionary in [snapshot.value allValues])
			{
				if ([dictionary[FRECENT_USERID] isEqualToString:userId]) create = NO;
			}
		}
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (create) CreateRecentItem(userId, groupId, members, description, picture, type);
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void CreateRecents(NSString *groupId, NSArray *members, NSString *description, NSString *picture, NSString *type)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[RELPassword init:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FRECENT_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FRECENT_GROUPID] queryEqualToValue:groupId];
	[query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		NSMutableArray *createIds = [[NSMutableArray alloc] initWithArray:members];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (snapshot.exists)
		{
			for (NSDictionary *dictionary in [snapshot.value allValues])
			{
				FObject *recent = [FObject objectWithPath:FRECENT_PATH dictionary:dictionary];
				if ([members containsObject:recent[FRECENT_USERID]])
				{
					UpdateRecentMembers(recent, members);
					[createIds removeObject:recent[FRECENT_USERID]];
				}
				else [recent deleteInBackground];
			}
		}
		//-----------------------------------------------------------------------------------------------------------------------------------------
		for (NSString *userId in createIds)
		{
			CreateRecentItem(userId, groupId, members, description, picture, type);
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void CreateRecentItem(NSString *userId, NSString *groupId, NSArray *members, NSString *description, NSString *picture, NSString *type)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *recent = [FObject objectWithPath:FRECENT_PATH];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	recent[FRECENT_USERID] = userId;
	recent[FRECENT_GROUPID] = groupId;
	recent[FRECENT_PICTURE] = (picture != nil) ? picture : @"";
	recent[FRECENT_MEMBERS] = members;
	recent[FRECENT_DESCRIPTION] = description;
	recent[FRECENT_LASTMESSAGE] = @"";
	recent[FRECENT_COUNTER] = @0;
	recent[FRECENT_TYPE] = type;
	recent[FRECENT_PASSWORD] = [RELPassword get:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[recent saveInBackground];
}

#pragma mark - Update Recent methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
void UpdateRecents(NSString *groupId, NSString *lastMessage)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FRECENT_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FRECENT_GROUPID] queryEqualToValue:groupId];
	[query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		if (snapshot.exists)
		{
			for (NSDictionary *dictionary in [snapshot.value allValues])
			{
				FObject *recent = [FObject objectWithPath:FRECENT_PATH dictionary:dictionary];
				UpdateRecentItem(recent, lastMessage);
			}
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void UpdateRecentItem(FObject *recent, NSString *lastMessage)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSInteger counter = [recent[FRECENT_COUNTER] integerValue];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([recent[FRECENT_USERID] isEqualToString:[FUser currentId]] == NO) counter++;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	recent[FRECENT_COUNTER] = @(counter);
	recent[FRECENT_LASTMESSAGE] = lastMessage;
	[recent saveInBackground];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void UpdateGroupMembers(FObject *group)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FRECENT_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FRECENT_GROUPID] queryEqualToValue:[group objectId]];
	[query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		if (snapshot.exists)
		{
			for (NSDictionary *dictionary in [snapshot.value allValues])
			{
				FObject *recent = [FObject objectWithPath:FRECENT_PATH dictionary:dictionary];
				if ([group[FGROUP_MEMBERS] containsObject:recent[FRECENT_USERID]])
				{
					UpdateRecentMembers(recent, group[FGROUP_MEMBERS]);
				}
				else [recent deleteInBackground];
			}
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
void UpdateRecentMembers(FObject *recent, NSArray *members)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSSet *set1 = [NSSet setWithArray:members];
	NSSet *set2 = [NSSet setWithArray:recent[FRECENT_MEMBERS]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([set1 isEqualToSet:set2] == NO)
	{
		recent[FRECENT_MEMBERS] = members;
		[recent saveInBackground];
	}
}

#pragma mark - Clear Recent Counter methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
void ClearRecentCounter(NSString *groupId)
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FRECENT_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FRECENT_GROUPID] queryEqualToValue:groupId];
	[query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		if (snapshot.exists)
		{
			for (NSDictionary *dictionary in [snapshot.value allValues])
			{
				FObject *recent = [FObject objectWithPath:FRECENT_PATH dictionary:dictionary];
				if ([recent[FRECENT_USERID] isEqualToString:[FUser currentId]])
				{
					recent[FRECENT_COUNTER] = @0;
					[recent saveInBackground];
				}
			}
		}
	}];
}
