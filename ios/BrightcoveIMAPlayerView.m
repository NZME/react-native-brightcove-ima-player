#import "BrightcoveIMAPlayerView.h"
#import <React/RCTUtils.h>
#import "UIApplication+CurrentNonAdViewController.h"

@interface BrightcoveIMAPlayerView () <IMALinkOpenerDelegate, BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVPlaybackControllerAdsDelegate, BCOVIMAPlaybackSessionDelegate>

@property (nonatomic) BOOL isAppInForeground; // App state

@end

@implementation BrightcoveIMAPlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
//        [self setup];
    }
    return self;
}

- (id) init
{
    self = [super init];
    if (self){
        self.isAppInForeground = YES;
        [self registerForNotifications];
      }
    return self;
}

#pragma mark - Setup

- (void)setupWithSettings:(NSDictionary*)settings {
    @try {
        // Current View Controller
        UIViewController * currentViewController = [[UIApplication sharedApplication] currentNonAdViewController];
        
        // Create and configure options for the Brightcove player
        BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
        
        // Configure jumpBackInterval
        options.jumpBackInterval = 999;
        
        // Set the Learn More button behavior
        [options setLearnMoreButtonBrowserStyle:BCOVPUILearnMoreButtonUseInAppBrowser];
        
        // Set the presenting view controller
        options.presentingViewController = RCTPresentedViewController();
        
        // Enable automatic control type selection
        options.automaticControlTypeSelection = YES;
        
        // Create and configure the basic control view
        BCOVPUIBasicControlView *control = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
        
        // Customize the progress slider appearance
        [control.progressSlider setTrackHeight:2];
        [control.progressSlider setMinimumTrackTintColor:[UIColor colorWithRed:0.22f green:0.64f blue:0.84f alpha:1.0f]];
        
        // Create the player view with the provided options and control view
        _playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:control];
        
        // Hide default controls if _disableDefaultControl is true
        if (_disableDefaultControl == true) {
            _playerView.controlsView.hidden = true;
        }
        
        // Set the delegate, resizing, and background color for the player view
        _playerView.delegate = self;
        _playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _playerView.backgroundColor = [UIColor clearColor];
        
        // Add the player view as a subview
        [self addSubview:_playerView];
        
        // Obtain the publisher ID and language for IMA
        NSString *kViewControllerIMAPublisherID = [settings objectForKey:@"publisherProvidedID"];
        NSString *kViewControllerIMALanguage = @"en";
        
        // Configure IMA settings
        IMASettings *imaSettings = [[IMASettings alloc] init];
        if (kViewControllerIMAPublisherID != nil) {
            imaSettings.ppid = kViewControllerIMAPublisherID;
        }
        imaSettings.language = kViewControllerIMALanguage;
        imaSettings.autoPlayAdBreaks = NO;
        
        // Configure IMA ad rendering settings
        IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
        renderSettings.linkOpenerPresentingController = currentViewController;
        renderSettings.linkOpenerDelegate = self;
        renderSettings.enablePreloading = YES; // Default is yes
        
        // Set the timeout for loading video ad media files
        if (_targetAdVideoLoadTimeout == 0) {
            renderSettings.loadVideoTimeout = 3.0;
        } else {
            renderSettings.loadVideoTimeout = _targetAdVideoLoadTimeout;
        }
        
        // Obtain the IMAUrl from settings and create an ads request policy
        NSString *IMAUrl = [settings objectForKey:@"IMAUrl"];
        BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:IMAUrl];
        
        // Configure IMA playback session options
        NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };
        
        // Get the shared Brightcove player manager
        BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
        
        
        // Create and configure the IMA playback controller
        _playbackController = [manager createIMAPlaybackControllerWithSettings:imaSettings
                                                          adsRenderingSettings:renderSettings
                                                              adsRequestPolicy:adsRequestPolicy
                                                                   adContainer:self.playerView.contentOverlayView
                                                                viewController:currentViewController
                                                                companionSlots:nil
                                                                  viewStrategy:nil
                                                                       options:imaPlaybackSessionOptions];
        
        // Set the playback controller for the player view
        _playerView.playbackController = _playbackController;
        
        // Set the delegate for the playback controller
        _playbackController.delegate = self;
        
        // Bypass mute button for audio
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        
        // Configure autoAdvance, autoPlay, and allowsExternalPlayback settings
        BOOL autoAdvance = [settings objectForKey:@"autoAdvance"] != nil ? [[settings objectForKey:@"autoAdvance"] boolValue] : NO;
        BOOL autoPlay = NO; // [settings objectForKey:@"autoPlay"] != nil ? [[settings objectForKey:@"autoPlay"] boolValue] : YES;
        BOOL allowsExternalPlayback = [settings objectForKey:@"allowsExternalPlayback"] != nil ? [[settings objectForKey:@"allowsExternalPlayback"] boolValue] : YES;
        
        _playbackController.autoAdvance = autoAdvance;
        _playbackController.autoPlay = autoPlay;
        _playbackController.allowsExternalPlayback = allowsExternalPlayback;
        
        // Set the target volume, autoPlay, and inViewPort defaults
        _targetVolume = 1.0;
        _autoPlay = autoPlay;
        _inViewPort = YES;
    }
    @catch (NSException *exception) {
        // Handle exceptions by logging them
        NSLog(@"-------setupWithSettings Exception------: %@", exception);
    }
}

