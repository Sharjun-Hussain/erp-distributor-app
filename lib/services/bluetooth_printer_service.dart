import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

import '../models/finance.dart';
import '../utils/formatters.dart';

class _EscPosDraft {
  _EscPosDraft(this.paper, this.profile, {int spaceBetweenRows = 5})
      : _generator = Generator(
          paper,
          profile,
          spaceBetweenRows: spaceBetweenRows,
        ) {
    _bytes.addAll(_generator.reset());
  }

  final PaperSize paper;
  final CapabilityProfile profile;
  final Generator _generator;
  final List<int> _bytes = <int>[];

  List<int> get bytes => _bytes;

  void setStyles(PosStyles styles, {bool isKanji = false}) {
    _bytes.addAll(_generator.setStyles(styles, isKanji: isKanji));
  }

  void text(
    String text, {
    PosStyles styles = const PosStyles(),
    int linesAfter = 0,
    bool containsChinese = false,
    int? maxCharsPerLine,
  }) {
    _bytes.addAll(
      _generator.text(
        text,
        styles: styles,
        linesAfter: linesAfter,
        containsChinese: containsChinese,
        maxCharsPerLine: maxCharsPerLine,
      ),
    );
  }

  void row(List<PosColumn> cols) {
    _bytes.addAll(_generator.row(cols));
  }

  void hr({String ch = '-', int? len, int linesAfter = 0}) {
    _bytes.addAll(_generator.hr(ch: ch, len: len, linesAfter: linesAfter));
  }

  void feed(int n) {
    _bytes.addAll(_generator.feed(n));
  }

  void cut({PosCutMode mode = PosCutMode.full}) {
    _bytes.addAll(_generator.cut(mode: mode));
  }

  void barcode(
    Barcode barcode, {
    int? width,
    int? height,
    BarcodeFont? font,
    BarcodeText textPos = BarcodeText.below,
    PosAlign align = PosAlign.center,
  }) {
    _bytes.addAll(
      _generator.barcode(
        barcode,
        width: width,
        height: height,
        font: font,
        textPos: textPos,
        align: align,
      ),
    );
  }

  void rawBytes(List<int> cmd, {bool isKanji = false}) {
    _bytes.addAll(_generator.rawBytes(cmd, isKanji: isKanji));
  }
}

class BluetoothPrinterService {
  static List<int> get cashDrawerKickBytes => <int>[27, 112, 0, 25, 250];

  static Future<List<BluetoothDevice>> getBondedDevices() async {
    if (kIsWeb) return <BluetoothDevice>[];
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (_) {
      return <BluetoothDevice>[];
    }
  }

  static Future<List<BluetoothDiscoveryResult>> scanDevices({
    int timeoutSeconds = 6,
  }) async {
    if (kIsWeb) return <BluetoothDiscoveryResult>[];
    final results = <BluetoothDiscoveryResult>[];
    try {
      final subscription = FlutterBluetoothSerial.instance
          .startDiscovery()
          .listen((r) => results.add(r), onError: (_) {});
      await Future<void>.delayed(Duration(seconds: timeoutSeconds));
      await subscription.cancel();
      try {
        await FlutterBluetoothSerial.instance.cancelDiscovery();
      } catch (_) {}
    } catch (_) {
      return <BluetoothDiscoveryResult>[];
    }
    return results;
  }

  static Future<bool> _send(String address, List<int> bytes) async {
    if (kIsWeb || address.isEmpty) return false;

    final BluetoothConnection connection;
    try {
      connection = await BluetoothConnection.toAddress(address);
    } catch (_) {
      return false;
    }

    try {
      const int chunkSize = 512;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final int end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        connection.output.add(Uint8List.fromList(bytes.sublist(i, end)));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
      connection.close();
      return true;
    } catch (_) {
      try {
        connection.close();
      } catch (_) {}
      return false;
    }
  }

  static void _applySam4sAlign(
    _EscPosDraft draft,
    String printerModel,
    PosAlign align,
  ) {
    if (printerModel == 'sam4s') {
      final int val = align == PosAlign.left
          ? 48
          : align == PosAlign.center
              ? 49
              : 50;
      draft.rawBytes(<int>[27, 97, val]);
    }
  }

  static Future<bool> openCashDrawer({required String address}) async {
    if (kIsWeb || address.isEmpty) return false;
    return await _send(address, cashDrawerKickBytes);
  }

