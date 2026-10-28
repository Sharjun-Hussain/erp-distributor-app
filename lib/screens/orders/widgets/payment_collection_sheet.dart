import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common.dart';

class PaymentSplitResult {
  final double cashAmount;
  final double bankAmount;
  final String bankRef;
  final double chequeAmount;
  final String chequeNo;
  final DateTime? chequeDate;
  final String chequeBank;

  const PaymentSplitResult({
    this.cashAmount = 0,
    this.bankAmount = 0,
    this.bankRef = '',
    this.chequeAmount = 0,
    this.chequeNo = '',
    this.chequeDate,
    this.chequeBank = '',
  });

  double get totalPaid => cashAmount + bankAmount + chequeAmount;

  List<Map<String, dynamic>> toPaymentsList() {
    final list = <Map<String, dynamic>>[];
    if (cashAmount > 0) {
      list.add({
        'payment_type': 'cash',
        'amount': cashAmount,
      });
    }
    if (bankAmount > 0) {
      list.add({
        'payment_type': 'bank_transfer',
        'amount': bankAmount,
        'bank_ref': bankRef.isNotEmpty ? bankRef : null,
      });
    }
    if (chequeAmount > 0) {
      list.add({
        'payment_type': 'cheque',
        'amount': chequeAmount,
        'cheque_no': chequeNo.isNotEmpty ? chequeNo : null,
        'cheque_date': chequeDate?.toIso8601String().split('T').first,
        'cheque_bank': chequeBank.isNotEmpty ? chequeBank : null,
        'cheque_status': 'pending',
      });
    }
    return list;
  }
}

class PaymentCollectionSheet extends StatefulWidget {
  final double orderTotal;
  final String shopName;
  final String title;

  const PaymentCollectionSheet({
    super.key,
    required this.orderTotal,
    required this.shopName,
    this.title = 'Collect Payment',
  });

  static Future<PaymentSplitResult?> show(
    BuildContext context, {
    required double orderTotal,
    required String shopName,
    String title = 'Collect Payment',
  }) {
    return showModalBottomSheet<PaymentSplitResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentCollectionSheet(
        orderTotal: orderTotal,
        shopName: shopName,
        title: title,
      ),
    );
  }

  @override
  State<PaymentCollectionSheet> createState() => _PaymentCollectionSheetState();
}

class _PaymentCollectionSheetState extends State<PaymentCollectionSheet> {
  final _cashController = TextEditingController();
  final _bankController = TextEditingController();
  final _bankRefController = TextEditingController();
  final _chequeController = TextEditingController();
  final _chequeNoController = TextEditingController();
  final _chequeBankController = TextEditingController();

  DateTime? _chequeDate;
  bool _showBankFields = false;
  bool _showChequeFields = false;

  @override
  void initState() {
    super.initState();
    // Default to full cash for quick 1-tap checkout
    _cashController.text = widget.orderTotal.toStringAsFixed(2);
    _cashController.addListener(() => setState(() {}));
    _bankController.addListener(() => setState(() {}));
    _chequeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    _bankRefController.dispose();
    _chequeController.dispose();
    _chequeNoController.dispose();
    _chequeBankController.dispose();
    super.dispose();
  }

  double get _cash => double.tryParse(_cashController.text.trim()) ?? 0;
  double get _bank => double.tryParse(_bankController.text.trim()) ?? 0;
  double get _cheque => double.tryParse(_chequeController.text.trim()) ?? 0;
  double get _totalPaid => _cash + _bank + _cheque;
  double get _balanceDue =>
      (widget.orderTotal - _totalPaid) > 0 ? (widget.orderTotal - _totalPaid) : 0;

  void _setFullCash() {
    setState(() {
      _cashController.text = widget.orderTotal.toStringAsFixed(2);
      _bankController.clear();
      _chequeController.clear();
      _showBankFields = false;
      _showChequeFields = false;
    });
  }

  void _setFullCredit() {
    setState(() {
      _cashController.clear();
      _bankController.clear();
      _chequeController.clear();
      _showBankFields = false;
      _showChequeFields = false;
    });
  }

