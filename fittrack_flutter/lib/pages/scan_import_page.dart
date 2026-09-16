import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zxing2/qrcode.dart';
import '../data/storage.dart';
import '../utils/platform_utils.dart';
import '../services/share_code_service.dart';
import '../services/rom_adaptation_service.dart';
import '../services/ohos_scan_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';

import '../l10n/i18n.dart';
class ScanImportPage extends StatefulWidget {
  const ScanImportPage({super.key});

  @override
  State<ScanImportPage> createState() => _ScanImportPageState();
}

class _ScanImportPageState extends State<ScanImportPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processed = false;
  bool _cameraFailed = false;
  bool _picking = false;
  // 相机权限状态
  bool _permissionChecked = false;
  bool _cameraAllowed = false;
  // 是否仅支持相册扫码（OHOS 或鸿蒙兼容层设备）：直接走相册兜底，不申请相机权限
  bool _galleryOnly = isOhos;
  // OHOS 原生扫码（Scan Kit 系统扫码界面）可用性：
  // mobile_scanner 在 OHOS 无原生实现，相机扫码改用系统扫码界面；true 时页面自动拉起
  bool _ohosScanSupported = isOhos;
  // 原生扫码进行中（显示"正在启动相机扫码"）
  bool _nativeScanning = false;

  bool get _cameraActive => _permissionChecked && _cameraAllowed && !_cameraFailed;

  /// OHOS 无 mobile_scanner 原生实现，相机扫码不可用，直接走相册兜底
  bool get _cameraUnsupported => _galleryOnly;

  @override
  void initState() {
    super.initState();
    _initCameraPermission();
    if (_ohosScanSupported) {
      // OHOS：页面出现后自动拉起系统扫码界面（Scan Kit 默认界面扫码）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _startNativeScan();
        });
      });
    }
  }

  /// 启动时申请相机权限（Android/iOS 运行时授权；OHOS 及鸿蒙兼容层直接走相册兜底）
  Future<void> _initCameraPermission() async {
    if (!isOhos) {
      // Android 包跑在鸿蒙机上时：原生侧识别到鸿蒙则视为相机不可用，避免弹出相机权限
      final harmony = await RomAdaptationService.instance.isHarmonyOSDevice();
      if (harmony && mounted) setState(() => _galleryOnly = true);
    }
    if (_galleryOnly) {
      if (mounted) {
        setState(() {
          _permissionChecked = true;
          _cameraAllowed = false;
        });
      }
      return;
    }
    final allowed = await _requestCameraPermission();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _cameraAllowed = allowed;
    });
  }

  /// 申请相机权限，返回是否已授权
  Future<bool> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) return false;
      final result = await Permission.camera.request();
      return result.isGranted;
    } catch (_) {
      // 平台未实现（如桌面/测试环境）：不阻塞进入相机，交给相机控件自行失败并走相册兜底
      return true;
    }
  }

  /// 权限被拒后手动重试授权
  Future<void> _retryPermission() async {
    final allowed = await _requestCameraPermission();
    if (!mounted) return;
    setState(() {
      _cameraAllowed = allowed;
      if (allowed) _cameraFailed = false;
    });
  }

  /// OHOS：调用原生 Scan Kit 启动系统扫码界面
  ///
  /// - 识别成功：交由 [_handleDecoded] 解析导入
  /// - 用户取消：回到本页显示兜底引导（可重试相机扫码或从相册选图）
  /// - 原生侧未接入 Scan Kit 通道：降级为纯相册兜底
  Future<void> _startNativeScan() async {
    if (_nativeScanning || _processed) return;
    setState(() => _nativeScanning = true);
    try {
      final raw = await OhosScanService.instance.scan();
      if (raw == null || raw.isEmpty) {
        if (mounted) setState(() => _nativeScanning = false);
        return;
      }
      // 复位后再解析：解析失败（无效码/用户取消确认）时页面停留在兜底引导而非"启动中"
      if (mounted) setState(() => _nativeScanning = false);
      _handleDecoded(raw);
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _ohosScanSupported = false;
          _nativeScanning = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _nativeScanning = false);
        if (e.code != 'USER_CANCELED') {
          FitToast.error(context, tr(context, '无法启动相机扫码，请重试'));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _nativeScanning = false);
    }
  }

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
                if (_ohosScanSupported)
                  _nativeScanning ? _buildNativeScanLoading() : _buildOhosScanFallback()
                else if (_cameraUnsupported)
                  _buildGalleryFallback()
                else if (!_permissionChecked)
                  _buildPermissionLoading()
                else if (!_cameraAllowed)
                  _buildPermissionDenied()
                else if (_cameraFailed)
                  _buildCameraFallback()
                else
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) => _buildCameraFallback(),
                  ),
                Center(
                  child: !_cameraActive
                      ? const SizedBox.shrink()
                      : Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white70, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 88,
                  left: 0,
                  right: 0,
                  child: !_cameraActive
                      ? const SizedBox.shrink()
                      : Text(
                          tr(context, '将二维码对准框内即可自动扫描'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                        ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    // OHOS 原生扫码时底部按钮隐藏，由 _buildOhosScanFallback 提供操作入口
                    child: _ohosScanSupported
                        ? const SizedBox.shrink()
                        : ElevatedButton.icon(
                            onPressed: _picking ? null : _pickQrImage,
                            icon: _picking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.photo_library_outlined, size: 18),
                            label: Text(_picking ? tr(context, '识别中...') : tr(context, '从相册选择二维码图片')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// OHOS：正在拉起系统扫码界面
  Widget _buildNativeScanLoading() {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white70),
          const SizedBox(height: 12),
          Text(tr(context, '正在启动相机扫码...'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  /// OHOS：系统扫码取消/失败后的引导（可重试相机扫码或从相册选图）
  Widget _buildOhosScanFallback() {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 56, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            tr(context, '使用相机扫码'),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, '点击"相机扫码"启动系统扫码，或从相册选择二维码图片。'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _nativeScanning ? null : _startNativeScan,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(_nativeScanning ? tr(context, '启动中...') : tr(context, '相机扫码')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _picking ? null : _pickQrImage,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(tr(context, '从相册选择二维码图片')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  /// 权限请求中
  Widget _buildPermissionLoading() {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white70),
          const SizedBox(height: 12),
          Text(tr(context, '正在申请相机权限...'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  /// 相机不支持平台（OHOS）时的引导：直接指向从相册选择二维码图片
  Widget _buildGalleryFallback() {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_outlined, size: 56, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            tr(context, '使用相册扫码'),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, '当前设备暂不支持相机扫码，请从相册选择二维码图片进行识别导入。'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _picking ? null : _pickQrImage,
            icon: _picking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(_picking ? tr(context, '识别中...') : tr(context, '从相册选择二维码图片')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
          ),
        ],
      ),
    );
  }

  /// 相机权限被拒时的引导（保留从相册选图入口）
  Widget _buildPermissionDenied() {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 56, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            tr(context, '需要相机权限'),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, '用于扫描二维码导入计划。您也可以使用下方"从相册选择二维码图片"导入。'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _retryPermission,
            icon: const Icon(Icons.lock_open, size: 18),
            label: Text(tr(context, '授权相机')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  /// 相机不可用（无权限 / 平台不支持）时的兜底引导
  Widget _buildCameraFallback() {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 56, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            tr(context, '无法启动相机'),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, '请检查相机权限，或使用下方"从相册选择二维码图片"导入'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              setState(() => _cameraFailed = false);
              try {
                await _controller.start();
              } catch (_) {
                if (mounted) setState(() => _cameraFailed = true);
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(tr(context, '重试相机')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  /// 从相册选择二维码图片并解析（纯 Dart 解码，兼容不支持摄像头的平台）
  Future<void> _pickQrImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery);
      if (xfile == null || !mounted) return;

      final bytes = await xfile.readAsBytes();
      final rawText = await _decodeQrFromBytes(bytes);
      if (rawText == null || rawText.isEmpty) {
        if (mounted) FitToast.error(context, tr(context, '未在图片中识别到二维码，请换一张清晰的图片'));
        return;
      }
      _handleDecoded(rawText);
    } catch (e) {
      if (mounted) FitToast.error(context, tr(context, '图片解析失败，请重试'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// 将图片字节解码为像素并识别二维码
  Future<String?> _decodeQrFromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      if (width <= 0 || height <= 0) return null;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (byteData == null) return null;

      final buffer = byteData.buffer.asUint8List();
      final pixels = Int32List(width * height);
      for (var i = 0; i < pixels.length; i++) {
        final o = i * 4;
        final r = buffer[o];
        final g = buffer[o + 1];
        final b = buffer[o + 2];
        pixels[i] = 0xFF000000 | (r << 16) | (g << 8) | b;
      }

      final source = RGBLuminanceSource(width, height, pixels);
      final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);
      return result.text;
    } catch (_) {
      return null;
    }
  }

  /// 统一处理解析到的分享串（相机扫码 / 相册图片共用）
  void _handleDecoded(String raw) {
    if (_processed) return;
    _processed = true;
    try {
      _controller.stop();
    } catch (_) {}

    final result = ShareCodeService.instance.importFromString(raw);
    if (!mounted) return;

    final ft = Theme.of(context).extension<LiftTrackColors>()!;

    if (result.result == ShareCodeResult.success && result.planData != null) {
      _doImport(result.planData!, result.warning, ft);
    } else {
      String errorMsg;
      switch (result.result) {
        case ShareCodeResult.invalidFormat:
          errorMsg = tr(context, '二维码格式无效，不是有效的计划分享码');
          break;
        case ShareCodeResult.invalidSignature:
          errorMsg = tr(context, '分享码签名无效，可能已损坏');
          break;
        case ShareCodeResult.decodeError:
          errorMsg = tr(context, '解析失败，二维码可能不完整');
          break;
        default:
          errorMsg = tr(context, '导入失败，请重试');
      }
      FitToast.error(context, errorMsg);
      setState(() => _processed = false);
      try {
        _controller.start();
      } catch (_) {}
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _processed = true;
    _controller.stop();

    _handleDecoded(raw);
  }

  void _doImport(Map<String, dynamic> planData, ImportWarning warning, LiftTrackColors ft) {
    if (warning == ImportWarning.excessiveVolume || warning == ImportWarning.excessiveFrequency) {
      ConfirmDialog.show(
        context,
        title: warning == ImportWarning.excessiveVolume ? tr(context, '训练量偏大') : tr(context, '训练频率偏高'),
        content: warning == ImportWarning.excessiveVolume
            ? tr(context, '该计划单日训练组数超过50组，可能不适合新手。确定要导入吗？')
            : tr(context, '该计划每周训练超过7次，恢复压力较大。确定要导入吗？'),
        confirmText: tr(context, '确定导入'),
        cancelText: tr(context, '取消'),
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
          ? tr(context, '已导入「${planData['name'] ?? '计划'}」（来自$author）')
          : tr(context, '已导入「${planData['name'] ?? '计划'}」'),
    );

    Navigator.of(context).pop();
  }
}
