import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inzeedo_erp_distributor/main.dart';
import 'package:inzeedo_erp_distributor/screens/shell/splash_screen.dart';
import 'package:inzeedo_erp_distributor/screens/login/login_screen.dart';
import 'package:inzeedo_erp_distributor/screens/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Directly launches into LoginScreen without splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(const ProviderScope(child: DistributorApp()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
