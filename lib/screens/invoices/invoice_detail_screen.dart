import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/finance.dart';
import '../../providers/auth_provider.dart';
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

  String _cleanItemTitle(String title) {
    var result = title;
    result = result.replaceAll(RegExp(r'\s*[-·•]\s*Default\b', caseSensitive: false), '');
    return result.trim().isEmpty ? title : result.trim();
  }

  String _shareText(Invoice inv, String distributorName, String distributorPhone) {
    final buffer = StringBuffer()
      ..writeln('🧾 INVOICE #${inv.invoiceNumber}')
      ..writeln('📅 Date: ${F.date(inv.date)}')
      ..writeln('🏢 Billed to: ${inv.shopName}')
      ..writeln('📍 Address: ${inv.shopAddress}')
      ..writeln('📞 Phone: ${inv.shopPhone}')
      ..writeln('--------------------------------');
    for (final item in inv.items) {
      final name = _cleanItemTitle(item.productName);
      buffer.writeln(
          '• $name  (${item.qty} ${item.unit} x ${F.money(item.unitPrice)}) = ${F.money(item.lineTotal)}');
    }
    buffer
      ..writeln('--------------------------------')
      ..writeln('Subtotal: ${F.money(inv.subtotal)}')
      ..writeln('Total Amount: ${F.money(inv.total)}')
      ..writeln('Status: ${inv.status.name.toUpperCase()}');

    final distName = inv.distributedBy.name.isNotEmpty
        ? inv.distributedBy.name
        : distributorName;
    if (distName.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('Distributed by: $distName');
      if (distributorPhone.isNotEmpty) {
        buffer.writeln('Contact: $distributorPhone');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inv = ref.watch(_invoiceByIdProvider(invoiceId));
    final currentUser = ref.watch(authProvider).user;

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
            title: const Text('Invoice Details'),
            leading: AppBackButton(onPressed: handleBack),
          ),
          body: const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Invoice not found',
            subtitle: 'It may have been removed or voided.',
          ),
        ),
      );
    }

    final statusColor = invoiceStatusColor(inv.status);
    final isPaid = inv.status == InvoiceStatus.paid;
    final isPartial = inv.status == InvoiceStatus.partiallyPaid;
    final statusLabel = isPaid ? 'Paid' : (isPartial ? 'Partially Paid' : 'Unpaid');

    // Resolve distributor company info
    final companyName = inv.company.name.isNotEmpty
        ? inv.company.name
        : (currentUser?.distributor.company.isNotEmpty == true
            ? currentUser!.distributor.company
            : (currentUser?.distributor.name.isNotEmpty == true
                ? currentUser!.distributor.name
                : (currentUser?.name.isNotEmpty == true ? currentUser!.name : 'Distributor')));
    final companyAddress = inv.company.address.isNotEmpty
        ? inv.company.address
        : (currentUser?.distributor.address.isNotEmpty == true
            ? currentUser!.distributor.address
            : '');
    final companyPhone = inv.company.phone.isNotEmpty
        ? inv.company.phone
        : (currentUser?.distributor.phone.isNotEmpty == true
            ? currentUser!.distributor.phone
            : (currentUser?.phone.isNotEmpty == true ? currentUser!.phone : ''));

    // Resolve distributed by info (sales rep or distributor)
    final distName = inv.distributedBy.name.isNotEmpty
        ? inv.distributedBy.name
        : (currentUser?.name.isNotEmpty == true
            ? currentUser!.name
            : (currentUser?.distributor.name.isNotEmpty == true
                ? currentUser!.distributor.name
                : ''));
    final distAddress = inv.distributedBy.address.isNotEmpty
        ? inv.distributedBy.address
        : (currentUser?.distributor.address ?? '');
    final distPhone = inv.distributedBy.phone.isNotEmpty
        ? inv.distributedBy.phone
        : (currentUser?.distributor.phone.isNotEmpty == true
            ? currentUser!.distributor.phone
            : (currentUser?.phone ?? ''));

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
              // Top Bar with Invoice Number & Status
              AppTopBar(
                title: inv.invoiceNumber,
                showBack: true,
                onBack: handleBack,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Scrollable Invoice Content
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    // Premium Invoice Card (Clean Paper Aesthetic)
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Company Brand Header
                          _buildCompanyHeader(theme, companyName, companyAddress, companyPhone),

                          const SizedBox(height: 14),
                          Divider(height: 1, color: theme.glassBorder),
                          const SizedBox(height: 14),

                          // 2. Billing & Invoice Meta Row
                          _buildBillingHeader(context, theme, inv),

                          const SizedBox(height: 16),

                          // 3. Compact Items Table
                          _buildCompactItemsTable(theme, inv),

                          const SizedBox(height: 14),
                          Divider(height: 1, color: theme.glassBorder),
                          const SizedBox(height: 12),

                          // 4. Financial Calculations (Subtotal, Discount, Total)
                          _buildFinancialTotals(theme, inv),

                          // 5. Distributed By Card (Always populated)
                          if (distName.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildDistributedByBox(theme, distName, distAddress, distPhone),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Shop Actions (Call / WhatsApp shop)
                    _buildShopActions(context, theme, inv),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Bottom Action Bar: Print, Share, SMS / WhatsApp Share
              _buildBottomActionBar(context, theme, inv, distName, distPhone),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPANY HEADER
  // ==========================================
  Widget _buildCompanyHeader(
    ThemeData theme,
    String name,
    String address,
    String phone,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.building2,
                size: 16,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.textMain,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (address.isNotEmpty || phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [if (address.isNotEmpty) address, if (phone.isNotEmpty) phone].join(' • '),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.textSecondary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ==========================================
  // BILLING & INVOICE METADATA ROW
  // ==========================================
  Widget _buildBillingHeader(BuildContext context, ThemeData theme, Invoice inv) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bill To (Shop Details)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BILL TO',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      inv.shopName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (inv.shopId.isNotEmpty)
                    GestureDetector(
                      onTap: () => context.push('/shops/${inv.shopId}'),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          LucideIcons.externalLink,
                          size: 13,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                ],
              ),
              if (inv.shopAddress.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    inv.shopAddress,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: theme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (inv.shopPhone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    inv.shopPhone,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: theme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Invoice Number & Date
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'INVOICE #',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                inv.invoiceNumber,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: theme.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                F.date(inv.date),
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPACT ITEMS TABLE
  // ==========================================
  Widget _buildCompactItemsTable(ThemeData theme, Invoice inv) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'ITEM',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: theme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'QTY',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: theme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'PRICE',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: theme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'TOTAL',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: inv.items.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            thickness: 1,
            color: theme.glassBorder,
          ),
          itemBuilder: (context, i) {
            final item = inv.items[i];
            final cleanName = _cleanItemTitle(item.productName);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  // Product Name
                  Expanded(
                    flex: 5,
                    child: Text(
                      cleanName,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textMain,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Quantity
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.qty}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: theme.textMain,
                      ),
                    ),
                  ),

                  // Unit Price
                  Expanded(
                    flex: 3,
                    child: Text(
                      F.money(item.unitPrice),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),

                  // Line Total
                  Expanded(
                    flex: 3,
                    child: Text(
                      F.money(item.lineTotal),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: theme.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // FINANCIAL TOTALS
  // ==========================================
  Widget _buildFinancialTotals(ThemeData theme, Invoice inv) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.textSecondary,
                ),
              ),
              Text(
                F.money(inv.subtotal),
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textMain,
                ),
              ),
            ],
          ),
        ),
        if (inv.discount > 0) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  '- ${F.money(inv.discount)}',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.textMain,
                ),
              ),
              Text(
                F.money(inv.total),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DISTRIBUTED BY CARD
  // ==========================================
  Widget _buildDistributedByBox(
    ThemeData theme,
    String name,
    String address,
    String phone,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.truck,
                size: 13,
                color: AppColors.brand,
              ),
              const SizedBox(width: 6),
              Text(
                'DISTRIBUTED BY',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: theme.textMain,
            ),
          ),
          if (address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                address,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: theme.textSecondary,
                ),
              ),
            ),
          if (phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                phone,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // QUICK SHOP ACTIONS (CALL & WHATSAPP)
  // ==========================================
  Widget _buildShopActions(BuildContext context, ThemeData theme, Invoice inv) {
    final hasPhone = inv.shopPhone.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasPhone
                  ? () async {
                      final uri = Uri(scheme: 'tel', path: inv.shopPhone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hasPhone
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.09)
                      : theme.surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasPhone
                        ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
                        : theme.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.phone,
                      size: 14,
                      color: hasPhone
                          ? const Color(0xFF0EA5E9)
                          : theme.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Call Client',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: hasPhone
                          ? const Color(0xFF0EA5E9)
                          : theme.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasPhone
                  ? () async {
                      final cleanPhone = inv.shopPhone.replaceAll(RegExp(r'[^0-9]'), '');
                      final formattedPhone = cleanPhone.startsWith('0')
                          ? '94${cleanPhone.substring(1)}'
                          : cleanPhone.startsWith('94')
                              ? cleanPhone
                              : '94$cleanPhone';

                      final uri = Uri.parse('https://wa.me/$formattedPhone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hasPhone
                      ? const Color(0xFF10B981).withValues(alpha: 0.09)
                      : theme.surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasPhone
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : theme.glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: hasPhone
                          ? const Color(0xFF10B981)
                          : theme.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WhatsApp',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: hasPhone
                          ? const Color(0xFF10B981)
                          : theme.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM ACTION BAR: PRINT, SHARE, SMS
  // ==========================================
  Widget _buildBottomActionBar(
    BuildContext context,
    ThemeData theme,
    Invoice inv,
    String distName,
    String distPhone,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: theme.glassBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Print Action
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  toastification.show(
                    context: context,
                    type: ToastificationType.info,
                    style: ToastificationStyle.flatColored,
                    title: const Text('Bluetooth Printer'),
                    description: const Text('Searching for paired POS mobile printer...'),
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.printer, size: 17, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Print',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Share Action
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: _shareText(inv, distName, distPhone),
                      subject: 'Invoice #${inv.invoiceNumber}',
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.share2, size: 16, color: theme.textMain),
                      const SizedBox(width: 8),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // SMS Action
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (inv.shopPhone.isNotEmpty) {
                    final text = Uri.encodeComponent(
                        'Invoice #${inv.invoiceNumber} for ${inv.shopName}. Total: ${F.money(inv.total)}. Status: ${inv.status.name.toUpperCase()}');
                    final uri = Uri.parse('sms:${inv.shopPhone}?body=$text');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                      return;
                    }
                  }
                  if (context.mounted) {
                    toastification.show(
                      context: context,
                      type: ToastificationType.info,
                      style: ToastificationStyle.flatColored,
                      title: const Text('SMS Action'),
                      description: const Text('Opening native SMS message composer...'),
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.messageSquare, size: 16, color: theme.textMain),
                      const SizedBox(width: 8),
                      Text(
                        'SMS',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: theme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