- (void)setupService {
    if ((!_playbackService || _playbackServiceDirty) && _accountId && _policyKey) {
        _playbackServiceDirty = NO;
        _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:_accountId policyKey:_policyKey];
    }
}

#pragma mark - Playback Controls
- (void)loadMovie {
    if (!_playbackService) return;
    if (_videoId) {
        [_playbackService findVideoWithVideoID:_videoId parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
            if (video) {
                [self.playbackController setVideos: @[ video ]];
            }
        }];
    }
}

-(void)dispose {
    [self.playbackController setVideos:@[]];
    self.playbackController = nil;
}

#pragma mark - Property Setters

- (void)setVideoId:(NSString *)videoId {
    _videoId = videoId;
    [self setupService];
    [self loadMovie];
}

- (void)setAccountId:(NSString *)accountId {
    _accountId = accountId;
    _playbackServiceDirty = YES;
    [self setupService];
    [self loadMovie];
}

- (void)setPolicyKey:(NSString *)policyKey {
    _policyKey = policyKey;
    _playbackServiceDirty = YES;
    [self setupService];
    [self loadMovie];
}

- (void)setAutoPlay:(BOOL)autoPlay {
    _autoPlay = autoPlay;
}

- (void)setPlay:(BOOL)play {
    if (_playing == play) return;
    if (play) {
        [_playbackController play];
    } else {
        [_playbackController pause];
    }
}

- (void)setFullscreen:(BOOL)fullscreen {
    if (fullscreen) {
        [_playerView performScreenTransitionWithScreenMode:BCOVPUIScreenModeFull];
    } else {
        [_playerView performScreenTransitionWithScreenMode:BCOVPUIScreenModeNormal];
    }
}

- (void)setVolume:(NSNumber*)volume {
    _targetVolume = volume.doubleValue;
    [self refreshVolume];
}

- (void)setBitRate:(NSNumber*)bitRate {
    _targetBitRate = bitRate.doubleValue;
    [self refreshBitRate];
}

- (void)setAdVideoLoadTimeout:(NSNumber*)adVideoLoadTimeout {
    _targetAdVideoLoadTimeout = adVideoLoadTimeout.intValue / 1000;
    _playbackServiceDirty = YES;
    [self setupService];
    [self loadMovie];
}

- (void)setPlaybackRate:(NSNumber*)playbackRate {
    _targetPlaybackRate = playbackRate.doubleValue;
    if (_playing) {
        [self refreshPlaybackRate];
    }
}

- (void)setDisableDefaultControl:(BOOL)disable {
    _disableDefaultControl = disable;
    _playerView.controlsView.hidden = disable;
}

#pragma mark - Refresh Methods

- (void)refreshVolume {
    if (!_playbackSession) return;
    _playbackSession.player.volume = _targetVolume;
}

- (void)refreshBitRate {
    if (!_playbackSession) return;
    AVPlayerItem *item = _playbackSession.player.currentItem;
    if (!item) return;
    item.preferredPeakBitRate = _targetBitRate;
}

- (void)refreshPlaybackRate {
    if (!_playbackSession || !_targetPlaybackRate) return;
    _playbackSession.player.rate = _targetPlaybackRate;
}

#pragma mark - Player Actions

- (void)seekTo:(NSNumber *)time {
    [_playbackController seekToTime:CMTimeMakeWithSeconds([time floatValue], NSEC_PER_SEC) completionHandler:^(BOOL finished) {
    }];
}

-(void) toggleFullscreen:(BOOL)isFullscreen {
    if (isFullscreen) {
        [_playerView performScreenTransitionWithScreenMode:BCOVPUIScreenModeFull];
    } else {
        [_playerView performScreenTransitionWithScreenMode:BCOVPUIScreenModeNormal];
    }
}

-(void) toggleInViewPort:(BOOL)inViewPort {
    if (inViewPort) {
        _inViewPort = YES;
    } else {
        _inViewPort = NO;
        [self.playbackController pauseAd];
        [self.playbackController pause];
    }
}

-(void) pause {
    if (self.playbackController) {
        if (_adsPlaying) {
            [self.playbackController pauseAd];
        }
        [self.playbackController pause];
    }
}

-(void) play {
    if (self.playbackController) {
        if (_adsPlaying) {
            [self.playbackController resumeAd];
            //[self.playbackController pause];
        } else {
            [self.playbackController play];
        }
    }
}

-(void) stopPlayback {
    if (self.playbackController) {
        if (_adsPlaying) {
            [self.playbackController pauseAd];
        }
        [self.playbackController pause];
    }
}

#pragma mark - Notification Handling

