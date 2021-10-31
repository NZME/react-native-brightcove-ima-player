package com.matejdr.brightcoveimaplayer;

import android.graphics.Color;
import android.text.format.DateUtils;
import android.util.Log;
import android.view.Choreographer;
import android.view.SurfaceView;
import android.view.View;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;
import androidx.core.view.ViewCompat;

import com.brightcove.ima.GoogleIMAComponent;
import com.brightcove.ima.GoogleIMAEventType;
import com.brightcove.player.display.ExoPlayerVideoDisplayComponent;
import com.brightcove.player.edge.Catalog;
import com.brightcove.player.edge.CatalogError;
import com.brightcove.player.edge.VideoListener;
import com.brightcove.player.event.Event;
import com.brightcove.player.event.EventEmitter;
import com.brightcove.player.event.EventListener;
import com.brightcove.player.event.EventType;
import com.brightcove.player.mediacontroller.BrightcoveMediaController;
import com.brightcove.player.mediacontroller.BrightcoveSeekBar;
import com.brightcove.player.model.Video;
import com.brightcove.player.view.BaseVideoView;
import com.brightcove.player.view.BrightcoveExoPlayerVideoView;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.google.ads.interactivemedia.v3.api.AdsManager;
import com.google.ads.interactivemedia.v3.api.AdsRequest;
import com.google.ads.interactivemedia.v3.api.ImaSdkFactory;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.MappingTrackSelector;
import com.matejdr.brightcoveimaplayer.util.FullScreenHandler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class BrightcoveIMAPlayerView extends RelativeLayout implements LifecycleEventListener {
  private final String TAG = this.getClass().getSimpleName();
  private final ThemedReactContext context;
  private final ReactApplicationContext applicationContext;
  private BrightcoveExoPlayerVideoView playerVideoView;
  private BrightcoveMediaController mediaController;
  private ReadableMap settings;
  private String policyKey;
  private String accountId;
  private String videoId;
  private boolean autoPlay = true;
  private boolean playing = false;
  private boolean adsPlaying = false;
  private int bitRate = 0;
  private int adVideoLoadTimeout = 3000;
  private float playbackRate = 1;
  private float lastAdPosition = -1;
  private EventEmitter eventEmitter;
  private GoogleIMAComponent googleIMAComponent;

  private FullScreenHandler fullScreenHandler;

  public BrightcoveIMAPlayerView(ThemedReactContext context, ReactApplicationContext applicationContext) {
    super(context);
    this.context = context;
    this.applicationContext = applicationContext;
    this.applicationContext.addLifecycleEventListener(this);
    this.setBackgroundColor(Color.BLACK);
    setup();
  }

  private void setup() {
    this.playerVideoView = new BrightcoveExoPlayerVideoView(this.context);

    this.addView(this.playerVideoView);
    this.playerVideoView.setLayoutParams(new RelativeLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
    this.playerVideoView.finishInitialization();

    this.requestLayout();

    this.fullScreenHandler = new FullScreenHandler(context, this.playerVideoView, this);
    this.mediaController = this.fullScreenHandler.initMediaController(this.playerVideoView);

    setupLayoutHack();

    ViewCompat.setTranslationZ(this, 9999);

    // *** This method call is optional *** //
    setupAdMarkers(this.playerVideoView);

    eventEmitter = this.playerVideoView.getEventEmitter();

    // Use a procedural abstraction to setup the Google IMA SDK via the plugin.
    setupGoogleIMA();

    eventEmitter.on(EventType.VIDEO_SIZE_KNOWN, new EventListener() {
      @Override
      public void processEvent(Event e) {
        fixVideoLayout();
        updateBitRate();
        updatePlaybackRate();
      }
    });
    eventEmitter.on(EventType.READY_TO_PLAY, new EventListener() {
      @Override
      public void processEvent(Event e) {
        WritableMap event = Arguments.createMap();
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_READY, event);
      }
    });
    eventEmitter.on(EventType.DID_PLAY, new EventListener() {
      @Override
      public void processEvent(Event e) {
        BrightcoveIMAPlayerView.this.playing = true;
        WritableMap event = Arguments.createMap();
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_PLAY, event);
      }
    });
    eventEmitter.on(EventType.DID_PAUSE, new EventListener() {
      @Override
      public void processEvent(Event e) {
        BrightcoveIMAPlayerView.this.playing = false;
        WritableMap event = Arguments.createMap();
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_PAUSE, event);
      }
    });
    eventEmitter.on(EventType.COMPLETED, new EventListener() {
      @Override
      public void processEvent(Event e) {
        WritableMap event = Arguments.createMap();
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_END, event);
      }
    });
    eventEmitter.on(EventType.PROGRESS, new EventListener() {
      @Override
      public void processEvent(Event e) {
        WritableMap event = Arguments.createMap();
        Integer playhead = (Integer) e.properties.get(Event.PLAYHEAD_POSITION);
        event.putDouble("currentTime", playhead / 1000d);
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_PROGRESS, event);
      }
    });
    eventEmitter.on(EventType.ENTER_FULL_SCREEN, new EventListener() {
      @Override
      public void processEvent(Event e) {
        mediaController.show();
        WritableMap event = Arguments.createMap();
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_TOGGLE_ANDROID_FULLSCREEN, event);
      }
    });
    eventEmitter.on(EventType.EXIT_FULL_SCREEN, new EventListener() {
      @Override
      public void processEvent(Event e) {
        mediaController.show();
        WritableMap event = Arguments.createMap();
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_TOGGLE_ANDROID_FULLSCREEN, event);
      }
    });
    eventEmitter.on(EventType.VIDEO_DURATION_CHANGED, new EventListener() {
      @Override
      public void processEvent(Event e) {
        Integer duration = (Integer) e.properties.get(Event.VIDEO_DURATION);
        WritableMap event = Arguments.createMap();
        event.putDouble("duration", duration / 1000d);
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_CHANGE_DURATION, event);
      }
    });
    eventEmitter.on(EventType.BUFFERED_UPDATE, new EventListener() {
      @Override
      public void processEvent(Event e) {
        Integer percentComplete = (Integer) e.properties.get(Event.PERCENT_COMPLETE);
        WritableMap event = Arguments.createMap();
        event.putDouble("bufferProgress", percentComplete / 100d);
        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_UPDATE_BUFFER_PROGRESS, event);
      }
    });
  }

  public void setSettings(ReadableMap settings) {
    this.settings = settings;
  }

  public void setPolicyKey(String policyKey) {
    this.policyKey = policyKey;
    this.loadVideo();
  }

  public void setAccountId(String accountId) {
    this.accountId = accountId;
    this.loadVideo();
  }

  public void setVideoId(String videoId) {
    this.videoId = videoId;
    this.loadVideo();
  }

  public void setAutoPlay(boolean autoPlay) {
    this.autoPlay = autoPlay;
  }

  public void setPlay(boolean play) {
    if (this.playing == play) return;
    if (play) {
      this.playerVideoView.start();
    } else {
      this.playerVideoView.pause();
    }
  }

  public void setDefaultControlDisabled(boolean disabled) {
    this.mediaController.hide();
    this.mediaController.setShowHideTimeout(disabled ? 1 : 4000);
  }

  public void setFullscreen(boolean fullscreen) {
    if (fullscreen) {
      this.fullScreenHandler.openFullscreenDialog();
      this.playerVideoView.getEventEmitter().emit(EventType.ENTER_FULL_SCREEN);
    } else {
      this.fullScreenHandler.closeFullscreenDialog();
      this.playerVideoView.getEventEmitter().emit(EventType.EXIT_FULL_SCREEN);
    }
//        this.mediaController.show();
//        WritableMap event = Arguments.createMap();
//        event.putBoolean("fullscreen", fullscreen);
//        ReactContext reactContext = (ReactContext) BrightcoveIMAPlayerView.this.getContext();
//        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(BrightcoveIMAPlayerView.this.getId(), BrightcoveIMAPlayerViewManager.EVENT_TOGGLE_ANDROID_FULLSCREEN, event);
  }

  public void toggleFullscreen(boolean isFullscreen) {
    if (isFullscreen) {
      this.fullScreenHandler.openFullscreenDialog();
    } else {
      this.fullScreenHandler.closeFullscreenDialog();
    }
  }

  public void setVolume(float volume) {
    Map<String, Object> details = new HashMap<>();
    details.put(Event.VOLUME, volume);
    this.playerVideoView.getEventEmitter().emit(EventType.SET_VOLUME, details);
  }

  /**/
  public void setBitRate(int bitRate) {
    this.bitRate = bitRate;
    this.updateBitRate();
  }

  public void setAdVideoLoadTimeout(int adVideoLoadTimeout) {
    this.adVideoLoadTimeout = adVideoLoadTimeout;
    this.loadVideo();
  }

  public void setPlaybackRate(float playbackRate) {
    if (playbackRate == 0) return;
    this.playbackRate = playbackRate;
    this.updatePlaybackRate();
  }

  public void seekTo(int time) {
    this.playerVideoView.seekTo(time);
  }

  //We need to stop the player to avoid a potential memory leak.
  public void stopPlayback() {
    if (this.playerVideoView != null) {
      this.playerVideoView.stopPlayback();
    }
  }

  public void pause() {
    if (this.playerVideoView != null) {
//            if (this.adsPlaying && this.googleIMAComponent != null) {
//                this.googleIMAComponent.getVideoAdPlayer().pauseAd();
//            }
      this.playerVideoView.pause();
    }
  }

  public void play() {
    if (this.playerVideoView != null) {
//            if (this.adsPlaying && this.googleIMAComponent != null) {
//                this.googleIMAComponent.getVideoAdPlayer().resumeAd();
//                this.playerVideoView.pause();
//            } else {
//                this.playerVideoView.start();
//            }
      this.playerVideoView.start();
    }
  }

  private void updateBitRate() {
    if (this.bitRate == 0) return;
    ExoPlayerVideoDisplayComponent videoDisplay = ((ExoPlayerVideoDisplayComponent) this.playerVideoView.getVideoDisplay());
    ExoPlayer player = videoDisplay.getExoPlayer();
    DefaultTrackSelector trackSelector = videoDisplay.getTrackSelector();
    if (player == null) return;
    MappingTrackSelector.MappedTrackInfo mappedTrackInfo = trackSelector.getCurrentMappedTrackInfo();
    if (mappedTrackInfo == null) return;

    DefaultTrackSelector.Parameters params = trackSelector.buildUponParameters().setMaxVideoBitrate(bitRate).build();
    trackSelector.setParameters(params);
  }

  private void updatePlaybackRate() {
    ExoPlayer expPlayer = ((ExoPlayerVideoDisplayComponent) this.playerVideoView.getVideoDisplay()).getExoPlayer();
    if (expPlayer != null) {
      expPlayer.setPlaybackParameters(new PlaybackParameters(playbackRate, 1f));
    }
  }

  private void loadVideo() {
    Catalog catalog = new Catalog.Builder(eventEmitter, this.accountId)
      .setPolicy(this.policyKey)
      .build();

    if (this.videoId != null) {
      catalog.findVideoByID(this.videoId, new VideoListener() {
        @Override
        public void onVideo(Video video) {
          playVideo(video);
        }

        @Override
        public void onError(@NonNull List<CatalogError> errors) {
          Log.e(TAG, errors.toString());
        }
      });
    }
  }

  private void playVideo(Video video) {
    BrightcoveIMAPlayerView.this.playerVideoView.clear();
    BrightcoveIMAPlayerView.this.playerVideoView.add(video);
    if (BrightcoveIMAPlayerView.this.autoPlay) {
      BrightcoveIMAPlayerView.this.playerVideoView.start();
    }
  }

  private void fixVideoLayout() {
    int viewWidth = this.getMeasuredWidth();
    int viewHeight = this.getMeasuredHeight();
    SurfaceView surfaceView = (SurfaceView) this.playerVideoView.getRenderView();
    surfaceView.measure(viewWidth, viewHeight);
    int surfaceWidth = surfaceView.getMeasuredWidth();
    int surfaceHeight = surfaceView.getMeasuredHeight();
    int leftOffset = (viewWidth - surfaceWidth) / 2;
    int topOffset = (viewHeight - surfaceHeight) / 2;
    surfaceView.layout(leftOffset, topOffset, leftOffset + surfaceWidth, topOffset + surfaceHeight);
  }

  /*
    This methods show how to the the Google IMA AdsManager, get the cue points and add the markers
    to the Brightcove Seek Bar.
   */
  private void setupAdMarkers(BaseVideoView videoView) {
//        final BrightcoveMediaController mediaController = new BrightcoveMediaController(this.playerVideoView);
    final BrightcoveMediaController mediaController = this.playerVideoView.getBrightcoveMediaController();

    // Add "Ad Markers" where the Ads Manager says ads will appear.
    mediaController.addListener(GoogleIMAEventType.ADS_MANAGER_LOADED, event -> {
      AdsManager manager = (AdsManager) event.properties.get("adsManager");
      List<Float> cuepoints = manager.getAdCuePoints();
      for (int i = 0; i < cuepoints.size(); i++) {
        Float cuepoint = cuepoints.get(i);
        BrightcoveSeekBar brightcoveSeekBar = mediaController.getBrightcoveSeekBar();
        // If cuepoint is negative it means it is a POST ROLL.
        int markerTime = cuepoint < 0 ? brightcoveSeekBar.getMax() : (int) (cuepoint * DateUtils.SECOND_IN_MILLIS);
        mediaController.getBrightcoveSeekBar().addMarker(markerTime);

      }
    });
    videoView.setMediaController(mediaController);
  }

  /**
   * Setup the Brightcove IMA Plugin.
   */
  private void setupGoogleIMA() {
    // Establish the Google IMA SDK factory instance.
    final ImaSdkFactory sdkFactory = ImaSdkFactory.getInstance();

    // TODO(matej): review this
    // Enable logging up ad start.
    eventEmitter.on(EventType.AD_STARTED, event -> {
      adsPlaying = true;
//        if (lastAdPosition > 0) {
//          googleIMAComponent.setAdPosition((int) (lastAdPosition * 1000));
//          lastAdPosition = -1;
//        }
    });
    // Enable logging any failed attempts to play an ad.
    eventEmitter.on(GoogleIMAEventType.DID_FAIL_TO_PLAY_AD, event -> adsPlaying = false);
    // Enable Logging upon ad completion.
    eventEmitter.on(EventType.AD_COMPLETED, event -> {
//      adsPlaying = false;
//      lastAdPosition = -1;
    });
    // Enable Logging upon ad break completion.
    eventEmitter.on(EventType.AD_BREAK_COMPLETED, event -> {
//      adsPlaying = false;
//      lastAdPosition = -1;
    });
    // Enable Logging upon ad progress.
    eventEmitter.on(EventType.AD_BREAK_STARTED, event -> {
      if (playing) {
        playerVideoView.pause();
      }
    });
    // Enable Logging upon ad progress.
    eventEmitter.on(EventType.AD_PAUSED, event -> {
//        if (googleIMAComponent != null) {
//          lastAdPosition = googleIMAComponent.getVideoAdPlayer().getAdProgress().getCurrentTime();
//        }
    });
    // Enable Logging upon ad progress.
    eventEmitter.on(EventType.AD_RESUMED, event -> {
//        if (lastAdPosition > 0 && googleIMAComponent != null) {
//          googleIMAComponent.setAdPosition((int) (lastAdPosition * 1000));
//          lastAdPosition = -1;
//        }
    });
    // Enable Logging upon ad progress.
    eventEmitter.on(EventType.AD_PROGRESS, event -> {
//        if (googleIMAComponent != null) {
//          float currentTime = googleIMAComponent.getVideoAdPlayer().getAdProgress().getCurrentTime();
//          if (currentTime > lastAdPosition) {
//            lastAdPosition = currentTime;
//          } else if (currentTime <= 0 && lastAdPosition > 0 && adsPlaying) {
//            googleIMAComponent.setAdPosition((int) (lastAdPosition * 1000));
//            lastAdPosition = -1;
//            googleIMAComponent.getVideoAdPlayer().resumeAd();
//          }
//        }

//        if (playing) {
//          playerVideoView.pause();
//        }
    });
//        eventEmitter.on(EventType.ANY, new EventListener() {
//            @Override
//            public void processEvent(Event event) {
//                Log.v(TAG + " matej", event.getType());
//            }
//        });

    // Set up a listener for initializing AdsRequests. The Google
    // IMA plugin emits an ad request event as a result of
    // initializeAdsRequests() being called.
    eventEmitter.on(GoogleIMAEventType.ADS_REQUEST_FOR_VIDEO, event -> {
      String IMAUrl = settings != null && settings.hasKey("IMAUrl") ?
        settings.getString("IMAUrl") : "";

      // Build an ads request object and point it to the ad
      // display container created above.
      AdsRequest adsRequest = sdkFactory.createAdsRequest();
      adsRequest.setAdTagUrl(IMAUrl);

      ArrayList<AdsRequest> adsRequests = new ArrayList<>(1);
      adsRequests.add(adsRequest);

      // Respond to the event with the new ad requests.
      event.properties.put(GoogleIMAComponent.ADS_REQUESTS, adsRequests);
      eventEmitter.respond(event);
    });

    // Create the Brightcove IMA Plugin and pass in the event
    // emitter so that the plugin can integrate with the SDK.
    googleIMAComponent = new GoogleIMAComponent.Builder(this.playerVideoView, eventEmitter)
      .setUseAdRules(true)
      .setLoadVideoTimeout(adVideoLoadTimeout)
      .build();
  }


  private void printKeys(Map<String, Object> map) {
    Log.d("debug", "-----------");
    for (Map.Entry<String, Object> entry : map.entrySet()) {
      Log.d("debug", entry.getKey());
    }
  }

  @Override
  public void onHostResume() {
//        if (this.adsPlaying && this.googleIMAComponent != null) {
//            this.googleIMAComponent.getVideoAdPlayer().resumeAd();
//            this.playerVideoView.pause();
//        } else
    if (this.playing && this.playerVideoView != null) {
      this.playerVideoView.start();
    }
  }

  @Override
  public void onHostPause() {
    this.pause();
  }

  @Override
  public void onHostDestroy() {
    this.playerVideoView.destroyDrawingCache();
    this.playerVideoView.clear();
    this.removeAllViews();
    this.applicationContext.removeLifecycleEventListener(this);
  }

  public void setupLayoutHack() {
    Choreographer.getInstance().postFrameCallback(new Choreographer.FrameCallback() {
      @Override
      public void doFrame(long frameTimeNanos) {
        manuallyLayoutChildren();
        getViewTreeObserver().dispatchOnGlobalLayout();
        Choreographer.getInstance().postFrameCallback(this);
      }
    });
  }

  private void manuallyLayoutChildren() {
    for (int i = 0; i < getChildCount(); i++) {
      View child = getChildAt(i);
      child.measure(MeasureSpec.makeMeasureSpec(getMeasuredWidth(), MeasureSpec.EXACTLY),
        MeasureSpec.makeMeasureSpec(getMeasuredHeight(), MeasureSpec.EXACTLY));
      child.layout(0, 0, child.getMeasuredWidth(), child.getMeasuredHeight());
    }
  }
}
