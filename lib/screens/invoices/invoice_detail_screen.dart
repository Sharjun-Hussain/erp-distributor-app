import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/finance.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/status_colors.dart';
import '../../widgets/common.dart';

final _invoiceByIdProvider = Provider.family<Invoice?, String>((ref, id) {
  final invoices = ref.watch(invoicesProvider).valueOrNull;
  if (invoices == null) return null;
  try {
    return invoices.firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
});

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  String _shareText(Invoice inv) {
    final buffer = StringBuffer()
      ..writeln('INVOICE ${inv.invoiceNumber}')
      ..writeln('Date: ${F.date(inv.date)}')
      ..writeln('To: ${inv.shopName}')
      ..writeln('--------------------------------');
    for (final item in inv.items) {
      buffer.writeln(
          '${item.productName}  ${item.qty} x ${F.money(item.unitPrice)} = ${F.money(item.lineTotal)}');
    }
    buffer
      ..writeln('--------------------------------')
      ..writeln('Total: ${F.money(inv.total)}')
      ..writeln('Status: ${inv.status.name.toUpperCase()}')
      ..writeln('')
      ..writeln('Distributed by: ${inv.distributedBy.name}')
      ..writeln(inv.distributedBy.address)
      ..writeln(inv.distributedBy.phone);
    return buffer.toString();
  }

  void _action(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inv = ref.watch(_invoiceByIdProvider(invoiceId));

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/more/invoices');
      }
    }

    final canPop = context.canPop();

    if (inv == null) {
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/more/invoices');
        },
        child: Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            title: const Text('Invoice'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Invoice not found',
            subtitle: 'It may have been removed.',
          ),
        ),
      );
    }

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/more/invoices');
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: inv.invoiceNumber,
                showBack: true,
                onBack: handleBack,
                actions: [
                  StatusChip(
                    label: inv.status == InvoiceStatus.paid
                      ? 'Paid'
                      : inv.status == InvoiceStatus.partiallyPaid
                          ? 'Partial'
                          : 'Unpaid',
                  color: invoiceStatusColor(inv.status),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Invoice paper
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Company (seller)
                        Center(
                          child: Column(
                            children: [
                              Text(
                                inv.company.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textMain,
                                ),
                              ),
                              Text(
                                inv.company.address,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: theme.textSecondary,
                                ),
                              ),
                              Text(
                                inv.company.phone,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BILL TO',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    inv.shopName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textMain,
                                    ),
                                  ),
                                  Text(
                                    inv.shopAddress,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    inv.shopPhone,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'INVOICE #',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textSecondary,
                                  ),
                                ),
                                Text(
                                  inv.invoiceNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textMain,
                                  ),
                                ),
                                Text(
                                  F.date(inv.date),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Items
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          color: theme.surfaceColor,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text('Item',
                                    style: _headStyle(theme)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('Qty',
                                    textAlign: TextAlign.right,
                                    style: _headStyle(theme)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Price',
                                    textAlign: TextAlign.right,
                                    style: _headStyle(theme)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Total',
                                    textAlign: TextAlign.right,
                                    style: _headStyle(theme)),
                              ),
                            ],
                          ),
                        ),
                        for (final item in inv.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    item.productName,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: theme.textMain),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${item.qty}',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: theme.textMain),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    F.money(item.unitPrice),
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: theme.textMain),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    F.money(item.lineTotal),
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textMain),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Text('Subtotal',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: theme.textSecondary)),
                              const Spacer(),
                              Text(F.money(inv.subtotal),
                                  style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: theme.textMain)),
                            ],
                          ),
                        ),
                        if (inv.discount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Text('Discount',
                                    style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: theme.textSecondary)),
                                const Spacer(),
                                Text('- ${F.money(inv.discount)}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: AppColors.success)),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Text('TOTAL',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: theme.textMain)),
                              const Spacer(),
                              Text(F.money(inv.total),
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brand)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 6),
                        // Distributed by (client requirement)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.brand.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DISTRIBUTED BY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                inv.distributedBy.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textMain,
                                ),
                              ),
                              Text(
                                inv.distributedBy.address,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: theme.textSecondary,
                                ),
                              ),
                              Text(
                                inv.distributedBy.phone,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.glassBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      theme,
                      icon: Icons.print_rounded,
                      label: 'Print',
                      filled: true,
                      onTap: () => _action(context,
                          'Bluetooth printer flow will be wired to real data'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      theme,
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () => SharePlus.instance
                          .share(ShareParams(text: _shareText(inv))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton(
                      theme,
                      icon: Icons.sms_outlined,
                      label: 'SMS',
                      onTap: () =>
                          _action(context, 'SMS gateway pending configuration'),
                    ),
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

  TextStyle _headStyle(ThemeData theme) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: theme.textSecondary,
      );

  Widget _actionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? AppColors.brand : theme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? AppColors.brand : theme.surfaceMutedColor,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18, color: filled ? Colors.white : theme.textMain),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : theme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
