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

#import "Incoming.h"
#import "Outgoing.h"

#import "AudioMediaItem.h"
#import "PhotoMediaItem.h"
#import "VideoMediaItem.h"

#import "ChatView.h"
#import "MapView.h"
#import "PictureView.h"
#import "StickersView.h"
#import "ProfileView.h"
#import "MembersView.h"
#import "GroupDetailsView.h"
#import "NavigationController.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface ChatView()
{
	NSString *groupId;
	NSArray *members;
	NSString *description;
	NSString *type;

	FObject *group;
	FUser *user2;

	NSInteger typingCounter;

	FIRDatabaseReference *firebase1;
	FIRDatabaseReference *firebase2;

	NSInteger loaded;
	NSMutableArray *loads;
	NSMutableArray *loadIds;

	NSMutableArray *messages;
	NSMutableArray *jsqmessages;

	NSMutableArray *avatarIds;
	NSMutableDictionary *avatars;
	NSMutableDictionary *initials;

	JSQMessagesBubbleImage *bubbleImageOutgoing;
	JSQMessagesBubbleImage *bubbleImageIncoming;
}

@property (strong, nonatomic) IBOutlet UIView *viewTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelDetails;

@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation ChatView

@synthesize viewTitle, labelTitle, labelDetails;

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSDictionary *)dictionary
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	groupId = dictionary[@"groupId"];
	members = dictionary[@"members"];
	description = dictionary[@"description"];
	type = dictionary[@"type"];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidLoad];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.titleView = viewTitle;
	[self updateTitleDetails];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"chat_back"]
																	style:UIBarButtonItemStylePlain target:self action:@selector(actionBack)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Details" style:UIBarButtonItemStylePlain target:self
																			 action:@selector(actionDetails)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[NotificationCenter addObserver:self selector:@selector(actionCleanup) name:NOTIFICATION_CLEANUP_CHATVIEW];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	loads = [[NSMutableArray alloc] init];
	loadIds = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	messages = [[NSMutableArray alloc] init];
	jsqmessages = [[NSMutableArray alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	avatarIds = [[NSMutableArray alloc] init];
	avatars = [[NSMutableDictionary alloc] init];
	initials = [[NSMutableDictionary alloc] init];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
	bubbleImageOutgoing = [bubbleFactory outgoingMessagesBubbleImageWithColor:COLOR_OUTGOING];
	bubbleImageIncoming = [bubbleFactory incomingMessagesBubbleImageWithColor:COLOR_INCOMING];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[JSQMessagesCollectionViewCell registerMenuAction:@selector(actionCopy:)];
	[JSQMessagesCollectionViewCell registerMenuAction:@selector(actionDelete:)];
	[JSQMessagesCollectionViewCell registerMenuAction:@selector(actionSave:)];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	UIMenuItem *menuItemCopy = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(actionCopy:)];
	UIMenuItem *menuItemDelete = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(actionDelete:)];
	UIMenuItem *menuItemSave = [[UIMenuItem alloc] initWithTitle:@"Save" action:@selector(actionSave:)];
	[UIMenuController sharedMenuController].menuItems = @[menuItemCopy, menuItemDelete, menuItemSave];
	//---------------------------------------------------------------------------------------------------------------------------------------------

	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Recent clearCounter:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	firebase1 = [[[FIRDatabase database] referenceWithPath:FMESSAGE_PATH] child:groupId];
	firebase2 = [[[FIRDatabase database] referenceWithPath:FTYPING_PATH] child:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self loadMessages];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewWillAppear:animated];
	[self fetchGroup];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super viewDidAppear:animated];
	self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

#pragma mark - Custom menu actions for cells

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIMenuController *menu = [notification object];
	UIMenuItem *menuItemCopy = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(actionCopy:)];
	UIMenuItem *menuItemDelete = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(actionDelete:)];
	UIMenuItem *menuItemSave = [[UIMenuItem alloc] initWithTitle:@"Save" action:@selector(actionSave:)];
	menu.menuItems = @[menuItemCopy, menuItemDelete, menuItemSave];
}

