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

#import "AppConstant.h"

#import "FUser+Util.h"

@implementation FUser (Util)

#pragma mark - Class methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSString *)name					{	return [[FUser currentUser] name];						}
+ (NSString *)picture				{	return [[FUser currentUser] picture];					}
+ (NSString *)loginMethod			{	return [[FUser currentUser] loginMethod];				}
//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (NSInteger)keepMedia				{	return [[FUser currentUser] keepMedia];					}
+ (NSInteger)networkImage			{	return [[FUser currentUser] networkImage];				}
+ (NSInteger)networkVideo			{	return [[FUser currentUser] networkVideo];				}
+ (NSInteger)networkAudio			{	return [[FUser currentUser] networkAudio];				}
//-------------------------------------------------------------------------------------------------------------------------------------------------
+ (BOOL)autoSaveMedia				{	return [[FUser currentUser] autoSaveMedia];				}
//-------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Instance methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)name					{	return self[FUSER_NAME];								}
- (NSString *)picture				{	return self[FUSER_PICTURE];								}
- (NSString *)loginMethod			{	return self[FUSER_LOGINMETHOD];							}
//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)keepMedia				{	return [self[FUSER_KEEPMEDIA] integerValue];			}
- (NSInteger)networkImage			{	return [self[FUSER_NETWORKIMAGE] integerValue];			}
- (NSInteger)networkVideo			{	return [self[FUSER_NETWORKVIDEO] integerValue];			}
- (NSInteger)networkAudio			{	return [self[FUSER_NETWORKAUDIO] integerValue];			}
//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)autoSaveMedia				{	return [self[FUSER_AUTOSAVEMEDIA] boolValue];			}
//-------------------------------------------------------------------------------------------------------------------------------------------------

@end
