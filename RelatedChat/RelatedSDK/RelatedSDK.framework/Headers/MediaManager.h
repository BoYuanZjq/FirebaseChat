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
#import <UIKit/UIKit.h>

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface MediaManager : NSObject
//-------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Picture

+ (void)loadPicture:(id)mediaItem message:(id)message user:(id)user wifi:(BOOL)wifi collectionView:(UICollectionView *)collectionView;

+ (void)loadPictureManual:(id)mediaItem message:(id)message user:(id)user collectionView:(UICollectionView *)collectionView;

#pragma mark - Video

+ (void)loadVideo:(id)mediaItem message:(id)message user:(id)user wifi:(BOOL)wifi collectionView:(UICollectionView *)collectionView;

+ (void)loadVideoManual:(id)mediaItem message:(id)message user:(id)user collectionView:(UICollectionView *)collectionView;

#pragma mark - Audio

+ (void)loadAudio:(id)mediaItem message:(id)message user:(id)user wifi:(BOOL)wifi collectionView:(UICollectionView *)collectionView;

+ (void)loadAudioManual:(id)mediaItem message:(id)message user:(id)user collectionView:(UICollectionView *)collectionView;

@end