#pragma mark - Backend methods (message)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadMessages
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self.automaticallyScrollsToMostRecentMessage = NO;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[Messages load:groupId completion:^(NSMutableArray *objects)
	{
		for (FObject *message in objects)
		{
			[loads addObject:message];
			[loadIds addObject:[message objectId]];
		}
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[self insertMessages];
		[self scrollToBottomAnimated:NO];
		//-----------------------------------------------------------------------------------------------------------------------------------------
		[self createMessageObservers];
		[self createTypingObservers];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)insertMessages
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSInteger max = [loads count]-loaded;
	NSInteger min = max-INSERT_MESSAGES; if (min < 0) min = 0;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (NSInteger i=max-1; i>=min; i--)
	{
		FObject *message = loads[i];
		BOOL incoming = [self insertMessage:message];
		if (incoming) [self messageUpdate:message];
		loaded++;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.automaticallyScrollsToMostRecentMessage = NO;
	[self finishReceivingMessage];
	self.automaticallyScrollsToMostRecentMessage = YES;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	self.showLoadEarlierMessagesHeader = (loaded != [loads count]);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createMessageObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase1 observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot)
	{
		FObject *message = [FObject objectWithPath:FMESSAGE_PATH Subpath:groupId dictionary:snapshot.value];
		if ([loadIds containsObject:[message objectId]] == NO)
		{
			BOOL incoming = [self addMessage:message];
			if (incoming) [self messageUpdate:message];
			if (incoming) [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
			[self finishReceivingMessage];
		}
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[firebase1 observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot)
	{
		FObject *message = [FObject objectWithPath:FMESSAGE_PATH Subpath:groupId dictionary:snapshot.value];
		[self updateMessage:message];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[firebase1 observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot)
	{
		FObject *message = [FObject objectWithPath:FMESSAGE_PATH Subpath:groupId dictionary:snapshot.value];
		[self deleteMessage:message];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)insertMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	Incoming *incoming = [[Incoming alloc] initWith:message CollectionView:self.collectionView];
	JSQMessage *jsqmessage = [incoming createMessage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[messages insertObject:message atIndex:0];
	[jsqmessages insertObject:jsqmessage atIndex:0];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [self incoming:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)addMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	Incoming *incoming = [[Incoming alloc] initWith:message CollectionView:self.collectionView];
	JSQMessage *jsqmessage = [incoming createMessage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[messages addObject:message];
	[jsqmessages addObject:jsqmessage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return [self incoming:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageIndex:message completion:^(NSInteger index)
	{
		messages[index] = message;
		[self.collectionView reloadData];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)deleteMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageIndex:message completion:^(NSInteger index)
	{
		[messages removeObjectAtIndex:index];
		[jsqmessages removeObjectAtIndex:index];
		[self.collectionView reloadData];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)messageIndex:(FObject *)message completion:(void (^)(NSInteger index))completion
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	for (NSInteger index=0; index<[messages count]; index++)
	{
		FObject *temp = messages[index];
		if ([[message objectId] isEqualToString:[temp objectId]])
		{
			if (completion != nil) completion(index);
			break;
		}
	}
}

#pragma mark - Backend methods (avatar)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)loadAvatar:(NSString *)userId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([avatarIds containsObject:userId]) return;
	else [avatarIds addObject:userId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	for (FUser *user in [Users objects])
	{
		if ([[user objectId] isEqualToString:userId])
		{
			[self downloadThumbnail:user];
			break;
		}
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)downloadThumbnail:(FUser *)user
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (user[FUSER_THUMBNAIL] == nil) return;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[DownloadManager image:user[FUSER_THUMBNAIL] completion:^(NSString *path, NSError *error, BOOL network)
	{
		NSString *userId = [user objectId];
		if (error == nil)
		{
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
			avatars[userId] = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:30];
			[self performSelector:@selector(delayedReload) withObject:nil afterDelay:0.1];
		}
		else [avatarIds removeObject:userId];
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)delayedReload
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.collectionView reloadData];
}

#pragma mark - Backend methods (group)

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)fetchGroup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *object = [FObject objectWithPath:FGROUP_PATH];
	object[FGROUP_OBJECTID] = groupId;
	[object fetchInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			group = object;
			members = group[FGROUP_MEMBERS];
			description = group[FGROUP_NAME];
			[self updateTitleDetails];
		}
	}];
}

#pragma mark - Message sendig methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)messageSend:(NSString *)text Video:(NSURL *)video Picture:(UIImage *)picture Audio:(NSString *)audio
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	Outgoing *outgoing = [[Outgoing alloc] initWith:groupId View:self.navigationController.view];
	[outgoing send:text Video:video Picture:picture Audio:audio];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[JSQSystemSoundPlayer jsq_playMessageSentSound];
	[self finishSendingMessage];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)messageUpdate:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([message[FMESSAGE_STATUS] isEqualToString:TEXT_DELIVERED])
	{
		message[FMESSAGE_STATUS] = TEXT_READ;
		[message saveInBackground];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)messageDelete:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	[message deleteInBackground];
}

