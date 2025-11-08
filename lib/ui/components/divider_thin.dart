import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Тонкий разделитель
class DividerThin extends StatelessWidget {
  const DividerThin({
    this.height = 1,
    this.indent = 0,
    this.endIndent = 0,
    super.key,
  });

  final double height;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Divider(
      height: height,
      thickness: height,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}

