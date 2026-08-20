// Basic smoke test — pastikan app bisa dibangun tanpa exception.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:owner_easton_mobile/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme builds a valid ThemeData', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Center(child: Text('Owner Easton Park'))),
        ),
      ),
    );

    expect(find.text('Owner Easton Park'), findsOneWidget);
  });
}
