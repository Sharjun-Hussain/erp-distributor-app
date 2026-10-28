import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettings {
  final bool useLanPrinter;
  final String printerIp;
  final int printerPort;
  final String printerModel; // 'sam4s' or 'xprinter'

  const PrinterSettings({
    this.useLanPrinter = false,
    this.printerIp = '',
    this.printerPort = 9100,
    this.printerModel = 'xprinter',
  });

  PrinterSettings copyWith({
    bool? useLanPrinter,
    String? printerIp,
    int? printerPort,
    String? printerModel,
  }) {
    return PrinterSettings(
      useLanPrinter: useLanPrinter ?? this.useLanPrinter,
      printerIp: printerIp ?? this.printerIp,
      printerPort: printerPort ?? this.printerPort,
      printerModel: printerModel ?? this.printerModel,
    );
  }
}

class PrinterSettingsNotifier extends StateNotifier<PrinterSettings> {
  PrinterSettingsNotifier() : super(const PrinterSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = PrinterSettings(
      useLanPrinter: prefs.getBool('use_lan_printer') ?? false,
      printerIp: prefs.getString('printer_ip') ?? '',
      printerPort: prefs.getInt('printer_port') ?? 9100,
      printerModel: prefs.getString('printer_model') ?? 'xprinter',
    );
  }

  Future<void> saveSettings(
    bool useLan,
    String ip,
    int port,
    String model,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_lan_printer', useLan);
    await prefs.setString('printer_ip', ip);
    await prefs.setInt('printer_port', port);
    await prefs.setString('printer_model', model);
    state = PrinterSettings(
      useLanPrinter: useLan,
      printerIp: ip,
      printerPort: port,
      printerModel: model,
    );
  }
}

final printerSettingsProvider =
    StateNotifierProvider<PrinterSettingsNotifier, PrinterSettings>((ref) {
  return PrinterSettingsNotifier();
});

class BluetoothPrinterSettings {
  final bool useBluetooth;
  final String deviceName;
  final String deviceAddress;
  final String printerModel; // 'sam4s' or 'xprinter'

  const BluetoothPrinterSettings({
    this.useBluetooth = false,
    this.deviceName = '',
    this.deviceAddress = '',
    this.printerModel = 'xprinter',
  });

  BluetoothPrinterSettings copyWith({
    bool? useBluetooth,
    String? deviceName,
    String? deviceAddress,
    String? printerModel,
  }) {
    return BluetoothPrinterSettings(
      useBluetooth: useBluetooth ?? this.useBluetooth,
      deviceName: deviceName ?? this.deviceName,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      printerModel: printerModel ?? this.printerModel,
    );
  }
}

