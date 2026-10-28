import 'dart:io';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import '../models/finance.dart';
import '../providers/printer_providers.dart';
import '../utils/formatters.dart';

class ReceiptPrinterService {
  static void applySam4sAlign(
    NetworkPrinter printer,
    String printerModel,
    PosAlign align,
  ) {
    if (printerModel == 'sam4s') {
      int val = align == PosAlign.left
          ? 48
          : align == PosAlign.center
              ? 49
              : 50;
      printer.rawBytes([27, 97, val]);
    }
  }

  /// Standard ESC/POS drawer-kick pulse
  static List<int> get cashDrawerKickBytes => <int>[27, 112, 0, 25, 250];

  /// Pulse the cash drawer over LAN TCP socket
  static Future<bool> openCashDrawer({
    required String ip,
    required int port,
  }) async {
    if (kIsWeb || ip.isEmpty) return false;
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(cashDrawerKickBytes);
      await socket.flush();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Diagnostic test print over LAN socket
  static Future<bool> testPrint({required String ip, required int port}) async {
    if (kIsWeb) return false;
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(
        ip,
        port: port,
        timeout: const Duration(seconds: 5),
      );
      if (res != PosPrintResult.success) return false;

      printer.setStyles(const PosStyles(align: PosAlign.center, bold: true));
      printer.text(
        'TEST PRINT',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
          align: PosAlign.center,
        ),
      );
      printer.text(
        'If you can read this,',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.text(
        'your LAN printer is working!',
        styles: const PosStyles(align: PosAlign.center),
      );
      printer.hr();
      printer.text('IP: $ip', styles: const PosStyles(align: PosAlign.left));
      printer.text('Port: $port', styles: const PosStyles(align: PosAlign.left));
      printer.feed(2);
      printer.cut();
      printer.disconnect();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Prints distributor invoice ESC/POS receipt
  static Future<bool> printDistributorInvoice({
    required Invoice invoice,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String distName,
    required String distPhone,
    required String printerIp,
    required int printerPort,
    required String printerModel,
    ReceiptLayoutSettings? receiptLayout,
  }) async {
    if (kIsWeb || printerIp.isEmpty) return false;

    try {
      final layout = receiptLayout ?? const ReceiptLayoutSettings();
      final profile = await CapabilityProfile.load();
      final paperSize = layout.paperWidth == '58mm' ? PaperSize.mm58 : PaperSize.mm80;
      final printer = NetworkPrinter(paperSize, profile);

      final PosPrintResult res = await printer.connect(
        printerIp,
        port: printerPort,
        timeout: const Duration(seconds: 5),
      );
      if (res != PosPrintResult.success) return false;

      await Future<void>.delayed(const Duration(milliseconds: 200));

      // ─── Header ───
      if (layout.showHeader) {
        applySam4sAlign(printer, printerModel, PosAlign.center);
        final headerName = companyName.isNotEmpty ? companyName : 'DISTRIBUTOR ERP';
        printer.text(
          headerName.toUpperCase(),
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size1,
            bold: true,
            align: PosAlign.center,
          ),
        );

        if (companyAddress.isNotEmpty) {
          printer.text(
            companyAddress.toUpperCase(),
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        if (companyPhone.isNotEmpty) {
          printer.text(
            'TEL: $companyPhone',
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        if (layout.headerText.isNotEmpty) {
          printer.text(
            layout.headerText,
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
      }

      printer.hr();

      // ─── Invoice Meta ───
      applySam4sAlign(printer, printerModel, PosAlign.left);
      printer.row([
        PosColumn(text: 'INVOICE:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
          text: invoice.invoiceNumber,
          width: 8,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
      printer.row([
        PosColumn(text: 'DATE:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
          text: F.date(invoice.date),
          width: 8,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      if (invoice.shopName.isNotEmpty) {
        printer.hr();
        printer.row([
          PosColumn(text: 'BILLED TO:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(
            text: invoice.shopName.toUpperCase(),
            width: 8,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
        if (invoice.shopPhone.isNotEmpty) {
          printer.row([
            PosColumn(text: 'PHONE:', width: 4, styles: const PosStyles(bold: true)),
            PosColumn(
              text: invoice.shopPhone,
              width: 8,
              styles: const PosStyles(bold: true, align: PosAlign.right),
            ),
          ]);
        }
      }

      printer.hr();

      // ─── Line Items Matrix ───
      printer.row([
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
      printer.hr();

      for (int i = 0; i < invoice.items.length; i++) {
        final item = invoice.items[i];
        final cleanName = item.productName
            .replaceAll(RegExp(r'\s*[-·•]\s*Default\b', caseSensitive: false), '')
            .trim()
            .toUpperCase();

        printer.text('${i + 1}. $cleanName', styles: const PosStyles(bold: true));

        final qty = item.qty.toDouble();
        final unitPrice = item.unitPrice;
        final total = item.lineTotal;

        printer.row([
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

      printer.hr();

      // ─── Financial Totals ───
      printer.row([
        PosColumn(text: 'SUBTOTAL:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: invoice.subtotal.toStringAsFixed(2),
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      if (invoice.discount > 0) {
        printer.row([
          PosColumn(text: 'DISCOUNT:', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(
            text: '-${invoice.discount.toStringAsFixed(2)}',
            width: 6,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
      }

      printer.hr();
      printer.row([
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
      printer.hr();

      // ─── Distributed By ───
      if (layout.showDistributorInfo && distName.isNotEmpty) {
        printer.row([
          PosColumn(text: 'DISTRIBUTED BY:', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(
            text: distName.toUpperCase(),
            width: 6,
            styles: const PosStyles(bold: true, align: PosAlign.right),
          ),
        ]);
        if (distPhone.isNotEmpty) {
          printer.row([
            PosColumn(text: 'CONTACT:', width: 6, styles: const PosStyles(bold: true)),
            PosColumn(
              text: distPhone,
              width: 6,
              styles: const PosStyles(bold: true, align: PosAlign.right),
            ),
          ]);
        }
        printer.feed(1);
      }

      // ─── Footer ───
      if (layout.showFooterText && layout.footerText.isNotEmpty) {
        applySam4sAlign(printer, printerModel, PosAlign.center);
        printer.text(
          layout.footerText.toUpperCase(),
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size1,
          ),
        );
        printer.feed(1);
      }

      // ─── Return / Refund Policy ───
      if (layout.showRefundPolicy && layout.refundPolicy.isNotEmpty) {
        applySam4sAlign(printer, printerModel, PosAlign.center);
        printer.text(
          layout.refundPolicy,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: false,
          ),
        );
        printer.feed(1);
      }

      // Barcode
      if (layout.showBarcode) {
        try {
          final cleanInvoice = invoice.invoiceNumber.toUpperCase();
          printer.barcode(Barcode.code39(cleanInvoice.codeUnits));
        } catch (_) {
          printer.text(
            invoice.invoiceNumber,
            styles: const PosStyles(align: PosAlign.center, bold: true),
          );
        }
        printer.feed(1);
      }

      printer.feed(2);
      printer.cut();

      await Future<void>.delayed(const Duration(milliseconds: 600));
      printer.disconnect();
      return true;
    } catch (e) {
      debugPrint('LAN thermal print failure: $e');
      return false;
    }
  }
}
