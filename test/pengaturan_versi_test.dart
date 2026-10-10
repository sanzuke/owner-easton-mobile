import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/core/providers/app_info_provider.dart';
import 'package:owner_easton_mobile/features/lainnya/presentation/pengaturan_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('Pengaturan menampilkan versi dan nomor build terpasang', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Owner', packageName: 'id.test', version: '1.1.0', buildNumber: '12345', buildSignature: '',
    );
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: PengaturanScreen())));
    await tester.pumpAndSettle();

    expect(find.text('Versi aplikasi'), findsOneWidget);
    expect(find.text('1.1.0 (build 12345)'), findsOneWidget);
  });

  test('labelVersi: versi + build', () {
    final info = PackageInfo(appName: 'a', packageName: 'p', version: '2.0.1', buildNumber: '7');
    expect(labelVersi(info), '2.0.1 (build 7)');
  });
}
