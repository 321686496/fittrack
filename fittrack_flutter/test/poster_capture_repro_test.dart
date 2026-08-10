import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 复现「海报生成失败：RepaintBoundary 尚未完成绘制」的根因。
///
/// 与 poster_capture_helper.captureAndPreview 相同的结构：
/// overlay 插入海报 entry + showDialog(loading) 后，检查海报
/// RepaintBoundary 的 hasSize / debugNeedsPaint 状态，并收集帧绘制期间的
/// FlutterError（如 PhysicalModel 'hasSize' 断言）。
void main() {
  testWidgets('poster entry under loading dialog: layout/paint state',
      (tester) async {
    final boundaryKey = GlobalKey();
    late OverlayEntry entry;

    final errors = <String>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
      originalOnError?.call(details);
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final overlay = Overlay.of(context);
              entry = OverlayEntry(
                builder: (_) => Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 360,
                      height: 640,
                      child: Material(
                        color: Colors.transparent,
                        child: RepaintBoundary(
                          key: boundaryKey,
                          child: Container(
                            width: 360,
                            height: 640,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: ColoredBox(color: const Color(0xFF111111)),
                    ),
                  ],
                ),
              );
              overlay.insert(entry);
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            });
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    // 模拟截图前的等待轮询：多帧 pump
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    FlutterError.onError = originalOnError;

    // 检查海报 boundary 状态
    final ctx = boundaryKey.currentContext;
    final ro = ctx?.findRenderObject();
    String state = 'ro=null';
    if (ro is RenderRepaintBoundary) {
      state = 'hasSize=${ro.hasSize} '
          'size=${ro.size} '
          'attached=${ro.attached} '
          'needsPaint=${ro.debugNeedsPaint}';
    } else if (ro != null) {
      state = 'roType=${ro.runtimeType}';
    }
    // 忽略 CircularProgressIndicator 动画帧的 TickerMode 断言
    final realErrors =
        errors.where((e) => !e.contains('TickerMode')).toList();
    debugPrint('=== poster repro ===');
    debugPrint('boundary: $state');
    debugPrint('errors: $realErrors');

    // 断言：海报必须完成 layout，且没有帧绘制断言错误
    expect(state.contains('hasSize=true'), isTrue,
        reason: '海报 entry 应完成 layout（hasSize=true）');
    expect(state.contains('needsPaint=false'), isTrue,
        reason: '海报 entry 应完成 paint（debugNeedsPaint=false）');
    expect(realErrors, isEmpty,
        reason: '帧绘制期间不应出现断言错误（如 PhysicalModel hasSize）');
  });
}
