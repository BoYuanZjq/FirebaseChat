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

#import <Foundation/Foundation.h>

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface Recent : NSObject
//-------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Fetch methods

+ (void)fetchRecents:(NSString *)groupId completion:(void (^)(NSMutableArray *recents))completion;
+ (void)fetchMembers:(NSString *)groupId completion:(void (^)(NSMutableArray *userIds))completion;

#pragma mark - Create methods

+ (void)createPrivate:(NSString *)userId GroupId:(NSString *)groupId Sender:(FUser *)sender Members:(NSArray *)members;

+ (void)createMultiple:(NSString *)groupId Description:(NSString *)description Members:(NSArray *)members;

+ (void)createGroup:(NSString *)groupId Picture:(NSString *)picture Description:(NSString *)description Members:(NSArray *)members;

+ (void)createItem:(NSString *)userId GroupId:(NSString *)groupId Sender:(FUser *)sender Picture:(NSString *)picture
	   Description:(NSString *)description Members:(NSArray *)members Type:(NSString *)type;

#pragma mark - Update methods

+ (void)updateLastMessage:(FObject *)message;

+ (void)updateMembers:(FObject *)group;
+ (void)updateDescription:(FObject *)group;
+ (void)updatePicture:(FObject *)group;

#pragma mark - Delete/Archive methods

+ (void)deleteItem:(NSString *)objectId;
+ (void)archiveItem:(NSString *)objectId;
+ (void)unarchiveItem:(NSString *)objectId;

#pragma mark - Clear methods

+ (void)clearCounter:(NSString *)groupId;

@end
