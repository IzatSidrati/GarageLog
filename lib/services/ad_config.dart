import 'package:flutter/foundation.dart';

class AdConfig {
  const AdConfig._();

  // Production AdMob IDs for GarageLog
  static const String appId = 'ca-app-pub-9171274707010006~2398578292';
  static const String prodBannerUnitId =
      'ca-app-pub-9171274707010006/3819471178';
  static const String prodNativeUnitId =
      'ca-app-pub-9171274707010006/5681161843';

  // Google Official Test Ad Unit IDs (used automatically in Debug/Profile builds
  // to comply with AdMob policy and prevent accidental invalid-traffic bans).
  static const String androidTestBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidTestNativeUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String iosTestBannerUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String iosTestNativeUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  static String resolveBannerUnitId({
    bool isReleaseMode = kReleaseMode,
    required bool isIos,
  }) {
    if (isReleaseMode) return prodBannerUnitId;
    return isIos ? iosTestBannerUnitId : androidTestBannerUnitId;
  }

  static String resolveNativeUnitId({
    bool isReleaseMode = kReleaseMode,
    required bool isIos,
  }) {
    if (isReleaseMode) return prodNativeUnitId;
    return isIos ? iosTestNativeUnitId : androidTestNativeUnitId;
  }
}
