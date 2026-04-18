import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction_model.dart';
import '../services/firestore_service.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final FirestoreService _service = FirestoreService();

  final List<String> _categories = [
    "Food", "Clothing", "Tech", "Transportation", "Bills",
    "Rent", "Education", "Healthcare", "Personal Care",
    "Entertainment", "Household / Furniture", "Stationery",
    "Vacation / Travel", "Taxes / Official Payments", "Other",
  ];

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Clothing': return Icons.checkroom;
      case 'Tech': return Icons.devices;
      case 'Transportation': return Icons.commute;
      case 'Bills': return Icons.receipt;
      case 'Rent': return Icons.home;
      case 'Education': return Icons.school;
      case 'Healthcare': return Icons.health_and_safety;
      case 'Personal Care': return Icons.spa;
      case 'Entertainment': return Icons.sports_esports;
      case 'Household / Furniture': return Icons.chair;
      case 'Stationery': return Icons.edit;
      case 'Vacation / Travel': return Icons.flight_takeoff;
      case 'Taxes / Official Payments': return Icons.account_balance;
      default: return Icons.shopping_bag;
    }
  }

  Color _frequencyColor(RecurringFrequency freq, ColorScheme cs) {
    switch (freq) {
      case RecurringFrequency.daily: return Colors.orange;
      case RecurringFrequency.weekly: return Colors.blue;
      case RecurringFrequency.monthly: return cs.primary;
      case RecurringFrequency.yearly: return Colors.purple;
    }
  }

  String _frequencyLabel(RecurringFrequency freq) {
    switch (freq) {
      case RecurringFrequency.daily: return 'Daily';
      case RecurringFrequency.weekly: return 'Weekly';
      case RecurringFrequency.monthly: return 'Monthly';
      case RecurringFrequency.yearly: return 'Yearly';
    }
  }

  bool _isDueSoon(RecurringModel r) {
    if (r.nextDueDate == null) return false;
    final diff = r.nextDueDate!.difference(DateTime.now()).inDays;
    return diff <= 3 && diff >= 0;
  }

  void _openForm({RecurringModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringFormSheet(
        categories: _categories,
        existing: existing,
        onSave: (model) async {
          if (existing == null) {
            await _service.addRecurring(model);
          } else {
            await _service.updateRecurring(model);
          }
        },
      ),
    );
  }

  void _confirmDelete(RecurringModel r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recurring'),
        content: Text('Remove "${r.storeName}" from recurring transactions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _service.deleteRecurring(r.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring'),
      ),
      body: StreamBuilder<List<RecurringModel>>(
        stream: _service.getRecurring(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64,
                      color: cs.primary.withAlpha(40)),
                  const SizedBox(height: 16),
                  Text('No recurring transactions',
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('Tap + to add subscriptions, rent, etc.',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          // Aktif üstte, paused altta
          final active = list.where((r) => r.status == RecurringStatus.active).toList();
          final paused = list.where((r) => r.status == RecurringStatus.paused).toList();
          final sorted = [...active, ...paused];

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: sorted.length + (paused.isNotEmpty ? 1 : 0),
            itemBuilder: (context, i) {
              // "Paused" başlığı
              if (paused.isNotEmpty && i == active.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Text('PAUSED',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                );
              }
              final idx = i > active.length ? i - 1 : i;
              final r = sorted[idx];
              return _RecurringCard(
                model: r,
                icon: _categoryIcon(r.category),
                freqColor: _frequencyColor(r.frequency, cs),
                freqLabel: _frequencyLabel(r.frequency),
                isDueSoon: _isDueSoon(r),
                onEdit: () => _openForm(existing: r),
                onDelete: () => _confirmDelete(r),
                onToggle: () => _service.toggleRecurringStatus(r),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD
// ─────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  final RecurringModel model;
  final IconData icon;
  final Color freqColor;
  final String freqLabel;
  final bool isDueSoon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _RecurringCard({
    required this.model,
    required this.icon,
    required this.freqColor,
    required this.freqLabel,
    required this.isDueSoon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPaused = model.status == RecurringStatus.paused;

    return Opacity(
      opacity: isPaused ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // İkon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: cs.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  // Bilgiler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(model.storeName,
                                style: theme.textTheme.titleMedium),
                            if (isDueSoon) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Due soon',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: Colors.orange)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: freqColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(freqLabel,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: freqColor)),
                            ),
                            const SizedBox(width: 8),
                            Text(model.category,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tutar
                  Text(
                    '₺${model.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Alt bar
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(80),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  if (model.nextDueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Next: ${DateFormat('d MMM yyyy').format(model.nextDueDate!)}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Pause / Resume
                  IconButton(
                    tooltip: isPaused ? 'Resume' : 'Pause',
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FORM SHEET
// ─────────────────────────────────────────────

class _RecurringFormSheet extends StatefulWidget {
  final List<String> categories;
  final RecurringModel? existing;
  final Future<void> Function(RecurringModel) onSave;

  const _RecurringFormSheet({
    required this.categories,
    required this.onSave,
    this.existing,
  });

  @override
  State<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends State<_RecurringFormSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _category = 'Bills';
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.storeName;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _noteCtrl.text = e.note;
      _category = e.category;
      _frequency = e.frequency;
      _startDate = e.startDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final e = widget.existing;

    final model = RecurringModel(
      id: e?.id ?? '',
      storeName: name,
      storeNameLower: name.toLowerCase(),
      amount: amount,
      category: _category,
      frequency: _frequency,
      status: e?.status ?? RecurringStatus.active,
      startDate: _startDate,
      nextDueDate: _startDate,
      note: _noteCtrl.text.trim(),
      createdAt: e?.createdAt ?? now,
    );

    await widget.onSave(model);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withAlpha(60),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.existing == null
                  ? 'New Recurring'
                  : 'Edit Recurring',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name / Store',
                prefixIcon: const Icon(Icons.store_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₺)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 20),

            // Frequency chips
            Text('Frequency', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: RecurringFrequency.values.map((f) {
                final selected = _frequency == f;
                return ChoiceChip(
                  label: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                  selected: selected,
                  onSelected: (_) => setState(() => _frequency = f),
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('d MMMM yyyy').format(_startDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Note
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.existing == null ? 'Add' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}