import React, { Component } from 'react';
import {
  requireNativeComponent,
  UIManager,
  Platform,
  ViewProps,
} from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-brightcove-ima-player' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

type BrightcoveIMAPlayerPosterProps = ViewProps & {
  accountId: string;
  policyKey: string;
  videoId: string;
  resizeMode?: 'contain' | 'fit' | 'cover';
};

const ComponentName = 'BrightcoveIMAPlayerPosterView';

const BrightcoveIMAPlayerPosterView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<BrightcoveIMAPlayerPosterProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

export class BrightcoveIMAPlayerPoster extends Component<BrightcoveIMAPlayerPosterProps> {
  render() {
    return <BrightcoveIMAPlayerPosterView {...this.props} />;
  }
}
