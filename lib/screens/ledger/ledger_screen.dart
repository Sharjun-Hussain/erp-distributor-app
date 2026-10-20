import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledger = ref.watch(ledgerProvider);
    final balance = ref.watch(authProvider).user?.distributor.balance ?? 0;

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Ledger',
              showBack: true,
              onBack: () => context.go('/more'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding balance',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      F.money(balance),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ledger.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No ledger entries',
                      subtitle: 'Invoices and payments appear here.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(ledgerProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final isDebit = e.debit > 0;
                        final isCredit = e.credit > 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isDebit
                                          ? AppColors.danger
                                          : isCredit
                                              ? AppColors.success
                                              : theme.textSecondary)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isDebit
                                      ? Icons.arrow_upward_rounded
                                      : isCredit
                                          ? Icons.arrow_downward_rounded
                                          : Icons.history_rounded,
                                  size: 16,
                                  color: isDebit
                                      ? AppColors.danger
                                      : isCredit
                                          ? AppColors.success
                                          : theme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textMain,
                                      ),
                                    ),
                                    Text(
                                      F.date(e.date),
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
                                    isDebit
                                        ? '+ ${F.money(e.debit)}'
                                        : isCredit
                                            ? '- ${F.money(e.credit)}'
                                            : F.money(0),
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDebit
                                          ? AppColors.danger
                                          : isCredit
                                              ? AppColors.success
                                              : theme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Bal ${F.money(e.balance)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: theme.textSecondary,
                                    ),
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
                  title: 'Could not load ledger',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
