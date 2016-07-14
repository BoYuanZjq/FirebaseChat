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

@implementation UserStatuses

@synthesize objects;

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (UserStatuses *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once = 0;
	static UserStatuses *userStatuses;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ userStatuses = [[UserStatuses alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return userStatuses;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)init
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	objects = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSMutableArray *)objects
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [self shared].objects;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)load:(void (^)(NSMutableArray *objects))completion
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FUSERSTATUS_PATH];
	[firebase observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		[[self objects] removeAllObjects];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (snapshot.exists)
		{
			NSArray *sorted = [self sort:snapshot.value];
			for (NSDictionary *dictionary in sorted)
			{
				FObject *object = [FObject objectWithPath:FUSERSTATUS_PATH dictionary:dictionary];
				[[self objects] addObject:object];
			}
		}
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (completion != nil) completion([self objects]);
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSArray *)sort:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSArray *array = [dictionary allValues];
	return [array sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
	{
		NSDictionary *dict1 = (NSDictionary *)obj1;
		NSDictionary *dict2 = (NSDictionary *)obj2;
		NSTimeInterval interval1 = [dict1[FUSERSTATUS_CREATEDAT] doubleValue];
		NSTimeInterval interval2 = [dict2[FUSERSTATUS_CREATEDAT] doubleValue];
		return (interval1 > interval2);
	}];
}

@end
