import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/garage_controller.dart';
import '../theme/app_theme.dart';
import 'screens/first_run_setup_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/fuel_tab.dart';
import 'tabs/garage_tab.dart';
import 'tabs/service_tab.dart';
import 'widgets/ad_banner_widget.dart';
import 'widgets/branded_splash_screen.dart';
import 'widgets/push_notification_banner.dart';

class GarageShell extends StatefulWidget {
  const GarageShell({
    super.key,
    required this.controller,
    this.enableSplashDelay = false,
  });

  final GarageController controller;
  final bool enableSplashDelay;

  @override
  State<GarageShell> createState() => _GarageShellState();
}

class _GarageShellState extends State<GarageShell> {
  int _tabIndex = 0;
  bool _splashHolding = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enableSplashDelay) {
      _splashHolding = true;
      _splashTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() => _splashHolding = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final s = ctrl.strings;

        if (!ctrl.isLoaded || _splashHolding) {
          return const BrandedSplashScreen();
        }

        if (ctrl.needsInitialSetup) {
          return FirstRunSetupScreen(controller: ctrl);
        }

        final pages = [
          DashboardTab(
            controller: ctrl,
            onNavigateToGarage: () => setState(() => _tabIndex = 3),
          ),
          FuelTab(controller: ctrl),
          ServiceTab(controller: ctrl),
          GarageTab(controller: ctrl),
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            toolbarHeight: 62,
            titleSpacing: 16,
            shape: const Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/app_logo_mark.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Garage',
                                  style: TextStyle(color: AppColors.brandNavy),
                                ),
                                TextSpan(
                                  text: 'Log',
                                  style:
                                      TextStyle(color: AppColors.racingOrange),
                                ),
                              ],
                            ),
                          ),
                          if (ctrl.isProUnlocked) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.amber.withOpacity(0.6),
                                ),
                              ),
                              child: Text(
                                s.proActive,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        ctrl.masterProfile.garageName.trim().isNotEmpty
                            ? ctrl.masterProfile.garageName.trim()
                            : s.appSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Quick Push Notification Test / Alert Preview button
              IconButton(
                key: const Key('appbar_test_notif_btn'),
                tooltip: s.testNotificationBtn,
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final res = await ctrl.triggerTestReminderNotification();
                  if (context.mounted) {
                    showInAppPushBanner(
                      context: context,
                      title: res.title,
                      body: res.body,
                      timeLabel: s.notifNowLabel,
                      footerHint: res.nativeDelivered
                          ? s.notifSentNative
                          : s.notifPreviewHint,
                    );
                  }
                },
                icon: Icon(
                  ctrl.notificationsEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: ctrl.notificationsEnabled
                      ? AppColors.racingOrange
                      : AppColors.textMuted,
                  size: 21,
                ),
              ),
              // Quick Currency Toggle (Rp / $)
              _QuickTogglePill(
                key: const Key('currency_toggle_button'),
                label: ctrl.currency == AppCurrency.idr ? 'Rp' : '\$',
                onTap: ctrl.toggleCurrency,
                accent: AppColors.sky,
              ),
              const SizedBox(width: 6),
              // Quick Language Toggle (ID / EN)
              _QuickTogglePill(
                key: const Key('lang_toggle_button'),
                label: ctrl.language == AppLanguage.id ? 'ID' : 'EN',
                onTap: ctrl.toggleLanguage,
                accent: AppColors.racingOrange,
              ),
              const SizedBox(width: 12),
            ],
            bottom: ctrl.vehicles.length > 1
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(44),
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: ctrl.vehicles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final v = ctrl.vehicles[idx];
                          final active = v.id == ctrl.activeVehicle?.id;
                          return ChoiceChip(
                            label: Text('${v.name} (${v.plateNumber})'),
                            selected: active,
                            selectedColor:
                                AppColors.racingOrange.withOpacity(0.22),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? AppColors.racingOrange
                                  : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: active
                                  ? AppColors.racingOrange
                                  : AppColors.border,
                            ),
                            onSelected: (_) => ctrl.selectVehicle(v.id),
                          );
                        },
                      ),
                    ),
                  )
                : null,
          ),
          body: IndexedStack(
            index: _tabIndex,
            children: pages,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdBannerWidget(isProUnlocked: ctrl.isProUnlocked),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _tabIndex,
                  backgroundColor: AppColors.surface,
                  indicatorColor: AppColors.racingOrange.withOpacity(0.2),
                  surfaceTintColor: Colors.transparent,
                  height: 66,
                  onDestinationSelected: (i) => setState(() => _tabIndex = i),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(
                        Icons.dashboard_rounded,
                        color: AppColors.racingOrange,
                      ),
                      label: s.navDashboard,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.local_gas_station_outlined),
                      selectedIcon: const Icon(
                        Icons.local_gas_station_rounded,
                        color: AppColors.emerald,
                      ),
                      label: s.navFuel,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.build_outlined),
                      selectedIcon: const Icon(
                        Icons.build_rounded,
                        color: AppColors.sky,
                      ),
                      label: s.navService,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.garage_outlined),
                      selectedIcon: const Icon(
                        Icons.garage_rounded,
                        color: AppColors.racingOrange,
                      ),
                      label: s.navGarage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickTogglePill extends StatelessWidget {
  const _QuickTogglePill({
    super.key,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.45)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
    );
  }
}
