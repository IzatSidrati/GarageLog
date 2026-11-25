import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/garage_controller.dart';
import '../theme/app_theme.dart';
import 'screens/first_run_setup_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/fuel_tab.dart';
import 'tabs/garage_tab.dart';
import 'tabs/service_tab.dart';

class GarageShell extends StatefulWidget {
  const GarageShell({
    super.key,
    required this.controller,
  });

  final GarageController controller;

  @override
  State<GarageShell> createState() => _GarageShellState();
}

class _GarageShellState extends State<GarageShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final s = ctrl.strings;

        if (!ctrl.isLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.sky),
            ),
          );
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
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.sky, AppColors.emerald],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.speed_rounded,
                    color: Color(0xFF04131E),
                    size: 20,
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
                          Text(
                            s.appTitle,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
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
                            ? '${ctrl.masterProfile.garageName.trim()} • ${s.offlineBadge}'
                            : s.offlineBadge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Quick Currency Toggle (Rp / $)
              _QuickTogglePill(
                key: const Key('currency_toggle_button'),
                label: ctrl.currency == AppCurrency.idr ? 'Rp' : '\$',
                onTap: ctrl.toggleCurrency,
                accent: AppColors.emerald,
              ),
              const SizedBox(width: 6),
              // Quick Language Toggle (ID / EN)
              _QuickTogglePill(
                key: const Key('lang_toggle_button'),
                label: ctrl.language == AppLanguage.id ? 'ID' : 'EN',
                onTap: ctrl.toggleLanguage,
                accent: AppColors.sky,
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
                            selectedColor: AppColors.sky.withOpacity(0.22),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? AppColors.sky
                                  : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: active ? AppColors.sky : AppColors.border,
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
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _tabIndex,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.sky.withOpacity(0.18),
              surfaceTintColor: Colors.transparent,
              height: 66,
              onDestinationSelected: (i) => setState(() => _tabIndex = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon:
                      const Icon(Icons.dashboard_rounded, color: AppColors.sky),
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
                  selectedIcon:
                      const Icon(Icons.build_rounded, color: AppColors.amber),
                  label: s.navService,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.garage_outlined),
                  selectedIcon:
                      const Icon(Icons.garage_rounded, color: AppColors.sky),
                  label: s.navGarage,
                ),
              ],
            ),
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
