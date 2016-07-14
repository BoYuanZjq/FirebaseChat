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

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface AlbumManager : NSObject
//-------------------------------------------------------------------------------------------------------------------------------------------------

+ (void)loadImage:(NSString *)localIdentifier completion:(void (^)(UIImage *image))completion;
+ (void)loadVideo:(NSString *)localIdentifier completion:(void (^)(NSString *path))completion;
+ (void)loadAudio:(NSString *)localIdentifier completion:(void (^)(NSString *path))completion;

+ (void)saveImage:(NSString *)path completion:(void (^)(NSString *localIdentifier, NSError *error))completion;
+ (void)saveVideo:(NSString *)path completion:(void (^)(NSString *localIdentifier, NSError *error))completion;
+ (void)saveAudio:(NSString *)path completion:(void (^)(NSString *localIdentifier, NSError *error))completion;

+ (void)getAlbum:(void (^)(PHAssetCollection *collection))completion;
+ (void)createAlbum:(void (^)(PHAssetCollection *collection))completion;

@end
