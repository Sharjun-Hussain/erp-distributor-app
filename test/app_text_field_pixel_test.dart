import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inzeedo_erp_distributor/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField prefix SVG paints visible pixels', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.all(16),
          child: RepaintBoundary(
            key: Key('shot'),
            child: AppTextField(
              label: 'Email',
              hint: 'you@company.lk',
              prefixSvg: 'assets/svg/field_mail.svg',
            ),
          ),
        ),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsOneWidget);

    await expectLater(find.byKey(const Key('shot')),
        matchesGoldenFile('goldens/app_text_field.png'));
  });
}
