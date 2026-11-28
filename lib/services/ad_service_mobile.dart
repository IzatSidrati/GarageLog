import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  const AdService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // Offline or unsupported environment: fail silently without blocking app startup.
    }
  }
}