class BluetoothPrinterSettingsNotifier
    extends StateNotifier<BluetoothPrinterSettings> {
  BluetoothPrinterSettingsNotifier() : super(const BluetoothPrinterSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = BluetoothPrinterSettings(
      useBluetooth: prefs.getBool('use_bluetooth_printer') ?? false,
      deviceName: prefs.getString('bluetooth_printer_name') ?? '',
      deviceAddress: prefs.getString('bluetooth_printer_address') ?? '',
      printerModel: prefs.getString('bluetooth_printer_model') ?? 'xprinter',
    );
  }

  Future<void> saveSettings({
    required bool useBluetooth,
    required String deviceName,
    required String deviceAddress,
    required String printerModel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_bluetooth_printer', useBluetooth);
    await prefs.setString('bluetooth_printer_name', deviceName);
    await prefs.setString('bluetooth_printer_address', deviceAddress);
    await prefs.setString('bluetooth_printer_model', printerModel);
    state = BluetoothPrinterSettings(
      useBluetooth: useBluetooth,
      deviceName: deviceName,
      deviceAddress: deviceAddress,
      printerModel: printerModel,
    );
  }
}

final bluetoothPrinterProvider =
    StateNotifierProvider<BluetoothPrinterSettingsNotifier,
        BluetoothPrinterSettings>((ref) {
  return BluetoothPrinterSettingsNotifier();
});

class ReceiptLayoutSettings {
  final String paperWidth; // '58mm' or '80mm'
  final bool showHeader;
  final String headerText;
  final bool showFooterText;
  final String footerText;
  final bool showRefundPolicy;
  final String refundPolicy;
  final bool showBarcode;
  final bool showDistributorInfo;

  const ReceiptLayoutSettings({
    this.paperWidth = '80mm',
    this.showHeader = true,
    this.headerText = '',
    this.showFooterText = true,
    this.footerText = 'THANK YOU FOR YOUR BUSINESS!',
    this.showRefundPolicy = false,
    this.refundPolicy = 'Returns accepted within 7 days with original receipt.',
    this.showBarcode = true,
    this.showDistributorInfo = true,
  });

  ReceiptLayoutSettings copyWith({
    String? paperWidth,
    bool? showHeader,
    String? headerText,
    bool? showFooterText,
    String? footerText,
    bool? showRefundPolicy,
    String? refundPolicy,
    bool? showBarcode,
    bool? showDistributorInfo,
  }) {
    return ReceiptLayoutSettings(
      paperWidth: paperWidth ?? this.paperWidth,
      showHeader: showHeader ?? this.showHeader,
      headerText: headerText ?? this.headerText,
      showFooterText: showFooterText ?? this.showFooterText,
      footerText: footerText ?? this.footerText,
      showRefundPolicy: showRefundPolicy ?? this.showRefundPolicy,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      showBarcode: showBarcode ?? this.showBarcode,
      showDistributorInfo: showDistributorInfo ?? this.showDistributorInfo,
    );
  }
}

class ReceiptLayoutSettingsNotifier extends StateNotifier<ReceiptLayoutSettings> {
  ReceiptLayoutSettingsNotifier() : super(const ReceiptLayoutSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = ReceiptLayoutSettings(
      paperWidth: prefs.getString('receipt_paper_width') ?? '80mm',
      showHeader: prefs.getBool('receipt_show_header') ?? true,
      headerText: prefs.getString('receipt_header_text') ?? '',
      showFooterText: prefs.getBool('receipt_show_footer') ?? true,
      footerText: prefs.getString('receipt_footer_text') ?? 'THANK YOU FOR YOUR BUSINESS!',
      showRefundPolicy: prefs.getBool('receipt_show_refund') ?? false,
      refundPolicy: prefs.getString('receipt_refund_policy') ?? 'Returns accepted within 7 days with original receipt.',
      showBarcode: prefs.getBool('receipt_show_barcode') ?? true,
      showDistributorInfo: prefs.getBool('receipt_show_dist_info') ?? true,
    );
  }

  Future<void> saveSettings({
    required String paperWidth,
    required bool showHeader,
    required String headerText,
    required bool showFooterText,
    required String footerText,
    required bool showRefundPolicy,
    required String refundPolicy,
    required bool showBarcode,
    required bool showDistributorInfo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receipt_paper_width', paperWidth);
    await prefs.setBool('receipt_show_header', showHeader);
    await prefs.setString('receipt_header_text', headerText);
    await prefs.setBool('receipt_show_footer', showFooterText);
    await prefs.setString('receipt_footer_text', footerText);
    await prefs.setBool('receipt_show_refund', showRefundPolicy);
    await prefs.setString('receipt_refund_policy', refundPolicy);
    await prefs.setBool('receipt_show_barcode', showBarcode);
    await prefs.setBool('receipt_show_dist_info', showDistributorInfo);

    state = ReceiptLayoutSettings(
      paperWidth: paperWidth,
      showHeader: showHeader,
      headerText: headerText,
      showFooterText: showFooterText,
      footerText: footerText,
      showRefundPolicy: showRefundPolicy,
      refundPolicy: refundPolicy,
      showBarcode: showBarcode,
      showDistributorInfo: showDistributorInfo,
    );
  }
}

final receiptLayoutSettingsProvider =
    StateNotifierProvider<ReceiptLayoutSettingsNotifier, ReceiptLayoutSettings>((ref) {
  return ReceiptLayoutSettingsNotifier();
});

