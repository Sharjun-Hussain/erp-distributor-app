import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';

import '../models/finance.dart';
import '../providers/printer_providers.dart';
import 'api_client.dart';
import 'bluetooth_printer_service.dart';
import 'receipt_printer_service.dart';
import 'stub_downloader.dart' if (dart.library.html) 'web_downloader.dart';

class InvoicePrintService {
  final ApiClient _api;
  final PrinterSettings _printerSettings;
  final BluetoothPrinterSettings _bluetoothSettings;
  final ReceiptLayoutSettings _receiptLayout;

  InvoicePrintService(
    this._api,
    this._printerSettings,
    this._bluetoothSettings,
    this._receiptLayout,
  );

  /// Downloads or opens native A4 invoice PDF generated from backend
  Future<void> handleA4Print(BuildContext context, Invoice invoice) async {
    try {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        title: const Text(
          'Generating A4 Invoice...',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        description: const Text('Compiling native PDF layout on server.'),
        autoCloseDuration: const Duration(seconds: 3),
      );

      final bytes = await _api.downloadBytes('/dapp/invoices/${invoice.id}/pdf');

      final fileName = 'Invoice_${invoice.invoiceNumber}.pdf';

      if (kIsWeb) {
        downloadBytes(bytes, fileName);
        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: const Text(
              'Download Ready',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            description: const Text('Invoice PDF saved to browser downloads.'),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } else {
        Directory saveDir;
        if (Platform.isAndroid) {
          final externalDirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (externalDirs != null && externalDirs.isNotEmpty) {
            saveDir = Directory('${externalDirs.first.path}/Inzeedo');
          } else {
            saveDir = await getApplicationDocumentsDirectory();
          }
        } else {
          saveDir = await getApplicationDocumentsDirectory();
        }

        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }

        final filePath = '${saveDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: const Text(
              'PDF Saved & Ready',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            description: Text('Saved to ${file.path}'),
            autoCloseDuration: const Duration(seconds: 4),
          );

          // Prompt native share / print preview on mobile
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(filePath)],
              text: 'Invoice #${invoice.invoiceNumber}',
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title: const Text(
            'A4 Print Failed',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }

  /// Prints 80mm/58mm thermal receipt via Bluetooth or LAN
  Future<void> handleThermalPrint({
    required BuildContext context,
    required Invoice invoice,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String distName,
    required String distPhone,
  }) async {
    try {
      // 1. Bluetooth thermal printer route
      if (_bluetoothSettings.useBluetooth &&
          _bluetoothSettings.deviceAddress.isNotEmpty) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          title: const Text(
            'Connecting to Bluetooth Printer...',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          description: Text(
            'Streaming ESC/POS to ${_bluetoothSettings.deviceName.isNotEmpty ? _bluetoothSettings.deviceName : _bluetoothSettings.deviceAddress}...',
          ),
          autoCloseDuration: const Duration(seconds: 3),
        );

        final success = await BluetoothPrinterService.printDistributorInvoice(
          address: _bluetoothSettings.deviceAddress,
          invoice: invoice,
          companyName: companyName,
          companyAddress: companyAddress,
          companyPhone: companyPhone,
          distName: distName,
          distPhone: distPhone,
          printerModel: _bluetoothSettings.printerModel,
          receiptLayout: _receiptLayout,
        );

        if (context.mounted) {
          if (success) {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              style: ToastificationStyle.flat,
              title: const Text(
                'Thermal Print Successful',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              description: const Text('Receipt transmitted to Bluetooth printer.'),
              autoCloseDuration: const Duration(seconds: 4),
            );
          } else {
            throw Exception(
              'Bluetooth printer unreachable. Verify Bluetooth is on and printer is paired.',
            );
          }
        }
        return;
      }

      // 2. LAN network socket thermal printer route
      if (_printerSettings.useLanPrinter &&
          _printerSettings.printerIp.isNotEmpty) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          title: const Text(
            'Connecting to LAN Printer...',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          description: Text(
            'Streaming ESC/POS to ${_printerSettings.printerIp}:${_printerSettings.printerPort}...',
          ),
          autoCloseDuration: const Duration(seconds: 3),
        );

        final success = await ReceiptPrinterService.printDistributorInvoice(
          invoice: invoice,
          companyName: companyName,
          companyAddress: companyAddress,
          companyPhone: companyPhone,
          distName: distName,
          distPhone: distPhone,
          printerIp: _printerSettings.printerIp,
          printerPort: _printerSettings.printerPort,
          printerModel: _printerSettings.printerModel,
          receiptLayout: _receiptLayout,
        );

        if (context.mounted) {
          if (success) {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              style: ToastificationStyle.flat,
              title: const Text(
                'Thermal Print Successful',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              description: const Text('Receipt transmitted to LAN printer.'),
              autoCloseDuration: const Duration(seconds: 4),
            );
          } else {
            throw Exception(
              'LAN printer connection failed. Verify IP, port, and Wi-Fi network.',
            );
          }
        }
        return;
      }

      // 3. No printer configured warning
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          style: ToastificationStyle.flat,
          title: const Text(
            'No Printer Configured',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          description: const Text(
            'Please configure a Bluetooth or LAN printer in More -> Printer Setup.',
          ),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          title: const Text(
            'Thermal Engine Error',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }
}

final invoicePrintServiceProvider = Provider<InvoicePrintService>((ref) {
  final api = ApiClient();
  final printerSettings = ref.watch(printerSettingsProvider);
  final bluetoothSettings = ref.watch(bluetoothPrinterProvider);
  final receiptLayout = ref.watch(receiptLayoutSettingsProvider);
  return InvoicePrintService(api, printerSettings, bluetoothSettings, receiptLayout);
});
