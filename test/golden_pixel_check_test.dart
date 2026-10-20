import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('golden contains visible icon pixels in prefix area', () async {
    final bytes = File('test/goldens/app_text_field.png').readAsBytesSync();
    final codec = await instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final bd = await img.toByteData(format: ImageByteFormat.rawRgba);
    final pixels = bd!.buffer.asUint8List();

    final w = img.width;
    final h = img.height;

    var iconGrey = 0;
    var leftIndigo = 0;
    var totalIndigo = 0;

    // icon slot: prefix icon occupies roughly x 4..46 of the field
    const iconX0 = 4;
    const iconX1 = 46;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final a = pixels[i + 3];
        if (a < 200) continue;
        final indigo = b > r + 50 && b > g + 50 && b > 150;
        if (indigo) totalIndigo++;
        // grey tint #64748B = (100,116,139)
        final grey = (r - 100).abs() <= 20 &&
            (g - 116).abs() <= 20 &&
            (b - 139).abs() <= 20;
        if (x >= iconX0 && x < iconX1 && grey) iconGrey++;
        if (x < w ~/ 3 && indigo) leftIndigo++;
      }
    }

    // ignore: avoid_print
    print('size ${w}x$h | icon-slot grey=$iconGrey | left-third indigo='
        '$leftIndigo | total indigo=$totalIndigo');

    expect(iconGrey + totalIndigo, greaterThan(30),
        reason: 'prefix icon strokes should paint inside the icon slot');
  });
}
