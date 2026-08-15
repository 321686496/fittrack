import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zxing2/qrcode.dart';
import '../widgets/common_widgets.dart';

/// 通用二维码扫码页（相机扫码 + 相册选图兜底）
///
/// 解析到二维码后返回原始文本：`Navigator.pop(context, rawText)`。
/// 供「邀请有礼」等场景复用：邀请码扫码激活、识别码扫码识别。
class QrScanPage extends StatefulWidget {
  final String title;

  const QrScanPage({super.key, this.title = '扫码'});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processed = false;
  bool _cameraFailed = false;
  bool _picking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_cameraFailed)
                  _buildCameraFallback()
                else
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) => _buildCameraFallback(),
                  ),
                Center(
                  child: _cameraFailed
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
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: _cameraFailed
                      ? const SizedBox.shrink()
                      : const Text(
                          '将二维码对准框内即可自动扫描',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _picking ? null : _pickQrImage,
                      icon: _picking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(_picking ? '识别中...' : '从相册选择二维码图片'),
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
          const Text(
            '无法启动相机',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '请检查相机权限，或使用下方"从相册选择二维码图片"导入',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
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
            label: const Text('重试相机'),
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
        if (mounted) FitToast.error(context, '未在图片中识别到二维码，请换一张清晰的图片');
        return;
      }
      _finish(rawText);
    } catch (e) {
      if (mounted) FitToast.error(context, '图片解析失败，请重试');
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

  /// 相机扫码回调
  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _finish(raw);
  }

  /// 统一处理：停止相机并返回原始文本
  void _finish(String rawText) {
    if (_processed) return;
    _processed = true;
    try {
      _controller.stop();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop(rawText);
  }
}