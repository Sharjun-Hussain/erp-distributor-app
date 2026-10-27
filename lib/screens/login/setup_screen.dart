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
    _urlController.addListener(_onUrlChanged);
    _loadExistingUrl();
  }

  void _onUrlChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadExistingUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConfig.customApiUrlKey);
    if (saved != null && saved.isNotEmpty) {
      // Remove trailing API paths for display
      final display = saved.replaceAll(RegExp(r'/api/v1/?$'), '');
      _urlController.text = display;
    } else {
      _urlController.text = AppConfig.productionBaseUrl;
    }
    if (mounted) setState(() {});
  }

  bool _isLocalHost(String input) {
    final v = input.trim().toLowerCase();
    return v.contains('localhost') ||
        v.contains('127.0.0.1') ||
        v.contains('10.0.2.2') ||
        v.contains('192.168.') ||
        v.contains('10.');
  }

  String _cleanForCompare(String url) {
    var s = url.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'^https?://'), '');
    s = s.replaceAll(RegExp(r'/api/v1/?$'), '');
    s = s.replaceAll(RegExp(r'/+$'), '');
    return s;
  }

  String _normalizeUrl(String input) {
    String base = input.trim();
    if (base.isEmpty) return '';

    if (!base.startsWith('http')) {
      // Local network / emulator hosts stay http, public domains use https
      base = _isLocalHost(base) ? 'http://$base' : 'https://$base';
    }

    // Strip trailing slashes and existing /api/v1
    base = base.replaceAll(RegExp(r'/+$'), '');
    base = base.replaceAll(RegExp(r'/api/v1/?$', caseSensitive: false), '');
    return '$base/api/v1';
  }

  void _selectPreset(String url) {
    setState(() {
      _urlController.text = url;
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
      await AppConfig.saveServerUrl(storageUrl);

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
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  Widget _buildPresetCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String targetUrl,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final currentClean = _cleanForCompare(_urlController.text);
    final targetClean = _cleanForCompare(targetUrl);
    final isSelected = currentClean == targetClean;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isPending ? null : () => _selectPreset(targetUrl),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.08)
                : theme.surfaceMutedColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : theme.glassBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.16)
                      : theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? accentColor : theme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? accentColor : theme.textMain,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: theme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 20,
                color: isSelected
                    ? accentColor
                    : theme.textSecondary.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textMain,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Logo
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

                const SizedBox(height: 36),

                Text(
                  'Server Setup',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: theme.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a preset environment or configure a custom API endpoint for Inzeedo ERP.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Presets Section
                Row(
                  children: [
                    Icon(
                      LucideIcons.zap,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'QUICK PRESETS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Preset 1: Live Production
                _buildPresetCard(
                  context: context,
                  title: 'Live Production',
                  subtitle: AppConfig.productionBaseUrl,
                  targetUrl: AppConfig.productionBaseUrl,
                  icon: LucideIcons.cloudCheck,
                  accentColor: Colors.green,
                ),
                const SizedBox(height: 10),

                // Preset 2: Localhost
                _buildPresetCard(
                  context: context,
                  title: 'Localhost (Dev Server)',
                  subtitle: AppConfig.localhostBaseUrl,
                  targetUrl: AppConfig.localhostBaseUrl,
                  icon: LucideIcons.laptop,
                  accentColor: AppColors.brand,
                ),
                const SizedBox(height: 10),

                // Preset 3: Android Emulator
                _buildPresetCard(
                  context: context,
                  title: 'Android Emulator',
                  subtitle: AppConfig.emulatorBaseUrl,
                  targetUrl: AppConfig.emulatorBaseUrl,
                  icon: LucideIcons.smartphone,
                  accentColor: Colors.orange,
                ),

                const SizedBox(height: 32),

                // Custom URL Input Section
                Row(
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CUSTOM ENDPOINT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Server API URL',
                  hintText: 'https://pos-api-v2.inzeedo.lk',
                  prefixIcon: LucideIcons.globe,
                  controller: _urlController,
                  disabled: _isPending,
                ),

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circleAlert,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
                                'Server settings are stored securely on this device and applied immediately to all API requests.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                AppButton(
                  onPressed: _handleSave,
                  isLoading: _isPending,
                  child: const Text('Save & Connect'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
