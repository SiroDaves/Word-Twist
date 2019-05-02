import 'dart:io';

class AdMobConfig {
  static String adMobAppId = '';
  static String rewardedAdId = '';

  static String get getRewardedAdId {
    if (isInDebugMode) {
      return Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
    } else {
      return rewardedAdId;
    }
  }

  static bool get isInDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}
