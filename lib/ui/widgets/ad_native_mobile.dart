import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ad_config.dart';
import '../../theme/app_theme.dart';

class AdNativeWidget extends StatefulWidget {
  const AdNativeWidget({
    super.key,
    required this.isProUnlocked,
  });

  final bool isProUnlocked;

  @override
  State<AdNativeWidget> createState() => _AdNativeWidgetState();
}

class _AdNativeWidgetState extends State<AdNativeWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (!widget.isProUnlocked && _isMobilePlatform) {
      _loadNativeAd();
    }
  }

  @override
  void didUpdateWidget(covariant AdNativeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProUnlocked && !oldWidget.isProUnlocked) {
      _disposeAd();
    } else if (!widget.isProUnlocked &&
        oldWidget.isProUnlocked &&
        _isMobilePlatform) {
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    _disposeAd();
    final ad = NativeAd(
      adUnitId: AdConfig.resolveNativeUnitId(isIos: Platform.isIOS),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted || widget.isProUnlocked) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _nativeAd = loadedAd as NativeAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (failedAd, _) {
          failedAd.dispose();
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoaded = false;
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: AppColors.surface,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.racingOrange,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.brandNavy,
          backgroundColor: AppColors.surface,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textMuted,
          backgroundColor: AppColors.surface,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
    );
    ad.load();
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isProUnlocked || !_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 112,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