  Future<void> _pickChequeDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _chequeDate = picked);
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      PaymentSplitResult(
        cashAmount: _cash,
        bankAmount: _bank,
        bankRef: _bankRefController.text.trim(),
        chequeAmount: _cheque,
        chequeNo: _chequeNoController.text.trim(),
        chequeDate: _chequeDate,
        chequeBank: _chequeBankController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.glassBorder),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                      Text(
                        widget.shopName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      F.money(widget.orderTotal),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Presets
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _setFullCash,
                      icon: const Icon(LucideIcons.banknote, size: 14),
                      label: const Text('Full Cash'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _setFullCredit,
                      icon: const Icon(LucideIcons.clock, size: 14),
                      label: const Text('On Credit'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.warning,
                        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. CASH INPUT
              _buildAmountField(
                theme,
                controller: _cashController,
                label: 'Cash Amount (Rs.)',
                icon: LucideIcons.banknote,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),

              // 2. BANK TRANSFER
              _buildToggleHeader(
                theme,
                label: 'Direct Bank Transfer',
                icon: LucideIcons.building2,
                color: const Color(0xFF0284C7),
                isExpanded: _showBankFields || _bank > 0,
                onToggle: () => setState(() => _showBankFields = !_showBankFields),
              ),
              if (_showBankFields || _bank > 0) ...[
                const SizedBox(height: 8),
                _buildAmountField(
                  theme,
                  controller: _bankController,
                  label: 'Bank Amount (Rs.)',
                  icon: LucideIcons.building2,
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bankRefController,
                  decoration: InputDecoration(
                    hintText: 'Reference / Deposit Slip No. (optional)',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: theme.textSecondary),
                    filled: true,
                    fillColor: theme.surfaceColor,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.glassBorder),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: theme.textMain),
                ),
              ],
              const SizedBox(height: 12),

              // 3. CHEQUE PAYMENT (PDC)
              _buildToggleHeader(
                theme,
                label: 'Cheque Payment (PDC)',
                icon: LucideIcons.fileText,
                color: const Color(0xFF8B5CF6),
                isExpanded: _showChequeFields || _cheque > 0,
                onToggle: () => setState(() => _showChequeFields = !_showChequeFields),
              ),
              if (_showChequeFields || _cheque > 0) ...[
                const SizedBox(height: 8),
                _buildAmountField(
                  theme,
                  controller: _chequeController,
                  label: 'Cheque Amount (Rs.)',
                  icon: LucideIcons.fileText,
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _chequeNoController,
                        decoration: InputDecoration(
                          hintText: 'Cheque #',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: theme.textSecondary),
                          filled: true,
                          fillColor: theme.surfaceColor,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.glassBorder),
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 13, color: theme.textMain),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: _pickChequeDate,
                        icon: const Icon(LucideIcons.calendar, size: 14),
                        label: Text(
                          _chequeDate != null
                              ? F.shortDate(_chequeDate!)
                              : 'Due Date',
                          style: GoogleFonts.inter(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _chequeBankController,
                  decoration: InputDecoration(
                    hintText: 'Bank Name (e.g. Commercial, Sampath)',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: theme.textSecondary),
                    filled: true,
                    fillColor: theme.surfaceColor,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.glassBorder),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: theme.textMain),
                ),
              ],
              const SizedBox(height: 16),

              // Summary Breakdown Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.glassBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Collected Now:', style: GoogleFonts.inter(fontSize: 12, color: theme.textSecondary)),
                        Text(F.money(_totalPaid), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                      ],
                    ),
                    if (_balanceDue > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining to Credit / Due:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.danger)),
                          Text(F.money(_balanceDue), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.danger)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Confirm Button
              PrimaryButton(
                label: 'Confirm & Complete',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: theme.textSecondary),
        prefixIcon: Icon(icon, size: 16, color: color),
        filled: true,
        fillColor: theme.surfaceColor,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brand, width: 1.5),
        ),
      ),
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: theme.textMain,
      ),
    );
  }

  Widget _buildToggleHeader(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textMain,
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
              color: theme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
