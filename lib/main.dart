import 'package:flutter/material.dart';

import 'state/garage_controller.dart';
import 'theme/app_theme.dart';
import 'ui/garage_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = GarageController();
  controller.init();
  runApp(GarageLogApp(controller: controller));
}

class GarageLogApp extends StatelessWidget {
  const GarageLogApp({
    super.key,
    required this.controller,
  });

  final GarageController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GarageLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideDesktop = constraints.maxWidth > 520;
            return ColoredBox(
              color: AppColors.outerBackdrop,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    decoration: isWideDesktop
                        ? BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: AppColors.border.withOpacity(0.85),
                                width: 1,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          )
                        : null,
                    clipBehavior: isWideDesktop ? Clip.antiAlias : Clip.none,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
      home: GarageShell(controller: controller),
    );
  }
}
