#import "BrightcoveIMAPlayerViewManager.h"
#import "BrightcoveIMAPlayerView.h"
#import <React/RCTUIManager.h>

@implementation BrightcoveIMAPlayerViewManager

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (UIView *)view {
    return [[BrightcoveIMAPlayerView alloc] init];
}

- (dispatch_queue_t)methodQueue {
    return _bridge.uiManager.methodQueue;
}

RCT_EXPORT_VIEW_PROPERTY(policyKey, NSString);
RCT_EXPORT_VIEW_PROPERTY(accountId, NSString);
RCT_EXPORT_VIEW_PROPERTY(videoId, NSString);
RCT_EXPORT_VIEW_PROPERTY(autoPlay, BOOL);
RCT_EXPORT_VIEW_PROPERTY(play, BOOL);
RCT_EXPORT_VIEW_PROPERTY(fullscreen, BOOL);
RCT_EXPORT_VIEW_PROPERTY(disableDefaultControl, BOOL);
RCT_EXPORT_VIEW_PROPERTY(volume, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(bitRate, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(adVideoLoadTimeout, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(playbackRate, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(onAdsLoaded, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onPlay, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onPause, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onEnd, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onProgress, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onChangeDuration, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onUpdateBufferProgress, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onEnterFullscreen, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onExitFullscreen, RCTDirectEventBlock);

RCT_CUSTOM_VIEW_PROPERTY(settings, NSDictionary, BrightcoveIMAPlayerView) {
    if ([json isKindOfClass:[NSDictionary class]]) {
        [view setupWithSettings:json];
    }
}

RCT_EXPORT_METHOD(toggleFullscreen:(nonnull NSNumber *)reactTag isFullscreen:(BOOL)isFullscreen) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BrightcoveIMAPlayerView *player = (BrightcoveIMAPlayerView*)viewRegistry[reactTag];
        if ([player isKindOfClass:[BrightcoveIMAPlayerView class]]) {
            [player toggleFullscreen:isFullscreen];
        }
    }];
}

RCT_EXPORT_METHOD(toggleInViewPort:(nonnull NSNumber *)reactTag inViewPort:(BOOL)inViewPort) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BrightcoveIMAPlayerView *player = (BrightcoveIMAPlayerView*)viewRegistry[reactTag];
        if ([player isKindOfClass:[BrightcoveIMAPlayerView class]]) {
            [player toggleInViewPort:inViewPort];
        }
    }];
}

RCT_EXPORT_METHOD(seekTo:(nonnull NSNumber *)reactTag seconds:(nonnull NSNumber *)seconds) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BrightcoveIMAPlayerView *player = (BrightcoveIMAPlayerView*)viewRegistry[reactTag];
        if ([player isKindOfClass:[BrightcoveIMAPlayerView class]]) {
            [player seekTo:seconds];
        }
    }];
}

RCT_EXPORT_METHOD(play:(nonnull NSNumber *)reactTag) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BrightcoveIMAPlayerView *player = (BrightcoveIMAPlayerView*)viewRegistry[reactTag];
        if ([player isKindOfClass:[BrightcoveIMAPlayerView class]]) {
            [player play];
        }
    }];
}

RCT_EXPORT_METHOD(pause:(nonnull NSNumber *)reactTag) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BrightcoveIMAPlayerView *player = (BrightcoveIMAPlayerView*)viewRegistry[reactTag];
        if ([player isKindOfClass:[BrightcoveIMAPlayerView class]]) {
            [player pause];
        }
    }];
}

RCT_EXPORT_METHOD(stopPlayback:(nonnull NSNumber *)reactTag) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BrightcoveIMAPlayerView *player = (BrightcoveIMAPlayerView*)viewRegistry[reactTag];
        if ([player isKindOfClass:[BrightcoveIMAPlayerView class]]) {
            [player stopPlayback];
        }
    }];
}

RCT_EXPORT_METHOD(dispose:(nonnull NSNumber *)reactTag) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        BrightcoveIMAPlayerView *player = (BrightcoveIMAPlayerView*)viewRegistry[reactTag];
        if ([player isKindOfClass:[BrightcoveIMAPlayerView class]]) {
            [player dispose];
        }
    }];
}

@end
