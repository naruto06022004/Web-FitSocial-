import 'package:flutter/widgets.dart';

/// Lưới 3 cột dùng chung cho AppBar và trang Home (căn chỉnh cột).
abstract final class FitnetLayout {
  static const double maxContentWidth = 1280;
  static const double leftRailWidth = 280;
  static const double rightRailWidth = 320;
  /// Khoảng cách giữa sidebar và cột bài viết (rộng hơn trước).
  static const double columnGap = 32;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(12, 12, 12, 24);
}
