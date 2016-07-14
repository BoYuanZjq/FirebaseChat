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

@implementation Messages

@synthesize objects;

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (Messages *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once = 0;
	static Messages *messages;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ messages = [[Messages alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return messages;
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
+ (void)load:(NSString *)groupId completion:(void (^)(NSMutableArray *objects))completion
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[[FIRDatabase database] referenceWithPath:FMESSAGE_PATH] child:groupId];
	[firebase observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		[[self objects] removeAllObjects];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if (snapshot.exists)
		{
			NSArray *sorted = [self sort:snapshot.value];
			for (NSDictionary *dictionary in sorted)
			{
				FObject *object = [FObject objectWithPath:FMESSAGE_PATH Subpath:groupId dictionary:dictionary];
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
		NSTimeInterval interval1 = [dict1[FMESSAGE_CREATEDAT] doubleValue];
		NSTimeInterval interval2 = [dict2[FMESSAGE_CREATEDAT] doubleValue];
		return (interval1 > interval2);
	}];
}

@end