#pragma mark - Typing indicator

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)createTypingObservers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase2 observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot)
	{
		if ([snapshot.key isEqualToString:[FUser currentId]] == NO)
		{
			BOOL typing = [snapshot.value boolValue];
			self.showTypingIndicator = typing;
			if (typing) [self scrollToBottomAnimated:YES];
		}
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)typingIndicatorStart
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	typingCounter++;
	[self typingIndicatorSave:@YES];
	[self performSelector:@selector(typingIndicatorStop) withObject:nil afterDelay:2.0];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)typingIndicatorStop
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	typingCounter--;
	if (typingCounter == 0) [self typingIndicatorSave:@NO];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)typingIndicatorSave:(NSNumber *)typing
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[firebase2 updateChildValues:@{[FUser currentId]:typing}];
}

#pragma mark - UITextViewDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self typingIndicatorStart];
	return YES;
}

#pragma mark - JSQMessagesViewController method overrides

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId
		 senderDisplayName:(NSString *)name date:(NSDate *)date
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageSend:text Video:nil Picture:nil Audio:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didPressAccessoryButton:(UIButton *)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self actionAttach];
}

#pragma mark - JSQMessages CollectionView DataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)senderId
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [FUser currentId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSString *)senderDisplayName
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [FUser fullname];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return jsqmessages[indexPath.item];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
			 messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self outgoing:messages[indexPath.item]])
	{
		return bubbleImageOutgoing;
	}
	else return bubbleImageIncoming;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
					avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	NSString *senderId = message[FMESSAGE_SENDERID];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (avatars[senderId] == nil)
	{
		[self loadAvatar:senderId];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (initials[senderId] == nil)
	{
		initials[senderId] = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:message[FMESSAGE_SENDERINITIALS]
								backgroundColor:HEXCOLOR(0xE4E4E4FF) textColor:[UIColor whiteColor] font:[UIFont systemFontOfSize:14] diameter:30];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	return (avatars[senderId] != nil) ? avatars[senderId] : initials[senderId];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView
	attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (indexPath.item % 3 == 0)
	{
		JSQMessage *jsqmessage = jsqmessages[indexPath.item];
		return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:jsqmessage.date];
	}
	else return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView
	attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self incoming:messages[indexPath.item]])
	{
		JSQMessage *jsqmessage = jsqmessages[indexPath.item];
		if (indexPath.item > 0)
		{
			JSQMessage *previous = jsqmessages[indexPath.item-1];
			if ([previous.senderId isEqualToString:jsqmessage.senderId])
			{
				return nil;
			}
		}
		return [[NSAttributedString alloc] initWithString:jsqmessage.senderDisplayName];
	}
	else return nil;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	if ([self outgoing:message])
	{
		return [[NSAttributedString alloc] initWithString:message[FMESSAGE_STATUS]];
	}
	else return nil;
}

#pragma mark - UICollectionView DataSource

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return [jsqmessages count];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIColor *color = [self outgoing:messages[indexPath.item]] ? [UIColor whiteColor] : [UIColor blackColor];

	JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
	cell.textView.textColor = color;
	cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName:color};

	return cell;
}

#pragma mark - UICollectionView Delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)collectionView:(JSQMessagesCollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[super collectionView:collectionView shouldShowMenuForItemAtIndexPath:indexPath];
	return YES;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath
			withSender:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (action == @selector(actionCopy:))
	{
		if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_TEXT]) return YES;
		if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_EMOJI]) return YES;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (action == @selector(actionDelete:))
	{
		if ([self outgoing:message]) return YES;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (action == @selector(actionSave:))
	{
		if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_PICTURE]) return YES;
		if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_VIDEO]) return YES;
		if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_AUDIO]) return YES;
	}
	return NO;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath
			withSender:(id)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (action == @selector(actionCopy:))		[self actionCopy:indexPath];
	if (action == @selector(actionDelete:))		[self actionDelete:indexPath];
	if (action == @selector(actionSave:))		[self actionSave:indexPath];
}

