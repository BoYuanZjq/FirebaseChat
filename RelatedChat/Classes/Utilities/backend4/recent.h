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
void			CreateRecent			(NSString *userId, NSString *groupId, NSArray *members, NSString *desc, NSString *profile, NSString *type);
void			CreateRecents			(NSString *groupId, NSArray *members, NSString *desc, NSString *profile, NSString *type);
void			CreateRecentItem		(NSString *userId, NSString *groupId, NSArray *members, NSString *desc, NSString *profile, NSString *type);

//-------------------------------------------------------------------------------------------------------------------------------------------------
void			UpdateRecents			(NSString *groupId, NSString *lastMessage);
void			UpdateRecentItem		(FObject *recent, NSString *lastMessage);

void			UpdateGroupMembers		(FObject *group);
void			UpdateRecentMembers		(FObject *recent, NSArray *members);

//-------------------------------------------------------------------------------------------------------------------------------------------------
void			ClearRecentCounter		(NSString *groupId);
