import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme provides valid light and dark theme data', (WidgetTester tester) async {
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;

    expect(lightTheme.brightness, Brightness.light);
    expect(darkTheme.brightness, Brightness.dark);
    expect(lightTheme.primaryColor, AppTheme.primary);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text('AuraBake Test'),
          ),
        ),
      ),
    );

    expect(find.text('AuraBake Test'), findsOneWidget);
  });
}
