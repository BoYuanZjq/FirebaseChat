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

@implementation Groups

@synthesize objects;

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (Groups *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once = 0;
	static Groups *groups;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ groups = [[Groups alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return groups;
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
	FIRDatabaseReference *firebase = [[[FIRDatabase database] referenceWithPath:FGROUP_PATH] child:[FUser currentId]];
	[firebase observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		[[self objects] removeAllObjects];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (snapshot.exists)
		{
			NSArray *sorted = [self sort:snapshot.value];
			for (NSDictionary *dictionary in sorted)
			{
				FObject *object = [FObject objectWithPath:FGROUP_PATH Subpath:[FUser currentId] dictionary:dictionary];
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
		NSString *name1 = dict1[FGROUP_NAME];
		NSString *name2 = dict2[FGROUP_NAME];
		return [name1 caseInsensitiveCompare:name2];
	}];
}

@end
