package com.matejdr.brightcoveimaplayer;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;


public class BrightcoveIMAPlayerPosterViewManager extends SimpleViewManager<BrightcoveIMAPlayerPosterView> {
  public static final String REACT_CLASS = "BrightcoveIMAPlayerPosterView";

  private final ReactApplicationContext applicationContext;

  public BrightcoveIMAPlayerPosterViewManager(ReactApplicationContext context) {
    this.applicationContext = context;
  }


  @Override
  public String getName() {
    return REACT_CLASS;
  }

  @Override
  public BrightcoveIMAPlayerPosterView createViewInstance(ThemedReactContext ctx) {
    return new BrightcoveIMAPlayerPosterView(ctx, applicationContext);
  }

  @ReactProp(name = "accountId")
  public void setAccountId(BrightcoveIMAPlayerPosterView view, String accountId) {
    view.setAccountId(accountId);
  }

  @ReactProp(name = "policyKey")
  public void setPolicyKey(BrightcoveIMAPlayerPosterView view, String policyKey) {
    view.setPolicyKey(policyKey);
  }

  @ReactProp(name = "videoId")
  public void setVideoId(BrightcoveIMAPlayerPosterView view, String videoId) {
    view.setVideoId(videoId);
  }

  @ReactProp(name = "resizeMode")
  public void setResizeMode(BrightcoveIMAPlayerPosterView view, String resizeMode) {
    view.setResizeMode(resizeMode);
  }
}