- (void)registerForNotifications {
    for (NSString *name in @[UIApplicationDidBecomeActiveNotification, UIApplicationWillResignActiveNotification]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppStateDidChange:) name:name object:nil];
    }
}

- (void)handleAppStateDidChange:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        self.isAppInForeground = NO;
        [self toggleInViewPort:NO];
        [self pause];
    }
    
    // This method will be called when your app becomes active again.
    if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        [self toggleInViewPort:YES];
        if (!self.isAppInForeground && _adsPlaying) {
            [self.playbackController resumeAd];
        }
    }
}

#pragma mark - BCOVPlaybackControllerBasicDelegate methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent {
    
    // NSLog(@"BC - DEBUG eventType: %@", lifecycleEvent.eventType);
        
    if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventPlaybackBufferEmpty ||
        lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventFail ||
        lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventError ||
        lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventTerminate) {
        _playbackSession = nil;
        return;
    }
    
    _playbackSession = session;
    if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventReady) {
        [self refreshVolume];
        [self refreshBitRate];
        if (self.onReady) {
            self.onReady(@{});
        }
        // disabling this due to video blip before pre-roll
//        if (_autoPlay) {
//            [_playbackController play];
//        }
    } else if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventPlay) {
        _playing = true;
        [self refreshPlaybackRate];
        if (self.onPlay) {
            self.onPlay(@{});
        }
    } else if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventPause) {
        _playing = false;
        if (self.currentVideoDuration) {
            int curDur = (int)self.currentVideoDuration;
            int curTime = (int)CMTimeGetSeconds([session.player currentTime]);
            if (curDur == curTime) {
                if (self.onEnd) {
                    self.onEnd(@{});
                }
            }
        }

        if (self.onPause) {
            self.onPause(@{});
        }
    } else if (lifecycleEvent.eventType == kBCOVIMALifecycleEventAdsLoaderLoaded) {
        if (self.onAdsLoaded) {
            self.onAdsLoaded(@{});
        }
    } else if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventAdProgress) {
        // catches scroll away before ads start bug
        if (!_inViewPort) {
            [self.playbackController pauseAd];
            [self.playbackController pause];
        }
    } else if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventAdEnter) {
        //Additional RN function to determine when an ad starts playing. We use this event to determine when to hide the activity indicator as the ad has not displayed yet when the onAdsLoaded event is fired
        if (self.onAdsPlaying) {
            self.onAdsPlaying(@{});
        }
    }
    
    if (lifecycleEvent.eventType == kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent) {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];
        
        // NSLog(@"BC - DEBUG adEvent: %ld %@", adEvent.type, adEvent.typeString);
                
        switch (adEvent.type)
        {
            case kIMAAdEvent_LOADED:
                _adsPlaying = YES;
                break;
            case kIMAAdEvent_PAUSE:
                break;
            case kIMAAdEvent_RESUME:
                _adsPlaying = YES;
                break;
            case kIMAAdEvent_STARTED:
                _adsPlaying = YES;
                break;
            case kIMAAdEvent_COMPLETE:
                _adsPlaying = NO;
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                _adsPlaying = NO;
                break;
            default:
                break;
        }
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didChangeDuration:(NSTimeInterval)duration {
    self.currentVideoDuration = duration;
    if (self.onChangeDuration) {
        self.onChangeDuration(@{
                                @"duration": @(duration)
                                });
    }
}

-(void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress {
    if (self.onProgress && progress > 0 && progress != INFINITY) {
        self.onProgress(@{
                          @"currentTime": @(progress)
                          });
    }
    float bufferProgress = _playerView.controlsView.progressSlider.bufferProgress;
    if (_lastBufferProgress != bufferProgress) {
        _lastBufferProgress = bufferProgress;
        if (self.onUpdateBufferProgress) {
            self.onUpdateBufferProgress(@{
                                          @"bufferProgress": @(bufferProgress),
                                          });
        }
    }
}

-(void)playerView:(BCOVPUIPlayerView *)playerView didTransitionToScreenMode:(BCOVPUIScreenMode)screenMode {
    if (screenMode == BCOVPUIScreenModeNormal) {
        // if controls are disabled, disable player controls on normal mode
        if (_disableDefaultControl == true) {
            _playerView.controlsView.hidden = true;
        }
        if (self.onExitFullscreen) {
            self.onExitFullscreen(@{});
        }
    } else if (screenMode == BCOVPUIScreenModeFull) {
        // enable player controls on fullscreen mode
        if (_disableDefaultControl == true) {
            _playerView.controlsView.hidden = false;
        }
        if (self.onEnterFullscreen) {
            self.onEnterFullscreen(@{});
        }
    }
}

#pragma mark - IMALinkOpenerDelegate Methods

- (void)linkOpenerDidCloseInAppLink:(NSObject *)linkOpener
{
    // Called when the in-app browser has closed.
    if (_adsPlaying) {
        [self.playbackController resumeAd];
    }
}

@end
