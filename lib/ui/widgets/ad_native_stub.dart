import 'package:flutter/material.dart';

class AdNativeWidget extends StatelessWidget {
  const AdNativeWidget({
    super.key,
    required this.isProUnlocked,
  });

  final bool isProUnlocked;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
