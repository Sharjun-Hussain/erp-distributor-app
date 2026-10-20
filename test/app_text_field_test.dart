import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inzeedo_erp_distributor/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField prefix SVG renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: AppTextField(
            label: 'Email',
            hint: 'you@company.lk',
            prefixSvg: 'assets/svg/field_mail.svg',
          ),
        ),
      ),
    ));

    // let the async asset load resolve
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final exception = tester.takeException();
    // ignore: avoid_print
    print('EXCEPTION: $exception');

    final pics = find.byType(SvgPicture);
    // ignore: avoid_print
    print('SvgPicture count: ${pics.evaluate().length}');
    if (pics.evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('SvgPicture size: ${tester.getSize(pics)}');
      // ignore: avoid_print
      print('SvgPicture found: ${tester.widget<SvgPicture>(pics)}');
    }

    expect(pics, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
