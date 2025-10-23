import 'package:event_marketplace_app/core/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Responsive Design Tests', () {
    test('ResponsiveUtils should return correct screen types', () {
      expect(ResponsiveUtils.getScreenType(400), equals(ScreenType.mobile));
      expect(ResponsiveUtils.getScreenType(800), equals(ScreenType.tablet));
      expect(
        ResponsiveUtils.getScreenType(1200),
        equals(ScreenType.largeDesktop),
      ); // 1200 >= 1200, so largeDesktop
      expect(
          ResponsiveUtils.getScreenType(1600), equals(ScreenType.largeDesktop));
    });

    test('ResponsiveUtils should return correct grid columns', () {
      expect(ResponsiveUtils.getGridColumns(400), equals(1));
      expect(ResponsiveUtils.getGridColumns(800), equals(2));
      expect(ResponsiveUtils.getGridColumns(1200),
          equals(4)); // largeDesktop = 4 columns
      expect(ResponsiveUtils.getGridColumns(1600), equals(4));
    });

    test('ResponsiveUtils should return correct font sizes', () {
      expect(ResponsiveUtils.getTitleFontSize(400), equals(24.0));
      expect(ResponsiveUtils.getTitleFontSize(800), equals(28.0));
      expect(ResponsiveUtils.getTitleFontSize(1200),
          equals(36.0)); // largeDesktop = 36
      expect(ResponsiveUtils.getTitleFontSize(1600), equals(36.0));
    });

    test('ResponsiveUtils should return correct padding', () {
      final mobilePadding = ResponsiveUtils.getScreenPadding(400);
      final tabletPadding = ResponsiveUtils.getScreenPadding(800);
      final desktopPadding = ResponsiveUtils.getScreenPadding(1200);
      final largeDesktopPadding = ResponsiveUtils.getScreenPadding(1600);

      expect(mobilePadding, equals(const EdgeInsets.all(16)));
      expect(tabletPadding, equals(const EdgeInsets.all(24)));
      expect(desktopPadding,
          equals(const EdgeInsets.all(48))); // largeDesktop = 48
      expect(largeDesktopPadding, equals(const EdgeInsets.all(48)));
    });
  });
}