#pragma mark - JSQMessages collection view flow layout delegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
	heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (indexPath.item % 3 == 0)
	{
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
	heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self incoming:messages[indexPath.item]])
	{
		if (indexPath.item > 0)
		{
			JSQMessage *jsqmessage = jsqmessages[indexPath.item];
			JSQMessage *previous = jsqmessages[indexPath.item-1];
			if ([previous.senderId isEqualToString:jsqmessage.senderId])
			{
				return 0;
			}
		}
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout
	heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([self outgoing:messages[indexPath.item]])
	{
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

#pragma mark - Responding to collection view tap events

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView header:(JSQMessagesLoadEarlierHeaderView *)headerView
	didTapLoadEarlierMessagesButton:(UIButton *)sender
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self insertMessages];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView
		   atIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	if ([self incoming:message])
	{
		ProfileView *profileView = [[ProfileView alloc] initWithUserId:message[FMESSAGE_SENDERID] Chat:NO];
		[self.navigationController pushViewController:profileView animated:YES];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	JSQMessage *jsqmessage = jsqmessages[indexPath.item];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_PICTURE])
	{
		PhotoMediaItem *mediaItem = (PhotoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_MANUAL)
		{
			[MediaManager loadPictureManual:mediaItem message:message user:[FUser currentUser] collectionView:collectionView];
			[collectionView reloadData];
		}
		if (mediaItem.status == STATUS_SUCCEED)
		{
			PictureView *pictureView = [[PictureView alloc] initWith:mediaItem.image];
			[self presentViewController:pictureView animated:YES completion:nil];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_VIDEO])
	{
		VideoMediaItem *mediaItem = (VideoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_MANUAL)
		{
			[MediaManager loadVideoManual:mediaItem message:message user:[FUser currentUser] collectionView:collectionView];
			[collectionView reloadData];
		}
		if (mediaItem.status == STATUS_SUCCEED)
		{
			MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
			[self presentMoviePlayerViewControllerAnimated:moviePlayer];
			[moviePlayer.moviePlayer play];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_AUDIO])
	{
		AudioMediaItem *mediaItem = (AudioMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_MANUAL)
		{
			[MediaManager loadAudioManual:mediaItem message:message user:[FUser currentUser] collectionView:collectionView];
			[collectionView reloadData];
		}
		if (mediaItem.status == STATUS_SUCCEED)
		{
			MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
			[self presentMoviePlayerViewControllerAnimated:moviePlayer];
			[moviePlayer.moviePlayer play];
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_LOCATION])
	{
		JSQLocationMediaItem *mediaItem = (JSQLocationMediaItem *)jsqmessage.media;
		MapView *mapView = [[MapView alloc] initWith:mediaItem.location];
		NavigationController *navController = [[NavigationController alloc] initWithRootViewController:mapView];
		[self presentViewController:navController animated:YES completion:nil];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath
		 touchLocation:(CGPoint)touchLocation
//-------------------------------------------------------------------------------------------------------------------------------------------------
{

}

#pragma mark - User actions

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionBack
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self actionCleanup];
	[Recent clearCounter:groupId];
	[self.navigationController popViewControllerAnimated:YES];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDetails
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([type isEqualToString:CHAT_PRIVATE])
	{
		for (NSString *userId in members)
		{
			if ([userId isEqualToString:[FUser currentId]] == NO)
			{
				ProfileView *profileView = [[ProfileView alloc] initWithUserId:userId Chat:NO];
				[self.navigationController pushViewController:profileView animated:YES];
			}
		}
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([type isEqualToString:CHAT_MULTIPLE])
	{
		MembersView *membersView = [[MembersView alloc] initWith:members];
		[self.navigationController pushViewController:membersView animated:YES];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([type isEqualToString:CHAT_GROUP])
	{
		if (group != nil)
		{
			GroupDetailsView *groupDetailsView = [[GroupDetailsView alloc] initWithGroup:group Chat:NO];
			[self.navigationController pushViewController:groupDetailsView animated:YES];
		}
		else [ProgressHUD showError:@"This group seems to be deleted."];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionDelete:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageDelete:indexPath];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCopy:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	NSString *text = [RELCryptor decryptText:message[FMESSAGE_TEXT] groupId:groupId];
	[[UIPasteboard generalPasteboard] setString:text];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionSave:(NSIndexPath *)indexPath
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = messages[indexPath.item];
	JSQMessage *jsqmessage = jsqmessages[indexPath.item];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_PICTURE])
	{
		PhotoMediaItem *mediaItem = (PhotoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_SUCCEED)
			UIImageWriteToSavedPhotosAlbum(mediaItem.image, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_VIDEO])
	{
		VideoMediaItem *mediaItem = (VideoMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_SUCCEED)
			UISaveVideoAtPathToSavedPhotosAlbum(mediaItem.fileURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([message[FMESSAGE_TYPE] isEqualToString:MESSAGE_AUDIO])
	{
		AudioMediaItem *mediaItem = (AudioMediaItem *)jsqmessage.media;
		if (mediaItem.status == STATUS_SUCCEED)
		{
			NSString *path = [RELFile temp:@"mp4"];
			[RELFile copy:mediaItem.fileURL.path dest:path overwrite:YES];
			UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
		}
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if (error == nil)
	{
		[ProgressHUD showSuccess:@"Successfully saved."];
	}
	else [ProgressHUD showError:@"Save failed."];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionAttach
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self.view endEditing:YES];
	NSArray *menuItems = @[[[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_camera"] title:@"Camera"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_audio"] title:@"Audio"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_picture"] title:@"Picture"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_video"] title:@"Video"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_location"] title:@"Location"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_sticker"] title:@"Sticker"]];
	RNGridMenu *gridMenu = [[RNGridMenu alloc] initWithItems:menuItems];
	gridMenu.delegate = self;
	[gridMenu showInViewController:self center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionStickers
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	StickersView *stickersView = [[StickersView alloc] init];
	stickersView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:stickersView];
	[self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - RNGridMenuDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)gridMenu:(RNGridMenu *)gridMenu willDismissWithSelectedItem:(RNGridMenuItem *)item atIndex:(NSInteger)itemIndex
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[gridMenu dismissAnimated:NO];
	if ([item.title isEqualToString:@"Camera"])		PresentMultiCamera(self, YES);
	if ([item.title isEqualToString:@"Audio"])		PresentAudioRecorder(self);
	if ([item.title isEqualToString:@"Picture"])	PresentPhotoLibrary(self, YES);
	if ([item.title isEqualToString:@"Video"])		PresentVideoLibrary(self, YES);
	if ([item.title isEqualToString:@"Location"])	[self messageSend:nil Video:nil Picture:nil Audio:nil];
	if ([item.title isEqualToString:@"Sticker"])	[self actionStickers];
}

