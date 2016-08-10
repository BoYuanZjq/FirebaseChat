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

#import "EmojiMediaItem.h"
#import "JSQLocationMediaItem.h"

#import "Incoming.h"
#import "AppDelegate.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface Incoming()
{
	NSString *senderId;
	NSString *senderName;
	NSDate *date;

	BOOL wifi;
	BOOL maskOutgoing;

	FObject *message;
	JSQMessagesCollectionView *collectionView;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation Incoming

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(FObject *)message_ CollectionView:(JSQMessagesCollectionView *)collectionView_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message = message_;
	collectionView = collectionView_;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
	wifi = [app.reachability isReachableViaWiFi];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)createMessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	senderId = message[FMESSAGE_SENDERID];
	senderName = message[FMESSAGE_SENDERNAME];
	date = Number2Date(message[FMESSAGE_CREATEDAT]);
	//---------------------------------------------------------------------------------------------------------------------------------------------
	maskOutgoing = [senderId isEqualToString:[FUser currentId]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_TEXT])		return [self createTextMessage];
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_EMOJI])		return [self createEmojiMessage];
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_PICTURE])	return [self createPictureMessage];
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_VIDEO])		return [self createVideoMessage];
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_AUDIO])		return [self createAudioMessage];
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_LOCATION])	return [self createLocationMessage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return nil;
}

#pragma mark - Text message

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)createTextMessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = [RELCryptor decryptText:message[FMESSAGE_TEXT] groupId:message[FMESSAGE_GROUPID]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:date text:text];
}

#pragma mark - Emoji message

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)createEmojiMessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSString *text = [RELCryptor decryptText:message[FMESSAGE_TEXT] groupId:message[FMESSAGE_GROUPID]];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	EmojiMediaItem *mediaItem = [[EmojiMediaItem alloc] initWithText:text];
	mediaItem.appliesMediaViewMaskAsOutgoing = maskOutgoing;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:date media:mediaItem];
}

#pragma mark - Picture message

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)createPictureMessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSNumber *width = message[FMESSAGE_PICTURE_WIDTH];
	NSNumber *height = message[FMESSAGE_PICTURE_HEIGHT];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	PhotoMediaItem *mediaItem = [[PhotoMediaItem alloc] initWithImage:nil Width:width Height:height];
	mediaItem.appliesMediaViewMaskAsOutgoing = maskOutgoing;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[MediaManager loadPicture:mediaItem message:message user:[FUser currentUser] wifi:wifi collectionView:collectionView];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:date media:mediaItem];
}

#pragma mark - Video message

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)createVideoMessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	VideoMediaItem *mediaItem = [[VideoMediaItem alloc] initWithMaskAsOutgoing:maskOutgoing];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[MediaManager loadVideo:mediaItem message:message user:[FUser currentUser] wifi:wifi collectionView:collectionView];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:date media:mediaItem];
}

#pragma mark - Audio message

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)createAudioMessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AudioMediaItem *mediaItem = [[AudioMediaItem alloc] initWithFileURL:nil Duration:message[FMESSAGE_AUDIO_DURATION]];
	mediaItem.appliesMediaViewMaskAsOutgoing = maskOutgoing;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[MediaManager loadAudio:mediaItem message:message user:[FUser currentUser] wifi:wifi collectionView:collectionView];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:date media:mediaItem];
}

#pragma mark - Location message

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (JSQMessage *)createLocationMessage
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	JSQLocationMediaItem *mediaItem = [[JSQLocationMediaItem alloc] initWithLocation:nil];
	mediaItem.appliesMediaViewMaskAsOutgoing = maskOutgoing;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	CLLocationDegrees latitude = [message[FMESSAGE_LATITUDE] doubleValue];
	CLLocationDegrees longitude = [message[FMESSAGE_LONGITUDE] doubleValue];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
	[mediaItem setLocation:location withCompletionHandler:^{
		[collectionView reloadData];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderName date:date media:mediaItem];
}

@end
