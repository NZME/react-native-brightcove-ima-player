import * as React from 'react';

import { StyleSheet, View } from 'react-native';
import {
  BrightcoveIMAPlayer,
  BrightcoveIMAPlayerPoster,
} from 'react-native-brightcove-ima-player';

const accountId = '1308227299001';
const policyKey =
  'BCpkADawqM2y6-Am7ImPI7GefImBwWww7W4WC53cN-Dp5yDuTTYic0SE7zOciUar3GPtzRZVmFaHi7Y_lw_pk-1he4JMbkKGVl9LBmIDLKafgXAesc8itDvIJbkSLdx4Kx6H9V_noezGNEx-';
const videoId = '6119603765001';
const gam_video_url =
  'https://pubads.g.doubleclick.net/gampad/ads?iu=/83069739/jeff&description_url=http%3A%2F%2Fnzme.co.nz&env=vp&impl=s&correlator=&tfcd=0&npa=0&gdfp_req=1&output=vast&sz=620x350&unviewed_position_start=1';
// const gam_video_url =
//   'https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator=';

export default function App() {
  return (
    <View style={styles.container}>
      <BrightcoveIMAPlayerPoster
        accountId={accountId}
        policyKey={policyKey}
        videoId={videoId}
      />
      <BrightcoveIMAPlayer
        accountId={accountId}
        policyKey={policyKey}
        videoId={videoId}
        settings={{
          IMAUrl: gam_video_url,
          autoAdvance: false,
          autoPlay: true, // initial autoPlay prop
          allowsExternalPlayback: true,
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