#pragma mark - UIImagePickerControllerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	NSURL *video = info[UIImagePickerControllerMediaURL];
	UIImage *picture = info[UIImagePickerControllerEditedImage];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[self messageSend:nil Video:video Picture:picture Audio:nil];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IQAudioRecorderViewControllerDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)audioRecorderController:(IQAudioRecorderViewController *)controller didFinishWithAudioAtPath:(NSString *)path
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[self messageSend:nil Video:nil Picture:nil Audio:path];
	[controller dismissViewControllerAnimated:YES completion:nil];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)audioRecorderControllerDidCancel:(IQAudioRecorderViewController *)controller
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - StickersDelegate

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)didSelectSticker:(NSString *)sticker
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	UIImage *picture = [UIImage imageNamed:sticker];
	[self messageSend:nil Video:nil Picture:picture Audio:nil];
}

#pragma mark - Cleanup methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)actionCleanup
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	[NotificationCenter removeObserver:self];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (firebase1 != nil) [firebase1 removeAllObservers];
	if (firebase2 != nil) [firebase2 removeAllObservers];
}

#pragma mark - Helper methods

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)updateTitleDetails
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	if ([type isEqualToString:CHAT_PRIVATE])
	{
		labelTitle.text = @"Private";
		labelDetails.text = description;
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([type isEqualToString:CHAT_MULTIPLE])
	{
		labelTitle.text = @"Multiple";
		labelDetails.text = [NSString stringWithFormat:@"%ld members", (long) [members count]];
	}
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if ([type isEqualToString:CHAT_GROUP])
	{
		labelTitle.text = description;
		labelDetails.text = [NSString stringWithFormat:@"%ld members", (long) [members count]];
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)incoming:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return ([message[FMESSAGE_SENDERID] isEqualToString:[FUser currentId]] == NO);
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (BOOL)outgoing:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	return ([message[FMESSAGE_SENDERID] isEqualToString:[FUser currentId]] == YES);
}

@end
