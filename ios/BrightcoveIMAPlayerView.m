#import "BrightcoveIMAPlayerView.h"
#import <React/RCTUtils.h>

@interface BrightcoveIMAPlayerView () <IMALinkOpenerDelegate, BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVPlaybackControllerAdsDelegate, BCOVIMAPlaybackSessionDelegate>

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
    if (!self) return nil;

    for (NSString *name in @[
             UIApplicationDidBecomeActiveNotification,
             UIApplicationDidEnterBackgroundNotification
           ]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppStateDidChange:)
                                                     name:name
                                                   object:nil];
      }

    return self;
}

- (void)setupWithSettings:(NSDictionary*)settings {
    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.jumpBackInterval = 999;
    [options setLearnMoreButtonBrowserStyle:BCOVPUILearnMoreButtonUseInAppBrowser];
    options.presentingViewController = RCTPresentedViewController();
    options.automaticControlTypeSelection = YES;
    BCOVPUIBasicControlView *control = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    [control.progressSlider setTrackHeight:2];
    [control.progressSlider setMinimumTrackTintColor:[UIColor colorWithRed:0.22f green:0.64f blue:0.84f alpha:1.0f]];

    _playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:nil options:options controlsView:control];
    if (_disableDefaultControl == true) {
        _playerView.controlsView.hidden = true;
    }
    _playerView.delegate = self;
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _playerView.backgroundColor = UIColor.blackColor;

    [self addSubview:_playerView];
    
    NSString * kViewControllerIMAPublisherID = [settings objectForKey:@"publisherProvidedID"];
    NSString * kViewControllerIMALanguage = @"en";

    IMASettings *imaSettings = [[IMASettings alloc] init];
    if (kViewControllerIMAPublisherID != nil) {
        imaSettings.ppid = kViewControllerIMAPublisherID;
    }
    imaSettings.language = kViewControllerIMALanguage;

    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.linkOpenerPresentingController = RCTPresentedViewController();
    renderSettings.linkOpenerDelegate = self;

    if (_targetAdVideoLoadTimeout == 0) {
        renderSettings.loadVideoTimeout = 3.;
    } else {
        renderSettings.loadVideoTimeout = _targetAdVideoLoadTimeout;
    }

    NSString *IMAUrl = [settings objectForKey:@"IMAUrl"];
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:IMAUrl];
    
    NSDictionary *imaPlaybackSessionOptions = @{ kBCOVIMAOptionIMAPlaybackSessionDelegateKey: self };
    
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager
                           createIMAPlaybackControllerWithSettings:imaSettings
                           adsRenderingSettings:renderSettings
                           adsRequestPolicy:adsRequestPolicy
                           adContainer:self.playerView.contentOverlayView
                           viewController:RCTPresentedViewController()
                           companionSlots:nil
                           viewStrategy:nil
                           options:imaPlaybackSessionOptions];

    _playerView.playbackController = _playbackController;
    _playbackController.delegate = self;

    // By pass mute button
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];

    BOOL autoAdvance = [settings objectForKey:@"autoAdvance"] != nil ? [[settings objectForKey:@"autoAdvance"] boolValue] : NO;
    BOOL autoPlay = [settings objectForKey:@"autoPlay"] != nil ? [[settings objectForKey:@"autoPlay"] boolValue] : YES;
    BOOL allowsExternalPlayback = [settings objectForKey:@"allowsExternalPlayback"] != nil ? [[settings objectForKey:@"allowsExternalPlayback"] boolValue] : YES;

    _playbackController.autoAdvance = autoAdvance;
    _playbackController.autoPlay = autoPlay;
    _playbackController.allowsExternalPlayback = allowsExternalPlayback;

    _targetVolume = 1.0;
    _autoPlay = autoPlay;
    // default is in view
    _inViewPort = YES;
}

- (void)setupService {
    if ((!_playbackService || _playbackServiceDirty) && _accountId && _policyKey) {
        _playbackServiceDirty = NO;
        _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:_accountId policyKey:_policyKey];
    }
}

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

- (id<BCOVPlaybackController>)createPlaybackController {
    BCOVBasicSessionProviderOptions *options = [BCOVBasicSessionProviderOptions alloc];
    BCOVBasicSessionProvider *provider = [[BCOVPlayerSDKManager sharedManager] createBasicSessionProviderWithOptions:options];
    return [BCOVPlayerSDKManager.sharedManager createPlaybackControllerWithSessionProvider:provider viewStrategy:nil];
}

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

- (void)setDisableDefaultControl:(BOOL)disable {
    _disableDefaultControl = disable;
    _playerView.controlsView.hidden = disable;
}

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
            [self.playbackController pause];
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

-(void)dispose {
    [self.playbackController setVideos:@[]];
    self.playbackController = nil;
}

- (void)handleAppStateDidChange:(NSNotification *)notification
{    
    if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        [self toggleInViewPort:NO];
        [self pause];
    }
    
    if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        [self toggleInViewPort:YES];
        [self pause];
    }
}

#pragma mark - BCOVPlaybackControllerBasicDelegate methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent {
        
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
        if (self.onAdStarted) {
            self.onAdStarted(@{});
        }
    } else if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventAdProgress) {
        // catches scroll away before ads start bug
        if (!_inViewPort) {
            [self.playbackController pauseAd];
        }
    } else if (lifecycleEvent.eventType == kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent) {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];
                
        switch (adEvent.type)
        {
            case kIMAAdEvent_LOADED:
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

#pragma mark - BCOVPlaybackControllerAdsDelegate methods

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence {
    if (!_inViewPort && _adsPlaying) {
        [self.playbackController pauseAd];
    }
    [self.playbackController pause];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence {
    if (_inViewPort) {
        [self.playbackController play];
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAd:(BCOVAd *)ad {
    if (!_inViewPort && _adsPlaying) {
        [self.playbackController pauseAd];
    }
    [self.playbackController pause];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAd:(BCOVAd *)ad {
    if (_inViewPort) {
        [self.playbackController play];
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session ad:(BCOVAd *)ad didProgressTo:(NSTimeInterval)progress {
    if (_playing) {
        [self.playbackController pause];
    }
}

#pragma mark - IMAPlaybackSessionDelegate Methods

- (void)willCallIMAAdsLoaderRequestAdsWithRequest:(IMAAdsRequest *)adsRequest forPosition:(NSTimeInterval)position
{
    // for demo purposes, increase the VAST ad load timeout.
    //    adsRequest.vastLoadTimeout = 3000.;
    //NSLog(@"BC - DEBUG - IMAAdsRequest.vastLoadTimeout set to %.1f milliseconds.", adsRequest.vastLoadTimeout);
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
