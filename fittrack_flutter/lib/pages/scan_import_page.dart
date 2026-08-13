import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/storage.dart';
import '../services/share_code_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';

class ScanImportPage extends StatefulWidget {
  const ScanImportPage({super.key});

  @override
  State<ScanImportPage> createState() => _ScanImportPageState();
}

class _ScanImportPageState extends State<ScanImportPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    '将二维码对准框内即可自动扫描',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _processed = true;
    _controller.stop();

    final result = ShareCodeService.instance.importFromString(raw);
    if (!mounted) return;

    final ft = Theme.of(context).extension<LiftTrackColors>()!;

    if (result.result == ShareCodeResult.success && result.planData != null) {
      _doImport(result.planData!, result.warning, ft);
    } else {
      String errorMsg;
      switch (result.result) {
        case ShareCodeResult.invalidFormat:
          errorMsg = '二维码格式无效，不是有效的计划分享码';
          break;
        case ShareCodeResult.invalidSignature:
          errorMsg = '分享码签名无效，可能已损坏';
          break;
        case ShareCodeResult.decodeError:
          errorMsg = '解析失败，二维码可能不完整';
          break;
        default:
          errorMsg = '导入失败，请重试';
      }
      FitToast.error(context, errorMsg);
      setState(() => _processed = false);
      _controller.start();
    }
  }

  void _doImport(Map<String, dynamic> planData, ImportWarning warning, LiftTrackColors ft) {
    if (warning == ImportWarning.excessiveVolume || warning == ImportWarning.excessiveFrequency) {
      ConfirmDialog.show(
        context,
        title: warning == ImportWarning.excessiveVolume ? '训练量偏大' : '训练频率偏高',
        content: warning == ImportWarning.excessiveVolume
            ? '该计划单日训练组数超过50组，可能不适合新手。确定要导入吗？'
            : '该计划每周训练超过7次，恢复压力较大。确定要导入吗？',
        confirmText: '确定导入',
        cancelText: '取消',
        confirmColor: ft.warningColor,
        icon: Icons.warning_amber_rounded,
      ).then((confirmed) {
        if (confirmed == true) {
          _executeImport(planData);
        } else {
          setState(() => _processed = false);
          _controller.start();
        }
      });
    } else {
      _executeImport(planData);
    }
  }

  void _executeImport(Map<String, dynamic> planData) {
    final newPlan = ShareCodeService.deepNormalizePlan(planData);
    newPlan.remove('author');
    newPlan.remove('sharedAt');
    newPlan['status'] = 'active';
    newPlan['progress'] = 0;
    newPlan['currentDayIndex'] = 0;
    ShareCodeService.normalizeWeightFieldsPublic(newPlan);

    Storage.addPlan(newPlan);

    final author = ShareCodeService.instance.getAuthor(planData);
    FitToast.success(
      context,
      author != null
          ? '已导入「${planData['name'] ?? '计划'}」（来自$author）'
          : '已导入「${planData['name'] ?? '计划'}」',
    );

    Navigator.of(context).pop();
  }
}