  static Future<bool> testPrint({
    required String address,
    required String printerModel,
  }) async {
    if (kIsWeb || address.isEmpty) return false;

    try {
      final profile = await CapabilityProfile.load();
      final draft = _EscPosDraft(PaperSize.mm80, profile);

      draft.setStyles(const PosStyles(align: PosAlign.center, bold: true));
      draft.text(
        'TEST PRINT',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
          align: PosAlign.center,
        ),
      );
      draft.text(
        'If you can read this,',
        styles: const PosStyles(align: PosAlign.center),
      );
      draft.text(
        'your Bluetooth printer is working!',
        styles: const PosStyles(align: PosAlign.center),
      );
      draft.hr();
      draft.text(
        'DEVICE: $address',
        styles: const PosStyles(align: PosAlign.left),
      );
      draft.feed(2);
      draft.cut();

      return await _send(address, draft.bytes);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> printDistributorInvoice({
    required String address,
    required Invoice invoice,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String distName,
    required String distPhone,
    required String printerModel,
  }) async {
    if (kIsWeb || address.isEmpty) return false;

    try {
      final profile = await CapabilityProfile.load();
      final draft = _EscPosDraft(PaperSize.mm80, profile);

      // Header
      _applySam4sAlign(draft, printerModel, PosAlign.center);
      final headerName = companyName.isNotEmpty ? companyName : 'DISTRIBUTOR ERP';
      draft.text(
        headerName.toUpperCase(),
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size1,
          bold: true,
          align: PosAlign.center,
        ),
      );

      if (companyAddress.isNotEmpty) {
        draft.text(
          companyAddress.toUpperCase(),
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      }
      if (companyPhone.isNotEmpty) {
        draft.text(
          'TEL: $companyPhone',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      }

      draft.hr();

      // Invoice Meta
      _applySam4sAlign(draft, printerModel, PosAlign.left);
      draft.row([
        PosColumn(text: 'INVOICE:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
          text: invoice.invoiceNumber,
          width: 8,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
      draft.row([
        PosColumn(text: 'DATE:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
          text: F.date(invoice.date),
          width: 8,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      if (invoice.shopName.isNotEmpty) {
        draft.hr();
        draft.row([
          PosColumn(text: 'BILLED TO:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(
            text: invoice.shopName.toUpperCase(),
            width: 8,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
        if (invoice.shopPhone.isNotEmpty) {
          draft.row([
            PosColumn(text: 'PHONE:', width: 4, styles: const PosStyles(bold: true)),
            PosColumn(
              text: invoice.shopPhone,
              width: 8,
              styles: const PosStyles(bold: true, align: PosAlign.right),
            ),
          ]);
        }
      }

      draft.hr();

      // Line Items
      draft.row([
        PosColumn(text: 'ITEM', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'QTY',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
        PosColumn(
          text: 'PRICE',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
        PosColumn(
          text: 'TOTAL',
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
      draft.hr();

      for (int i = 0; i < invoice.items.length; i++) {
        final item = invoice.items[i];
        final cleanName = item.productName
            .replaceAll(RegExp(r'\s*[-·•]\s*Default\b', caseSensitive: false), '')
            .trim()
            .toUpperCase();

        draft.text('${i + 1}. $cleanName', styles: const PosStyles(bold: true));

        final qty = item.qty.toDouble();
        final unitPrice = item.unitPrice;
        final total = item.lineTotal;

        draft.row([
          PosColumn(text: '', width: 6),
          PosColumn(
            text: qty.toStringAsFixed(0),
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.center),
          ),
          PosColumn(
            text: unitPrice.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
          PosColumn(
            text: total.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
      }

      draft.hr();

      // Financial Totals
      draft.row([
        PosColumn(text: 'SUBTOTAL:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: invoice.subtotal.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      if (invoice.discount > 0) {
        draft.row([
          PosColumn(text: 'DISCOUNT:', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(
            text: '-${invoice.discount.toStringAsFixed(2)}',
            width: 6,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
      }

      draft.hr();
      draft.row([
        PosColumn(
          text: 'TOTAL AMOUNT:',
          width: 6,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
        PosColumn(
          text: invoice.total.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            align: PosAlign.right,
          ),
        ),
      ]);
      draft.hr();

      // Distributed By
      if (distName.isNotEmpty) {
        draft.row([
          PosColumn(text: 'DISTRIBUTED BY:', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(
            text: distName.toUpperCase(),
            width: 6,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
        if (distPhone.isNotEmpty) {
          draft.row([
            PosColumn(text: 'CONTACT:', width: 6, styles: const PosStyles(bold: true)),
            PosColumn(
              text: distPhone,
              width: 6,
              styles: const PosStyles(bold: true, align: PosAlign.right),
            ),
          ]);
        }
        draft.feed(1);
      }

      // Footer
      _applySam4sAlign(draft, printerModel, PosAlign.center);
      draft.text(
        'THANK YOU FOR YOUR BUSINESS!',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      draft.feed(1);

      // Barcode
      try {
        final cleanInvoice = invoice.invoiceNumber.toUpperCase();
        draft.barcode(Barcode.code39(cleanInvoice.codeUnits));
      } catch (_) {
        draft.text(
          invoice.invoiceNumber,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
      }

      draft.feed(1);
      draft.text(
        'ERP SYSTEM FROM INZEEDO',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      draft.text(
        '(c) ${DateTime.now().year} INZEEDO.LK | +94785706441',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      draft.feed(2);
      draft.cut();

      return await _send(address, draft.bytes);
    } catch (_) {
      return false;
    }
  }
}
