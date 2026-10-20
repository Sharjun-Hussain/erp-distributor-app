import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

final _shopQueryProvider = StateProvider<String>((ref) => '');

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(_shopQueryProvider);
    final shops = ref.watch(shopsProvider);

    return Scaffold(
      backgroundColor: theme.bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shops/new'),
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Shop',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'My Shops',
              bottom: SearchField(
                controller: _controller,
                hint: 'Search shops...',
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300),
                      () => ref.read(_shopQueryProvider.notifier).state = v);
                },
              ),
            ),
            Expanded(
              child: shops.when(
                data: (list) {
                  final q = query.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? list
                      : list
                          .where((s) =>
                              s.name.toLowerCase().contains(q) ||
                              s.phone.contains(q))
                          .toList();
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'No shops found',
                      subtitle: 'Add your shop clients to start taking orders.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(shopsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final shop = filtered[index];
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => context.push('/shops/${shop.id}'),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    AppColors.brand.withValues(alpha: 0.12),
                                child: Text(
                                  shop.name.characters.first.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textMain,
                                      ),
                                    ),
                                    Text(
                                      shop.phone.isEmpty
                                          ? shop.address
                                          : '${shop.phone} • ${shop.address}',
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
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.textSecondary,
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
                  title: 'Could not load shops',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
