import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/shop.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
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
        text: shop == null ? '' : shop.creditLimit.toStringAsFixed(0));
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
        id: existing?.id ??
            's-${DateTime.now().millisecondsSinceEpoch}',
        name: _name.text.trim(),
        contactPerson: _contact.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        creditLimit: double.tryParse(_credit.text.trim()) ?? 0,
        balance: existing?.balance ?? 0,
      );
      await ref.read(shopsRepositoryProvider).saveShop(shop);
      ref.invalidate(shopsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(_isEdit ? 'Shop updated' : 'Shop added'),
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Could not save shop'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: _isEdit ? 'Edit Shop' : 'Add Shop',
              showBack: true,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          _field(
                            'Shop name *',
                            _name,
                            prefixSvg: 'assets/svg/badge_store.svg',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          _field('Contact person', _contact,
                              prefixSvg: 'assets/svg/field_user.svg'),
                          _field(
                            'Phone',
                            _phone,
                            prefixSvg: 'assets/svg/field_phone.svg',
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (v.trim().length < 7) return 'Invalid phone';
                              return null;
                            },
                          ),
                          _field(
                            'Email',
                            _email,
                            prefixSvg: 'assets/svg/field_mail.svg',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          _field('Address', _address,
                              prefixSvg: 'assets/svg/field_pin.svg',
                              maxLines: 2),
                          _field(
                            'Credit limit',
                            _credit,
                            prefixSvg: 'assets/svg/field_credit.svg',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _isEdit ? 'Save Changes' : 'Add Shop',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixSvg,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppTextField(
        controller: controller,
        label: label,
        prefixSvg: prefixSvg,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}
