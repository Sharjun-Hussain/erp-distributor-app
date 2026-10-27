import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../providers/printer_providers.dart';
import '../../services/bluetooth_printer_service.dart';
import '../../services/receipt_printer_service.dart';
import '../../theme/app_colors.dart';

class PrinterSettingsSheet extends ConsumerStatefulWidget {
  const PrinterSettingsSheet({super.key});

  @override
  ConsumerState<PrinterSettingsSheet> createState() => _PrinterSettingsSheetState();
}

class _PrinterSettingsSheetState extends ConsumerState<PrinterSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Bluetooth State
  bool _useBluetooth = false;
  String? _selectedBtAddress;
  String? _selectedBtName;
  String _btPrinterModel = 'xprinter';
  bool _isLoadingBt = false;
  bool _isScanningBt = false;
  final List<BluetoothDevice> _btDevices = <BluetoothDevice>[];

  // LAN State
  bool _useLan = false;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '9100');
  String _lanPrinterModel = 'xprinter';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bt = ref.read(bluetoothPrinterProvider);
      final lan = ref.read(printerSettingsProvider);

      setState(() {
        _useBluetooth = bt.useBluetooth;
        _selectedBtAddress = bt.deviceAddress.isEmpty ? null : bt.deviceAddress;
        _selectedBtName = bt.deviceName.isEmpty ? null : bt.deviceName;
        _btPrinterModel = bt.printerModel;

        _useLan = lan.useLanPrinter;
        _ipController.text = lan.printerIp;
        _portController.text = lan.printerPort.toString();
        _lanPrinterModel = lan.printerModel;
      });

      if (_useBluetooth) {
        _loadBtDevices();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadBtDevices() async {
    if (kIsWeb) return;
    setState(() => _isLoadingBt = true);
    final bonded = await BluetoothPrinterService.getBondedDevices();
    if (!mounted) return;
    setState(() {
      _btDevices
        ..clear()
        ..addAll(bonded);
      _isLoadingBt = false;
    });
  }

  Future<void> _scanBtDevices() async {
    if (kIsWeb || _isScanningBt) return;
    setState(() => _isScanningBt = true);
    final results = await BluetoothPrinterService.scanDevices(timeoutSeconds: 6);
    if (!mounted) return;
    setState(() {
      for (final result in results) {
        final device = result.device;
        if (!_btDevices.any((d) => d.address == device.address)) {
          _btDevices.add(device);
        }
      }
      _isScanningBt = false;
    });
  }

  Future<void> _saveAllSettings() async {
    // Save Bluetooth
    await ref.read(bluetoothPrinterProvider.notifier).saveSettings(
          useBluetooth: _useBluetooth,
          deviceName: _selectedBtName ?? '',
          deviceAddress: _selectedBtAddress ?? '',
          printerModel: _btPrinterModel,
        );

    // Save LAN
    final port = int.tryParse(_portController.text.trim()) ?? 9100;
    await ref.read(printerSettingsProvider.notifier).saveSettings(
          _useLan,
          _ipController.text.trim(),
          port,
          _lanPrinterModel,
        );

    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: const Text('Printer Settings Saved', style: TextStyle(fontWeight: FontWeight.bold)),
      description: const Text('Thermal printer preferences updated.'),
      autoCloseDuration: const Duration(seconds: 3),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.printer, color: AppColors.brand, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Printer Setup',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: theme.textMain,
                          ),
                        ),
                        Text(
                          'Configure Bluetooth & LAN thermal printers',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surfaceMutedColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: AppColors.brand,
              unselectedLabelColor: theme.textSecondary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(LucideIcons.bluetooth, size: 16),
                  text: 'Bluetooth',
                ),
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(LucideIcons.wifi, size: 16),
                  text: 'LAN Network',
                ),
              ],
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBluetoothTab(theme),
                _buildLanTab(theme),
              ],
            ),
          ),

          // Save Footer Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              border: Border(top: BorderSide(color: theme.glassBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _saveAllSettings,
                child: Text(
                  'Save Printer Settings',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BLUETOOTH TAB
  // ==========================================
  Widget _buildBluetoothTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Enable Bluetooth Printer',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.5, color: theme.textMain),
          ),
          subtitle: Text(
            'Connect to portable Bluetooth thermal receipts',
            style: GoogleFonts.inter(fontSize: 12, color: theme.textSecondary),
          ),
          value: _useBluetooth,
          activeThumbColor: AppColors.brand,
          onChanged: (val) {
            setState(() => _useBluetooth = val);
            if (val && _btDevices.isEmpty) _loadBtDevices();
          },
        ),
        const SizedBox(height: 12),

        if (_useBluetooth) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAIRED & NEARBY DEVICES',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.textSecondary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    onPressed: _isLoadingBt ? null : _loadBtDevices,
                    tooltip: 'Reload Paired',
                  ),
                  IconButton(
                    icon: _isScanningBt
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.radar, size: 16),
                    onPressed: _isScanningBt ? null : _scanBtDevices,
                    tooltip: 'Scan Devices',
                  ),
                ],
              ),
            ],
          ),

          if (_isLoadingBt)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_btDevices.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.surfaceMutedColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.bluetoothOff, size: 28, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No Bluetooth devices found.\nTurn on Bluetooth and pair your mobile thermal printer in phone settings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: theme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ..._btDevices.map((device) {
              final isSelected = _selectedBtAddress == device.address;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brand.withValues(alpha: 0.08) : theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.brand : theme.glassBorder,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  onTap: () {
                    setState(() {
                      _selectedBtAddress = device.address;
                      _selectedBtName = device.name;
                    });
                  },
                  leading: Icon(
                    LucideIcons.printer,
                    color: isSelected ? AppColors.brand : theme.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    device.name ?? 'Unknown Device',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: theme.textMain,
                    ),
                  ),
                  subtitle: Text(
                    device.address,
                    style: GoogleFonts.inter(fontSize: 11.5, color: theme.textSecondary),
                  ),
                  trailing: isSelected
                      ? const Icon(LucideIcons.checkCircle2, color: AppColors.brand, size: 18)
                      : null,
                ),
              );
            }),

          const SizedBox(height: 16),
          // Test Print Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: theme.glassBorder),
            ),
            icon: const Icon(LucideIcons.printer, size: 16),
            label: Text(
              'Test Bluetooth Print',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            onPressed: _selectedBtAddress != null
                ? () async {
                    toastification.show(
                      context: context,
                      type: ToastificationType.info,
                      title: const Text('Sending Test Print...'),
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                    final ok = await BluetoothPrinterService.testPrint(
                      address: _selectedBtAddress!,
                      printerModel: _btPrinterModel,
                    );
                    if (!mounted) return;
                    toastification.show(
                      context: context,
                      type: ok ? ToastificationType.success : ToastificationType.error,
                      title: Text(ok ? 'Test Print Sent!' : 'Bluetooth Print Failed'),
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  }
                : null,
          ),
        ],
      ],
    );
  }

  // ==========================================
  // LAN TAB
  // ==========================================
  Widget _buildLanTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Enable LAN Network Printing',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.5, color: theme.textMain),
          ),
          subtitle: Text(
            'Direct TCP socket to network printer (port 9100)',
            style: GoogleFonts.inter(fontSize: 12, color: theme.textSecondary),
          ),
          value: _useLan,
          activeThumbColor: AppColors.brand,
          onChanged: (val) => setState(() => _useLan = val),
        ),
        const SizedBox(height: 12),

        if (_useLan) ...[
          Text(
            'PRINTER IP ADDRESS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _ipController,
            decoration: InputDecoration(
              hintText: 'e.g. 192.168.1.100',
              prefixIcon: const Icon(LucideIcons.wifi, size: 18),
              filled: true,
              fillColor: theme.surfaceMutedColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.glassBorder),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'PORT (DEFAULT 9100)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '9100',
              prefixIcon: const Icon(LucideIcons.hash, size: 18),
              filled: true,
              fillColor: theme.surfaceMutedColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.glassBorder),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Test LAN Print Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: theme.glassBorder),
            ),
            icon: const Icon(LucideIcons.printer, size: 16),
            label: Text(
              'Test LAN Print',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            onPressed: _ipController.text.trim().isNotEmpty
                ? () async {
                    if (kIsWeb) {
                      toastification.show(
                        context: context,
                        type: ToastificationType.warning,
                        title: const Text('Web Limitation'),
                        description: const Text(
                          'Direct raw TCP socket connections are blocked by browser sandboxes.',
                        ),
                        autoCloseDuration: const Duration(seconds: 4),
                      );
                      return;
                    }
                    toastification.show(
                      context: context,
                      type: ToastificationType.info,
                      title: const Text('Sending LAN Test Print...'),
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                    final port = int.tryParse(_portController.text.trim()) ?? 9100;
                    final ok = await ReceiptPrinterService.testPrint(
                      ip: _ipController.text.trim(),
                      port: port,
                    );
                    if (!mounted) return;
                    toastification.show(
                      context: context,
                      type: ok ? ToastificationType.success : ToastificationType.error,
                      title: Text(ok ? 'LAN Print Success!' : 'LAN Print Failed'),
                      autoCloseDuration: const Duration(seconds: 3),
                    );
                  }
                : null,
          ),
        ],
      ],
    );
  }
}
