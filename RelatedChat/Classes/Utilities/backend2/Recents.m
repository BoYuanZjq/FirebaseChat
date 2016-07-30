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

@implementation Recents

@synthesize objects;

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (Recents *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once;
	static Recents *recents;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ recents = [[Recents alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return recents;
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
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FRECENT_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FRECENT_USERID] queryEqualToValue:[FUser currentId]];
	[query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		[[self objects] removeAllObjects];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (snapshot.exists)
		{
			NSArray *sorted = [self sort:snapshot.value];
			for (NSDictionary *dictionary in sorted)
			{
				FObject *object = [FObject objectWithPath:FRECENT_PATH dictionary:dictionary];
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
		NSTimeInterval interval1 = [dict1[FRECENT_UPDATEDAT] doubleValue];
		NSTimeInterval interval2 = [dict2[FRECENT_UPDATEDAT] doubleValue];
		return (interval1 > interval2);
	}];
}

@end
