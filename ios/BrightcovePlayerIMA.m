#import "BrightcovePlayerIMA.h"
#import "BrightcovePlayerOfflineVideoManager.h"

@interface BrightcovePlayerIMA () <IMAWebOpenerDelegate, BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate, BCOVPlaybackControllerAdsDelegate>

@end

@implementation BrightcovePlayerIMA

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
//        [self setup];
    }
    return self;
}

- (void)setupWithSettings:(NSDictionary*)settings {
    /* added */
    NSString * kViewControllerIMAPublisherID = [settings objectForKey:@"publisherProvidedID"];
    NSString * kViewControllerIMALanguage = @"en";
    
    IMASettings *imaSettings = [[IMASettings alloc] init];
    if (kViewControllerIMAPublisherID != nil) {
        imaSettings.ppid = kViewControllerIMAPublisherID;
    }
    imaSettings.language = kViewControllerIMALanguage;
    
    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = (UIViewController*)[self nextResponder];
    renderSettings.webOpenerDelegate = self;
    
    NSString *IMAUrl = [settings objectForKey:@"IMAUrl"];
    BCOVIMAAdsRequestPolicy *adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyWithVMAPAdTagUrl:IMAUrl];
    
    _playbackController = [BCOVPlayerSDKManager.sharedManager createIMAPlaybackControllerWithSettings:imaSettings adsRenderingSettings:renderSettings adsRequestPolicy:adsRequestPolicy adContainer:self companionSlots:nil viewStrategy:nil];
    
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
    
    BCOVPUIBasicControlView *control = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    [control.progressSlider setTrackHeight:2];
    [control.progressSlider setMinimumTrackTintColor:[UIColor colorWithRed:0.22f green:0.64f blue:0.84f alpha:1.0f]];
    
    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.jumpBackInterval = 999;
    [options setLearnMoreButtonBrowserStyle:BCOVPUILearnMoreButtonUseInAppBrowser];
        
    _playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options controlsView:control];
    _playerView.delegate = self;
    _playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _playerView.backgroundColor = UIColor.blackColor;
    
    _targetVolume = 1.0;
    _autoPlay = autoPlay;
    
    [self addSubview:_playerView];
    
    /*
     _playbackController = [BCOVPlayerSDKManager.sharedManager createPlaybackController];
     _playbackController.delegate = self;
     _playbackController.autoPlay = NO;
     _playbackController.autoAdvance = YES;
     
     _playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:nil controlsView:[BCOVPUIBasicControlView basicControlViewWithVODLayout] ];
     _playerView.delegate = self;
     _playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
     _playerView.backgroundColor = UIColor.blackColor;
     
     _targetVolume = 1.0;
     _autoPlay = NO;
     
     [self addSubview:_playerView];
     
     */
}

- (void)setupService {
    if ((!_playbackService || _playbackServiceDirty) && _accountId && _policyKey) {
        _playbackServiceDirty = NO;
        _playbackService = [[BCOVPlaybackService alloc] initWithAccountId:_accountId policyKey:_policyKey];
    }
}

- (void)loadMovie {
    if (_videoToken) {
        BCOVVideo *video = [[BrightcovePlayerOfflineVideoManager sharedManager] videoObjectFromOfflineVideoToken:_videoToken];
        if (video) {
            [self.playbackController setVideos: @[ video ]];
        }
        return;
    }
    if (!_playbackService) return;
    if (_videoId) {
        [_playbackService findVideoWithVideoID:_videoId parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
            if (video) {
                [self.playbackController setVideos: @[ video ]];
            }
        }];
    } else if (_referenceId) {
        [_playbackService findVideoWithReferenceID:_referenceId parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
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

- (void)setReferenceId:(NSString *)referenceId {
    _referenceId = referenceId;
    _videoId = NULL;
    [self setupService];
    [self loadMovie];
}

- (void)setVideoId:(NSString *)videoId {
    _videoId = videoId;
    _referenceId = NULL;
    [self setupService];
    [self loadMovie];
}

- (void)setVideoToken:(NSString *)videoToken {
    _videoToken = videoToken;
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

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent {
    if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventPlaybackBufferEmpty || lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventFail ||
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
        if (_autoPlay) {
            [_playbackController play];
        }
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
    } else if (lifecycleEvent.eventType == kBCOVPlaybackSessionLifecycleEventEnd) {
//        if (self.onEnd) {
//            self.onEnd(@{});
//        }
    }
    
    NSString *type = lifecycleEvent.eventType;

    if ([type isEqualToString:kBCOVIMALifecycleEventAdsLoaderLoaded])
    {        
        // When ads load successfully, the kBCOVIMALifecycleEventAdsLoaderLoaded lifecycle event
//        // returns an NSDictionary containing a reference to the IMAAdsManager.
//        IMAAdsManager *adsManager = lifecycleEvent.properties[kBCOVIMALifecycleEventPropertyKeyAdsManager];
//        if (adsManager != nil)
//        {
//            // Lower the volume of ads by half.
//            adsManager.volume = adsManager.volume / 2.0;
//            NSLog (@"ViewController Debug - IMAAdsManager.volume set to %0.1f.", adsManager.volume);
//        }
    }
    else if ([type isEqualToString:kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];

        switch (adEvent.type)
        {
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
        self.onUpdateBufferProgress(@{
                                      @"bufferProgress": @(bufferProgress),
                                      });
    }
}

-(void)playerView:(BCOVPUIPlayerView *)playerView didTransitionToScreenMode:(BCOVPUIScreenMode)screenMode {
    if (screenMode == BCOVPUIScreenModeNormal) {
        if (self.onExitFullscreen) {
            self.onExitFullscreen(@{});
        }
    } else if (screenMode == BCOVPUIScreenModeFull) {
        if (self.onEnterFullscreen) {
            self.onEnterFullscreen(@{});
        }
    }
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAd:(BCOVAd *)ad {
    [self.playbackController pause];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didEnterAdSequence:(BCOVAdSequence *)adSequence {
    [self.playbackController pause];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAd:(BCOVAd *)ad {
    [self.playbackController play];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didExitAdSequence:(BCOVAdSequence *)adSequence {
    [self.playbackController play];
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session ad:(BCOVAd *)ad didProgressTo:(NSTimeInterval)progress {
    if (_playing) {
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
            [self.playbackController pause];
        } else {
            [self.playbackController play];
        }
    }
}

-(void)dispose {
    [self.playbackController setVideos:@[]];
    self.playbackController = nil;
}

@end
