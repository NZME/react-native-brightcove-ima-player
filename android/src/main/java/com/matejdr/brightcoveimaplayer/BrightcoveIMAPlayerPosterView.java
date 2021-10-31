package com.matejdr.brightcoveimaplayer;

import android.annotation.SuppressLint;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import com.brightcove.player.edge.Catalog;
import com.brightcove.player.edge.OfflineCatalog;
import com.brightcove.player.edge.VideoListener;
import com.brightcove.player.model.Video;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ThemedReactContext;
import com.matejdr.brightcoveimaplayer.util.DefaultEventEmitter;
import com.matejdr.brightcoveimaplayer.util.ImageLoader;

public class BrightcoveIMAPlayerPosterView extends RelativeLayout implements LifecycleEventListener {
  private final ReactApplicationContext applicationContext;
  private final ImageView imageView;
  private String policyKey;
  private String accountId;
  private String videoId;
  private OfflineCatalog offlineCatalog;
  private ImageLoader imageLoader;

  public BrightcoveIMAPlayerPosterView(ThemedReactContext context, ReactApplicationContext applicationContext) {
    super(context);
    this.applicationContext = applicationContext;
    this.applicationContext.addLifecycleEventListener(this);
    this.imageView = new ImageView(context);
    this.imageView.setLayoutParams(new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
    this.imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
    this.addView(imageView);
    this.requestLayout();
  }

  public void setPolicyKey(String policyKey) {
    this.policyKey = policyKey;
    this.loadPoster();
  }

  public void setAccountId(String accountId) {
    this.accountId = accountId;
    this.loadPoster();
  }

  public void setVideoId(String videoId) {
    this.videoId = videoId;
    this.loadPoster();
  }

  public void setResizeMode(String resizeMode) {
    if ("contain".equals(resizeMode)) {
      this.imageView.setScaleType(ImageView.ScaleType.FIT_CENTER);
    } else if ("fit".equals(resizeMode)) {
      this.imageView.setScaleType(ImageView.ScaleType.FIT_XY);
    } else {
      this.imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
    }
  }

  private void loadPoster() {
    VideoListener listener = new VideoListener() {
      @Override
      public void onVideo(Video video) {
        loadImage(video);
      }
    };
    Catalog catalog = new Catalog(DefaultEventEmitter.sharedEventEmitter, this.accountId, this.policyKey);
    if (this.videoId != null) {
      catalog.findVideoByID(this.videoId, listener);
    }
  }

  private void loadImage(Video video) {
    if (video == null) {
      this.imageView.setImageResource(android.R.color.transparent);
      return;
    }
    String url = video.getPosterImage().toString();
    if (url == null) {
      this.imageView.setImageResource(android.R.color.transparent);
      return;
    }
    if (this.imageLoader != null) {
      this.imageLoader.cancel(true);
    }
    this.imageLoader = new ImageLoader(this.imageView);
    this.imageLoader.execute(url);
  }

  @Override
  public void onHostResume() {

  }

  @Override
  public void onHostPause() {

  }

  @Override
  public void onHostDestroy() {
    if (this.imageLoader != null) {
      this.imageLoader.cancel(true);
    }
    this.applicationContext.removeLifecycleEventListener(this);
  }
}
