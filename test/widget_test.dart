import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inzeedo_erp_distributor/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders with splash/login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
        const ProviderScope(child: DistributorApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Distributor'), findsWidgets);
    // Let entrance-effect delay timers fire, then unmount so the infinite
    // float-loop tickers are disposed cleanly.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
  });
}
