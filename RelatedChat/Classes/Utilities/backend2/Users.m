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

@implementation Users

@synthesize objects;

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (Users *)shared
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	static dispatch_once_t once;
	static Users *users;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	dispatch_once(&once, ^{ users = [[Users alloc] init]; });
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return users;
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
	[[self objects] removeAllObjects];
	[self lastId:^(NSString *lastId)
	{
		[self load:lastId completion:completion];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)lastId:(void (^)(NSString *lastId))completion
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FUSER_PATH];
	FIRDatabaseQuery *query = [[firebase queryOrderedByChild:FUSER_NAME_LOWER] queryLimitedToLast:1];
	[query observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot)
	{
		NSDictionary *dictionary = snapshot.value;
		if (completion != nil) completion(dictionary[FUSER_OBJECTID]);
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (void)load:(NSString *)lastId completion:(void (^)(NSMutableArray *objects))completion
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FIRDatabaseReference *firebase = [[FIRDatabase database] referenceWithPath:FUSER_PATH];
	FIRDatabaseQuery *query = [firebase queryOrderedByChild:FUSER_NAME_LOWER];
	[query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot)
	{
		FUser *user = [[FUser alloc] initWithPath:FUSER_PATH dictionary:snapshot.value];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[[self objects] addObject:user];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		if ([[user objectId] isEqualToString:lastId])
		{
			[firebase removeAllObservers];
			if (completion != nil) completion([self objects]);
		}
	}];
}

@end
