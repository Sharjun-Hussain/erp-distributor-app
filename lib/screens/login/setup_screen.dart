import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_text_field.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isPending = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadExistingUrl();
  }

  Future<void> _loadExistingUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('custom_api_url');
    if (saved != null && saved.isNotEmpty) {
      // Remove trailing API paths for display
      final display = saved.replaceAll(RegExp(r'/api/v1/?$'), '');
      _urlController.text = display;
    } else {
      _urlController.text = AppConfig.productionBaseUrl;
    }
  }

  bool _isLocalHost(String input) {
    final v = input.trim().toLowerCase();
    return v.contains('localhost') ||
        v.contains('127.0.0.1') ||
        v.contains('10.0.2.2') ||
        v.contains('192.168.') ||
        v.contains('10.');
  }

  String _normalizeUrl(String input) {
    String base = input.trim();
    if (base.isEmpty) return '';

    if (!base.startsWith('http')) {
      // Local network / emulator hosts must stay http, public domains use https
      base = _isLocalHost(base) ? 'http://$base' : 'https://$base';
    }

    // Strip trailing slashes and existing /api/v1
    base = base.replaceAll(RegExp(r'/+$'), '');
    base = base.replaceAll(RegExp(r'/api/v1/?$', caseSensitive: false), '');
    return '$base/api/v1';
  }

  void _useLocalhost() {
    setState(() {
      _urlController.text = 'http://localhost:5000';
      _error = '';
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _error = '';
      _isPending = true;
    });

    final storageUrl = _normalizeUrl(_urlController.text);
    if (storageUrl.isEmpty) {
      setState(() {
        _error = 'Please enter a valid server URL.';
        _isPending = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_api_url', storageUrl);
      AppConfig.setCustomUrl(storageUrl);

      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } catch (err) {
      setState(() {
        _error = 'Failed to save server settings on device.';
        _isPending = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textMain, // Back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.textMain,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.boxes,
                    color: theme.surfaceColor,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 48),

                Text(
                  'Server Setup',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: theme.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your self-hosted API endpoint to get started with Inzeedo ERP.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),

                const SizedBox(height: 48),

                AppTextField(
                  label: 'Server API URL',
                  hintText: kReleaseMode
                      ? 'https://pos.yourdomain.com'
                      : 'http://localhost:5000',
                  prefixIcon: LucideIcons.globe,
                  controller: _urlController,
                  disabled: _isPending,
                ),

                if (!kReleaseMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isPending ? null : _useLocalhost,
                          icon: const Icon(
                              LucideIcons.monitorSmartphone,
                              size: 16),
                          label: const Text(
                            'Use localhost:5000',
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPending
                              ? null
                              : () => setState(() {
                                    _urlController.text =
                                        'http://10.0.2.2:5000';
                                    _error = '';
                                  }),
                          icon: const Icon(
                              LucideIcons.smartphone,
                              size: 16),
                          label: const Text(
                            'Emulator 10.0.2.2',
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Info Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.brand.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(
                          LucideIcons.shieldCheck,
                          color: AppColors.brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text:
                                'Your URL is stored locally on this device. We recommend using ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.textSecondary,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'HTTPS',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(
                                text: ' for secure communication.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                AppButton(
                  onPressed: _handleSave,
                  isLoading: _isPending,
                  child: const Text('Save & Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
