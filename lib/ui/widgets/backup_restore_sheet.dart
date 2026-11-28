import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/garage_controller.dart';
import '../../theme/app_theme.dart';

Future<void> showBackupRestoreSheet({
  required BuildContext context,
  required GarageController controller,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _BackupRestoreSheet(controller: controller),
  );
}

class _BackupRestoreSheet extends StatefulWidget {
  const _BackupRestoreSheet({required this.controller});

  final GarageController controller;

  @override
  State<_BackupRestoreSheet> createState() => _BackupRestoreSheetState();
}

class _BackupRestoreSheetState extends State<_BackupRestoreSheet> {
  int _mode = 0; // 0 = Backup, 1 = Restore
  final TextEditingController _restoreController = TextEditingController();
  String? _errorMsg;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final s = ctrl.strings;
    final backupJson = ctrl.exportBackupJson();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sky.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.save_alt_rounded,
                    color: AppColors.sky,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.backupRestoreTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.backupRestoreSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text(s.backupTabLabel),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: const Icon(Icons.download_for_offline_rounded, size: 16),
                    label: Text(s.restoreTabLabel),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) => setState(() {
                  _mode = set.first;
                  _errorMsg = null;
                }),
              ),
            ),
            const SizedBox(height: 14),
            if (_mode == 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _countBadge(
                      '${ctrl.vehicles.length}',
                      s.subTabVehicles,
                      AppColors.sky,
                    ),
                    _countBadge(
                      '${ctrl.allFuelEntries.length}',
                      s.navFuel,
                      AppColors.emerald,
                    ),
                    _countBadge(
                      '${ctrl.allServiceEntries.length}',
                      s.navService,
                      AppColors.amber,
                    ),
                    _countBadge(
                      '${ctrl.inventoryItems.length}',
                      s.subTabStock,
                      AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      backupJson,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('copy_backup_json_btn'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: backupJson));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.backupCopied)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: Text(s.copyBackupJson),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.restoreWarning,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('restore_json_input'),
                controller: _restoreController,
                maxLines: 6,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                ),
                decoration: InputDecoration(
                  hintText: s.pasteBackupHint,
                  errorText: _errorMsg,
                ),
                onChanged: (_) {
                  if (_errorMsg != null) setState(() => _errorMsg = null);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          setState(() {
                            _restoreController.text = data!.text!;
                            _errorMsg = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.content_paste_rounded, size: 17),
                      label: Text(
                        s.pasteFromClipboard,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('restore_json_submit_btn'),
                      onPressed: () async {
                        final ok = await ctrl.importBackupJson(
                          _restoreController.text,
                        );
                        if (!ok) {
                          setState(() => _errorMsg = s.restoreInvalid);
                          return;
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.restoreSuccess)),
                          );
                        }
                      },
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: Text(s.restoreNow),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _countBadge(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
