import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

void showInAppPushBanner({
  required BuildContext context,
  required String title,
  required String body,
  required String timeLabel,
  String? footerHint,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry entry;
  var removed = false;

  void dismiss() {
    if (!removed) {
      removed = true;
      entry.remove();
    }
  }

  entry = OverlayEntry(
    builder: (ctx) => _PushBannerOverlay(
      title: title,
      body: body,
      timeLabel: timeLabel,
      footerHint: footerHint,
      onDismiss: dismiss,
    ),
  );

  overlay.insert(entry);
  Timer(const Duration(seconds: 5), dismiss);
}

class _PushBannerOverlay extends StatefulWidget {
  const _PushBannerOverlay({
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.onDismiss,
    this.footerHint,
  });

  final String title;
  final String body;
  final String timeLabel;
  final String? footerHint;
  final VoidCallback onDismiss;

  @override
  State<_PushBannerOverlay> createState() => _PushBannerOverlayState();
}

class _PushBannerOverlayState extends State<_PushBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 14,
      right: 14,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 472),
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismiss,
                onVerticalDragEnd: (_) => widget.onDismiss(),
                child: Container(
                  key: const Key('push_notification_banner'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.racingOrange.withOpacity(0.55),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandNavy.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'assets/icon/app_logo_mark.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'GarageLog',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandNavy,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.timeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.body,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.footerHint != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.footerHint!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.racingOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
