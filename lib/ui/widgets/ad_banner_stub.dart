import 'package:flutter/material.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({
    super.key,
    required this.isProUnlocked,
  });

  final bool isProUnlocked;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
