import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/finance.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final payments = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: theme.bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/more/payments/new'),
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Record Payment',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Payments',
              showBack: true,
              onBack: () => context.go('/more'),
            ),
            Expanded(
              child: payments.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.wallet_outlined,
                      title: 'No payments',
                      subtitle: 'Recorded payments appear here.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(paymentsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final p = list[index];
                        final isManufacturer =
                            p.party == PaymentParty.manufacturer;
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isManufacturer
                                          ? AppColors.info
                                          : AppColors.success)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isManufacturer
                                      ? Icons.outgoing_mail
                                      : Icons.payments_rounded,
                                  size: 20,
                                  color: isManufacturer
                                      ? AppColors.info
                                      : AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.partyName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${F.date(p.date)} • ${_methodLabel(p.method)}'
                                      '${p.reference.isEmpty ? '' : ' • ${p.reference}'}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                    if (p.notes.isNotEmpty)
                                      Text(
                                        p.notes,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                          color: theme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                F.money(p.amount),
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isManufacturer
                                      ? AppColors.info
                                      : AppColors.success,
                                ),
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
                  title: 'Could not load payments',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank transfer';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.mobile:
        return 'Mobile';
    }
  }
}
