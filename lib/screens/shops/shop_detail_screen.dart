import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/cart_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

final _shopByIdProvider = Provider.family<dynamic, String>((ref, id) {
  final shops = ref.watch(shopsProvider).valueOrNull;
  if (shops == null) return null;
  try {
    return shops.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shop = ref.watch(_shopByIdProvider(shopId));

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/shops');
      }
    }

    final canPop = context.canPop();

    if (shop == null) {
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go('/shops');
        },
        child: Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            title: const Text('Shop'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Shop not found',
            subtitle: 'It may have been removed.',
          ),
        ),
      );
    }

    final orders = ref.watch(shopOrdersProvider).valueOrNull ?? [];
    final shopOrders =
        orders.where((o) => o.shopId == shop.id).toList();

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
                title: shop.name,
                showBack: true,
                onBack: handleBack,
              actions: [
                IconButton(
                  onPressed: () => context.push('/shops/$shopId/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        InfoRow(
                            label: 'Contact person',
                            value: shop.contactPerson.isEmpty
                                ? '—'
                                : shop.contactPerson),
                        InfoRow(
                            label: 'Phone',
                            value: shop.phone.isEmpty ? '—' : shop.phone),
                        InfoRow(
                            label: 'Email',
                            value: shop.email.isEmpty ? '—' : shop.email),
                        InfoRow(
                            label: 'Address',
                            value: shop.address.isEmpty ? '—' : shop.address),
                        InfoRow(
                          label: 'Balance',
                          value: F.money(shop.balance),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'New Order',
                          icon: LucideIcons.clipboardPlus,
                          onPressed: () {
                            ref
                                .read(cartProvider.notifier)
                                .startShopOrder(shop);
                            context.go('/catalog');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SecondaryButton(
                          label: 'Sell Now',
                          icon: LucideIcons.zap,
                          onPressed: () {
                            ref
                                .read(cartProvider.notifier)
                                .startDirectSale(shop);
                            context.go('/catalog');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Call',
                          icon: Icons.phone_outlined,
                          onPressed: shop.phone.isEmpty
                              ? null
                              : () async {
                                  final uri =
                                      Uri(scheme: 'tel', path: shop.phone);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SecondaryButton(
                          label: 'WhatsApp',
                          icon: Icons.chat_outlined,
                          onPressed: shop.phone.isEmpty
                              ? null
                              : () async {
                                  final uri = Uri.parse(
                                      'https://wa.me/94${shop.phone.replaceFirst(RegExp(r'^0'), '')}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                        uri,
                                        mode: LaunchMode
                                            .externalApplication);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(
                    title: 'Orders (${shopOrders.length})',
                    trailing: TextButton(
                      onPressed: () => context.go('/orders?segment=shop'),
                      child: const Text('See all'),
                    ),
                  ),
                  if (shopOrders.isEmpty)
                    const AppCard(
                      child: Text('No orders for this shop yet.'),
                    )
                  else
                    ...shopOrders.take(5).map(
                          (o) => AppCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => context.push('/orders/shop/${o.id}'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        o.orderNumber,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textMain,
                                        ),
                                      ),
                                      Text(
                                        F.date(o.date),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: theme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  F.money(o.total),
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textMain,
                                  ),
                                ),
                              ],
                            ),
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
}
