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

/// Ngưỡng responsive dùng chung (điện thoại / tablet / desktop).
abstract final class FitnetBreakpoints {
  /// Màn rất hẹp: xếp cột, giảm padding.
  static const double compact = 560;
  /// Dưới ngưỡng này: bảng admin chuyển sang thẻ (card).
  static const double adminTableAsCards = 720;
  /// Admin shell: drawer vs sidebar (khớp [AdminDashboardScreen]).
  static const double adminShellWide = 980;

  static bool isCompactWidth(double w) => w < compact;
  static bool useAdminCards(double w) => w < adminTableAsCards;

  static EdgeInsets pagePaddingInsets(double width) {
    final c = isCompactWidth(width);
    return EdgeInsets.fromLTRB(c ? 16 : 24, c ? 8 : 24, c ? 16 : 24, c ? 20 : 24);
  }
}
