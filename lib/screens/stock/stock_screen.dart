import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stock = ref.watch(stockProvider);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'My Stock',
              showBack: true,
              onBack: () => context.go('/more'),
            ),
            Expanded(
              child: stock.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No stock yet',
                      subtitle: 'Delivered items appear here.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(stockProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final low = e.qty <= 20;
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (low
                                          ? AppColors.danger
                                          : AppColors.brand)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  size: 20,
                                  color: low
                                      ? AppColors.danger
                                      : AppColors.brand,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.productName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textMain,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${e.sku} • Last move ${F.date(e.lastMovement)}',
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
                                    F.qty(e.qty),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: low
                                          ? AppColors.danger
                                          : theme.textMain,
                                    ),
                                  ),
                                  Text(
                                    e.unit,
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
                  title: 'Could not load stock',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
