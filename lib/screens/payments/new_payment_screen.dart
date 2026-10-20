import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/finance.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  const NewPaymentScreen({super.key});

  @override
  ConsumerState<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends ConsumerState<NewPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  PaymentParty _party = PaymentParty.manufacturer;
  PaymentMethod _method = PaymentMethod.cash;
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(financeRepositoryProvider).addPayment(Payment(
            id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
            party: _party,
            partyName: _party == PaymentParty.manufacturer
                ? 'Inzeedo Manufacturing (Pvt) Ltd'
                : 'Shop payment',
            amount: double.parse(_amount.text.trim()),
            method: _method,
            reference: _reference.text.trim(),
            notes: _notes.text.trim(),
          ));
      ref.invalidate(paymentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Payment recorded'),
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Could not record payment'),
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTopBar(
                title: 'Record Payment',
                showBack: true,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pay to',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<PaymentParty>(
                            segments: const [
                              ButtonSegment(
                                  value: PaymentParty.manufacturer,
                                  label: Text('Manufacturer')),
                              ButtonSegment(
                                  value: PaymentParty.shop,
                                  label: Text('From shop (received)')),
                            ],
                            selected: {_party},
                            onSelectionChanged: (v) =>
                                setState(() => _party = v.first),
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              side: WidgetStateProperty.all(
                                BorderSide(color: theme.surfaceMutedColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Amount *',
                            controller: _amount,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            hint: '0.00',
                            prefixText: 'Rs ',
                            validator: (v) {
                              final n = double.tryParse(v?.trim() ?? '');
                              if (n == null || n <= 0) return 'Enter amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Method',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<PaymentMethod>(
                            initialValue: _method,
                            items: const [
                              DropdownMenuItem(
                                  value: PaymentMethod.cash,
                                  child: Text('Cash')),
                              DropdownMenuItem(
                                  value: PaymentMethod.bankTransfer,
                                  child: Text('Bank transfer')),
                              DropdownMenuItem(
                                  value: PaymentMethod.cheque,
                                  child: Text('Cheque')),
                              DropdownMenuItem(
                                  value: PaymentMethod.mobile,
                                  child: Text('Mobile payment')),
                            ],
                            onChanged: (v) => setState(
                                () => _method = v ?? PaymentMethod.cash),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.surfaceColor,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              prefixIcon: SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: SvgPicture.asset(
                                      'assets/svg/badge_wallet.svg',
                                      colorFilter: ColorFilter.mode(
                                          theme.textSecondary,
                                          BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: theme.surfaceMutedColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.brand, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Reference / Cheque no.',
                            controller: _reference,
                            prefixSvg: 'assets/svg/field_receipt.svg',
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Notes',
                            controller: _notes,
                            prefixSvg: 'assets/svg/field_note.svg',
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Save Payment',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
