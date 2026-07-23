import 'package:flutter/material.dart';
import '../router.dart';

/// Mixin for tab pages that need to refresh data when becoming active.
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with TabRefreshMixin<MyPage> {
///   @override
///   int get tabIndex => 1; // 该 tab 在底部导航中的索引
///
///   @override
///   void onTabBecameActive() {
///     _loadData();
///   }
///   ...
/// }
/// ```
mixin TabRefreshMixin<T extends StatefulWidget> on State<T> {
  /// 该 tab 页在底部导航中的索引（0-4）
  int get tabIndex;

  /// 当该 tab 页变为活跃时回调（仅在从其他 tab 切换过来时触发，不会重复触发）
  void onTabBecameActive();

  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    currentTabIndex.addListener(_onTabChanged);
    // 初始化 _wasActive：处理首屏即为该 tab 的情况
    _wasActive = currentTabIndex.value == tabIndex;
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    final isActive = currentTabIndex.value == tabIndex;
    if (isActive && !_wasActive && mounted) {
      onTabBecameActive();
    }
    _wasActive = isActive;
  }
}
