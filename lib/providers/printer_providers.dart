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
