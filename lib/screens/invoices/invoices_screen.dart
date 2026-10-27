import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/finance.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/status_colors.dart';
import '../../widgets/common.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  InvoiceStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoices = ref.watch(invoicesProvider);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/more');
      }
    }

    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/more');
      },
      child: Scaffold(
        backgroundColor: theme.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: 'Invoices',
                showBack: true,
                onBack: handleBack,
              ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip(null, 'All'),
                  _filterChip(InvoiceStatus.unpaid, 'Unpaid'),
                  _filterChip(InvoiceStatus.partiallyPaid, 'Partial'),
                  _filterChip(InvoiceStatus.paid, 'Paid'),
                ],
              ),
            ),
            Expanded(
              child: invoices.when(
                data: (list) {
                  final filtered = _filter == null
                      ? list
                      : list.where((i) => i.status == _filter).toList();
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.description_outlined,
                      title: 'No invoices',
                      subtitle: 'Generated invoices appear here.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(invoicesProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final inv = filtered[index];
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => context.push('/more/invoices/${inv.id}'),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      invoiceStatusColor(inv.status)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.description_rounded,
                                  size: 20,
                                  color: invoiceStatusColor(inv.status),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inv.invoiceNumber,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: theme.textMain,
                                      ),
                                    ),
                                    Text(
                                      '${inv.shopName} • ${F.date(inv.date)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: theme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    F.money(inv.total),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: theme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusChip(
                                    label: inv.status == InvoiceStatus.paid
                                        ? 'Paid'
                                        : inv.status ==
                                                InvoiceStatus.partiallyPaid
                                            ? 'Partial'
                                            : 'Unpaid',
                                    color: invoiceStatusColor(inv.status),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const LoadingShimmer(),
                error: (_, _) => const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load invoices',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _filterChip(InvoiceStatus? status, String label) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = status),
        selectedColor: AppColors.brand.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.brand : null,
        ),
      ),
    );
  }
}
