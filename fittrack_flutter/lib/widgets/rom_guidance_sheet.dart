import 'package:flutter/material.dart';
import '../services/rom_adaptation_service.dart';
import '../themes/app_themes.dart';

class RomGuidanceSheet extends StatefulWidget {
  final VoidCallback? onDismiss;

  const RomGuidanceSheet({super.key, this.onDismiss});

  static Future<void> show(BuildContext context, {VoidCallback? onDismiss}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RomGuidanceSheet(onDismiss: onDismiss),
    );
  }

  @override
  State<RomGuidanceSheet> createState() => _RomGuidanceSheetState();
}

class _RomGuidanceSheetState extends State<RomGuidanceSheet> {
  String _title = '请确保 FitTrack 允许后台运行';
  String _steps = '请确保 FitTrack 允许后台运行和自启动';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGuidance();
  }

  Future<void> _loadGuidance() async {
    final romService = RomAdaptationService.instance;
    final title = await romService.guidanceTitle;
    final steps = await romService.guidanceSteps;
    if (mounted) {
      setState(() {
        _title = title;
        _steps = steps;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final romService = RomAdaptationService.instance;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: colors.borderColor)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.notifications_active,
                      color: colors.accentGlow, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _loading ? '正在检测...' : _title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderColor),
                ),
                child: _loading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _steps,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  FutureBuilder<bool>(
                    future: romService.isOemRom,
                    builder: (context, snapshot) {
                      final isOem = snapshot.data ?? false;
                      if (!isOem) return const SizedBox.shrink();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: OutlinedButton(
                            onPressed: () {
                              romService.openAutoStartSettings();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              '去开启自启动',
                              style: TextStyle(color: colors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        romService.requestIgnoreBatteryOptimizations();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '关闭电池优化',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDismiss?.call();
                },
                child: Text(
                  '稍后设置',
                  style: TextStyle(color: colors.textMuted, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
