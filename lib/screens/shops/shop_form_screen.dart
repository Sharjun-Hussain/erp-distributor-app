import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../models/shop.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class ShopFormScreen extends ConsumerStatefulWidget {
  final String? shopId;

  const ShopFormScreen({super.key, this.shopId});

  @override
  ConsumerState<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends ConsumerState<ShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _contact;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _credit;
  bool _saving = false;

  bool get _isEdit => widget.shopId != null;

  @override
  void initState() {
    super.initState();
    final shop = _existing();
    _name = TextEditingController(text: shop?.name ?? '');
    _contact = TextEditingController(text: shop?.contactPerson ?? '');
    _phone = TextEditingController(text: shop?.phone ?? '');
    _email = TextEditingController(text: shop?.email ?? '');
    _address = TextEditingController(text: shop?.address ?? '');
    _credit = TextEditingController(
      text: shop == null || shop.creditLimit == 0
          ? ''
          : shop.creditLimit.toStringAsFixed(0),
    );
  }

  Shop? _existing() {
    if (!_isEdit) return null;
    final shops = ref.read(shopsProvider).valueOrNull ?? [];
    try {
      return shops.firstWhere((s) => s.id == widget.shopId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _credit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final existing = _existing();
      final shop = Shop(
        id: existing?.id ?? 's-${DateTime.now().millisecondsSinceEpoch}',
        name: _name.text.trim(),
        contactPerson: _contact.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        creditLimit: double.tryParse(_credit.text.trim()) ?? 0,
        balance: existing?.balance ?? 0,
        isActive: existing?.isActive ?? true,
      );
      await ref.read(shopsRepositoryProvider).saveShop(shop, isNew: !_isEdit);
      ref.invalidate(shopsProvider);

      if (!mounted) return;
      toastification.show(
        context: context,
        title: Text(_isEdit ? 'Shop Updated' : 'Shop Registered'),
        description: Text(
          _isEdit
              ? 'Changes to "${shop.name}" have been saved.'
              : '"${shop.name}" has been added to your client shops.',
        ),
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 3),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        title: const Text('Save Failed'),
        description: Text(e.toString().replaceAll('Exception: ', '')),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/shops');
      }
    }

    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/shops');
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: _isEdit ? 'Edit Shop' : 'Register Shop',
                showBack: true,
                onBack: handleBack,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          // --- Hero Banner Card ---
                          _buildHeroBanner(theme),

                          const SizedBox(height: 20),

                          // --- Section 1: Store Information ---
                          SectionTitle(title: 'Store Information'),
                          _buildCard(
                            theme,
                            children: [
                              _buildInputField(
                                theme,
                                label: 'Shop Name',
                                isRequired: true,
                                hintText: 'e.g. City Supermarket & Grocery',
                                controller: _name,
                                prefixIcon: LucideIcons.store,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter the shop name';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Shop name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                theme,
                                label: 'Store Address',
                                hintText: 'e.g. 142 Main Street, Colombo 03',
                                controller: _address,
                                prefixIcon: LucideIcons.mapPin,
                                maxLines: 2,
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // --- Section 2: Contact Details ---
                          SectionTitle(title: 'Contact Details'),
                          _buildCard(
                            theme,
                            children: [
                              _buildInputField(
                                theme,
                                label: 'Contact Person',
                                hintText: 'e.g. Nimal Perera (Store Manager)',
                                controller: _contact,
                                prefixIcon: LucideIcons.user,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                theme,
                                label: 'Phone Number',
                                hintText: 'e.g. 077 123 4567',
                                controller: _phone,
                                prefixIcon: LucideIcons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  if (v.trim().length < 7) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                theme,
                                label: 'Email Address',
                                hintText: 'e.g. outlet@example.com',
                                controller: _email,
                                prefixIcon: LucideIcons.mail,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  if (!v.contains('@') || !v.contains('.')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // --- Section 3: Credit Terms ---
                          SectionTitle(title: 'Commercial Terms'),
                          _buildCard(
                            theme,
                            children: [
                              _buildInputField(
                                theme,
                                label: 'Credit Limit',
                                hintText: '0',
                                controller: _credit,
                                prefixIcon: LucideIcons.creditCard,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                prefixWidget: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Rs',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.info,
                                    size: 13,
                                    color: theme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Maximum unpaid invoice balance allowed for this client outlet.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // --- Submit Action Button ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isEdit
                                          ? LucideIcons.check
                                          : LucideIcons.plus,
                                      size: 18,
                                    ),
                              label: Text(
                                _saving
                                    ? 'Saving...'
                                    : (_isEdit
                                        ? 'Save Changes'
                                        : 'Register Shop'),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brand,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                LucideIcons.store,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Update Shop Profile' : 'Register New Client Shop',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: theme.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isEdit
                      ? 'Modify outlet contacts, address, or credit limit terms.'
                      : 'Add store details to collect orders and issue invoices.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputField(
    ThemeData theme, {
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixWidget,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.textMain,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          cursorColor: AppColors.brand,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textMain,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: theme.textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: theme.surfaceColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 12 : 13,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 12, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    prefixIcon,
                    size: 17,
                    color: theme.textSecondary.withValues(alpha: 0.8),
                  ),
                  if (prefixWidget != null) ...[
                    const SizedBox(width: 8),
                    prefixWidget,
                  ],
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? const Color(0x33FFFFFF)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.brand,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.danger.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }
}
