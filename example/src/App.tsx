import * as React from 'react';

import { StyleSheet, View, Text, Button, ScrollView } from 'react-native';
import {
  BrightcoveIMAPlayer,
  BrightcoveIMAPlayerPoster,
} from 'react-native-brightcove-ima-player';

const accountId = '5434391461001';
const videoId = '6140448705001';
const policyKey =
  'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L';
// VMAP Session Ad Rule Pre-roll
// const gam_video_url =
//   'https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&cust_params=sar%3Da0f2&unviewed_position_start=1&tfcd=0&npa=0&correlator=';
// VMAP Pre-roll
// const gam_video_url =
//   'https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpreonly&cmsid=496&vid=short_onecue&correlator=';
// VMAP Pre-roll + Bumper
// const gam_video_url =
//   'https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpreonlybumper&cmsid=496&vid=short_onecue&correlator=';
// VMAP Pre-, Mid-, and Post-rolls, Single Ads
const gam_video_url =
  'https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator=';

export default function App() {
  const videoPlayer = React.useRef<BrightcoveIMAPlayer>(null);
  const videoPlayerControlls = React.useRef<BrightcoveIMAPlayer>(null);

  const stopPlayback = () => {
    videoPlayer?.current?.stopPlayback();
  };

  const play = () => {
    videoPlayerControlls?.current?.play();
  };

  const pause = () => {
    videoPlayerControlls?.current?.pause();
  };

  const seekTo = () => {
    videoPlayerControlls?.current?.seekTo(5);
  };

  const fullscreen = () => {
    videoPlayerControlls?.current?.toggleFullscreen(true);
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.containerContent}
    >
      <View>
        <Text style={styles.headline}>Brightcove IMA Player Demo</Text>
      </View>
      <View style={styles.posterBg}>
        <View>
          <Text>Poster demo</Text>
        </View>
        <BrightcoveIMAPlayerPoster
          style={styles.poster}
          accountId={accountId}
          policyKey={policyKey}
          videoId={videoId}
        />
      </View>
      <View style={styles.videoBg}>
        <View>
          <Text>Player demo</Text>
        </View>
        <BrightcoveIMAPlayer
          ref={videoPlayer}
          style={styles.video}
          accountId={accountId}
          policyKey={policyKey}
          videoId={videoId}
          // autoPlay={true}
          settings={{
            IMAUrl: gam_video_url,
            autoAdvance: false,
            autoPlay: false, // initial autoPlay prop
            allowsExternalPlayback: true,
            publisherProvidedID: 'insertyourpidhere',
          }}
        />
      </View>
      <Button title={'Stop Playback'} onPress={stopPlayback} />
      <View style={styles.videoBg}>
        <View>
          <Text>Player controls demo</Text>
        </View>
        <BrightcoveIMAPlayer
          disableDefaultControl={true}
          ref={videoPlayerControlls}
          style={styles.video}
          accountId={accountId}
          policyKey={policyKey}
          videoId={videoId}
          // autoPlay={true}
          settings={{
            IMAUrl: gam_video_url,
            autoAdvance: false,
            autoPlay: false, // initial autoPlay prop
            allowsExternalPlayback: true,
            publisherProvidedID: 'insertyourpidhere',
          }}
        />
      </View>
      <Button title={'Play'} onPress={play} />
      <Button title={'Pause'} onPress={pause} />
      <Button title={'Seek to 5s'} onPress={seekTo} />
      <Button title={'Full screen'} onPress={fullscreen} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  containerContent: {
    paddingVertical: 40,
  },
  headline: {
    fontSize: 24,
    padding: 10,
  },
  posterBg: {
    backgroundColor: '#b8b8b8',
    padding: 10,
  },
  poster: {
    width: '100%',
    height: 200,
    marginVertical: 20,
  },
  videoBg: {
    backgroundColor: '#5f5f5f',
    padding: 10,
  },
  video: {
    width: '100%',
    height: 200,
    marginVertical: 20,
  },
});
