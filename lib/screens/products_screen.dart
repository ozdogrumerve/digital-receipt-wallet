import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

class ProductsScreen extends StatelessWidget {
  final ReceiptModel transaction;

  const ProductsScreen({
    super.key,
    required this.transaction,
  });

  String formatTL(double amount) =>
      "₺${amount.toStringAsFixed(2)}";

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Clothing':
        return Icons.checkroom;
      case 'Tech':
        return Icons.devices;
      case 'Transportation':
        return Icons.commute;
      case 'Bills':
        return Icons.receipt;
      case 'Rent':
        return Icons.home;
      case 'Education':
        return Icons.school;
      case 'Healthcare':
        return Icons.health_and_safety;
      case 'Personal Care':
        return Icons.spa;
      case 'Entertainment':
        return Icons.sports_esports;
      case 'Household / Furniture':
        return Icons.chair;
      case 'Stationery':
        return Icons.edit;
      case 'Vacation / Travel':
        return Icons.flight_takeoff;
      case 'Taxes / Official Payments':
        return Icons.account_balance;
      case 'Other':
        return Icons.shopping_bag;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final FirestoreService service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.productDetails),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Header ──────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HeaderBackground(
                transaction: transaction,
                categoryIcon: _getCategoryIcon(transaction.category),
                formatTL: formatTL,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
            ),
          ),

          // ── Meta info strip ─────────────────────────────────
          SliverToBoxAdapter(
            child: _MetaStrip(transaction: transaction),
          ),

          // ── Section header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.items,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Products list ────────────────────────────────────
          StreamBuilder<List<ProductModel>>(
            stream: service.getProducts(transaction.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final products = snapshot.data!;

              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 52,
                          color: theme.colorScheme.primary.withAlpha(60),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.noItemsRecorded,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == products.length) {
                        // ── Total row ──
                        return _TotalRow(
                          total: transaction.totalAmount,
                          formatTL: formatTL,
                        );
                      }
                      return _ProductTile(
                        product: products[index],
                        index: index,
                        formatTL: formatTL,
                        isLast: index == products.length - 1,
                      );
                    },
                    childCount: products.length + 1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Header background widget ────────────────────────────────────────────────
class _HeaderBackground extends StatelessWidget {
  final ReceiptModel transaction;
  final IconData categoryIcon;
  final String Function(double) formatTL;

  const _HeaderBackground({
    required this.transaction,
    required this.categoryIcon,
    required this.formatTL,
  });

  String _localizeCategory(String category, AppLocalizations loc) {
    switch (category) {
      case 'Food': return loc.food;
      case 'Clothing': return loc.clothing;
      case 'Tech': return loc.tech;
      case 'Transportation': return loc.transportation;
      case 'Bills': return loc.bills;
      case 'Rent': return loc.rent;
      case 'Education': return loc.education;
      case 'Healthcare': return loc.healthcare;
      case 'Personal Care': return loc.personalCare;
      case 'Entertainment': return loc.entertainment;
      case 'Household / Furniture': return loc.householdFurniture;
      case 'Stationery': return loc.stationery;
      case 'Vacation / Travel': return loc.vacationTravel;
      case 'Taxes / Official Payments': return loc.taxesOfficialPayments;
      case 'Other': return loc.other;
      default: return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withAlpha(18),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withAlpha(12),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(categoryIcon,
                            color: primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.storeName,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: primary.withAlpha(20),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                _localizeCategory(transaction.category, loc),
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta info strip ──────────────────────────────────────────────────────────
class _MetaStrip extends StatelessWidget {
  final ReceiptModel transaction;

  const _MetaStrip({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final dateStr =
        DateFormat('d MMMM yyyy, HH:mm').format(transaction.date);

    IconData sourceIcon;
    String sourceLabel;
    switch (transaction.source) {
      case 'scan':
        sourceIcon = Icons.camera_alt_outlined;
        sourceLabel = loc.scanned;
        break;
      case 'pdf':
        sourceIcon = Icons.picture_as_pdf_outlined;
        sourceLabel = loc.pdf;
        break;
      default:
        sourceIcon = Icons.edit_outlined;
        sourceLabel = loc.manual;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
                .withAlpha(128), // 0.5 * 255 = 128
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(102), // 0.4 * 255 = 102
        ),
      ),
      child: Row(
        children: [
          _MetaChip(
            icon: Icons.calendar_today_outlined,
            label: dateStr,
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.outlineVariant,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          _MetaChip(
            icon: sourceIcon,
            label: sourceLabel,
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Product tile ─────────────────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final int index;
  final String Function(double) formatTL;
  final bool isLast;

  const _ProductTile({
    required this.product,
    required this.index,
    required this.formatTL,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Product name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Unit price
                    Text(
                      formatTL(product.price),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "×",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quantity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "×${product.quantity}",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Item total
          Text(
            formatTL(product.total),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Total row ─────────────────────────────────────────────────────────────────
class _TotalRow extends StatelessWidget {
  final double total;
  final String Function(double) formatTL;

  const _TotalRow({required this.total, required this.formatTL});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withAlpha(30),
            primary.withAlpha(18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withAlpha(50)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            loc.total,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            formatTL(total),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}