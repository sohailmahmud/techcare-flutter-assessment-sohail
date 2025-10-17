import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/transaction_filter.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/repositories/category_repository.dart';

class FilterBottomSheet extends StatefulWidget {
  final TransactionFilter currentFilter;
  final Function(TransactionFilter) onApplyFilters;
  final VoidCallback onClearFilters;
  final CategoryRepository categoryRepository;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilters,
    required this.onClearFilters,
    required this.categoryRepository,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with TickerProviderStateMixin {
  late TransactionFilter _workingFilter;
  late TabController _tabController;

  // Available categories loaded from repository
  List<Category> _availableCategories = [];

  final List<String> _filterTabs = ['Date', 'Category', 'Amount', 'Type'];

  @override
  void initState() {
    super.initState();
    _workingFilter = widget.currentFilter;
    _tabController = TabController(length: 4, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await AppCategories.getAllCategories();
      setState(() {
        _availableCategories = categories;
      });
    } catch (e) {
      setState(() {
        _availableCategories = [];
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateFilter(TransactionFilter newFilter) {
    setState(() {
      _workingFilter = newFilter;
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_workingFilter);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _workingFilter = const TransactionFilter();
    });
    widget.onClearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      height: mediaQuery.size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Spacing.space12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(Spacing.space20),
            child: Row(
              children: [
                Text(
                  'Filter Transactions',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_workingFilter.hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Spacing.space20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary,
              ),
              dividerColor: Colors.transparent,
              labelColor: AppColors.background,
              unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(153),
              labelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              indicatorPadding: const EdgeInsets.symmetric(vertical: Spacing.space4),
              tabs: _filterTabs
                  .map((tab) {
                    return Tab(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: Spacing.space16,
                          right: Spacing.space16,
                        ),
                        child: Text(tab),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDateFilter(),
                _buildCategoryFilter(),
                _buildAmountFilter(),
                _buildTypeFilter(),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.only(
              left: Spacing.space20,
              right: Spacing.space20,
              top: Spacing.space16,
              bottom: Spacing.space16 + bottomPadding,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Spacing.space16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _workingFilter.hasActiveFilters
                          ? 'Apply (${_workingFilter.activeFilterCount})'
                          : 'Apply',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date Range',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: Spacing.space16),

          // Preset options
          ...DateRangePreset.values.map((preset) {
            final isSelected = _workingFilter.datePreset == preset;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.space8),
              child: GestureDetector(
                onTap: () {
                  final dateRange = preset.getDateRange();
                  _updateFilter(_workingFilter.copyWith(
                    datePreset: preset,
                    dateRange: dateRange,
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.all(Spacing.space16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withAlpha(25)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                      ),
                      const SizedBox(width: Spacing.space12),
                      Text(
                        preset.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Custom date range
          if (_workingFilter.datePreset == DateRangePreset.custom) ...[
            const SizedBox(height: Spacing.space16),
            Text(
              'Custom Range',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: Spacing.space12),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    'From',
                    _workingFilter.dateRange?.start,
                    (date) {
                      if (date != null && _workingFilter.dateRange != null) {
                        _updateFilter(_workingFilter.copyWith(
                          dateRange:
                              _workingFilter.dateRange!.copyWith(start: date),
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: Spacing.space12),
                Expanded(
                  child: _buildDateButton(
                    'To',
                    _workingFilter.dateRange?.end,
                    (date) {
                      if (date != null && _workingFilter.dateRange != null) {
                        _updateFilter(_workingFilter.copyWith(
                          dateRange:
                              _workingFilter.dateRange!.copyWith(end: date),
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateButton(
      String label, DateTime? date, Function(DateTime?) onDateSelected) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onDateSelected(selectedDate);
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_workingFilter.selectedCategories.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _updateFilter(
                        _workingFilter.copyWith(selectedCategories: []));
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.space16),

          // Select all/none buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _updateFilter(_workingFilter.copyWith(
                      selectedCategories: _availableCategories.map((c) => c.id).toList(),
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                  child: const Text('Select All'),
                ),
              ),
              const SizedBox(width: Spacing.space12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _updateFilter(
                        _workingFilter.copyWith(selectedCategories: []));
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                  child: const Text('Select None'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.space16),

          // Category chips
          Wrap(
            spacing: Spacing.space8,
            runSpacing: Spacing.space8,
            children: _availableCategories.map((category) {
              final isSelected =
                  _workingFilter.selectedCategories.contains(category.id);
              return GestureDetector(
                onTap: () {
                  final updatedCategories =
                      List<String>.from(_workingFilter.selectedCategories);
                  if (isSelected) {
                    updatedCategories.remove(category.id);
                  } else {
                    updatedCategories.add(category.id);
                  }
                  _updateFilter(_workingFilter.copyWith(
                      selectedCategories: updatedCategories));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.space16,
                    vertical: Spacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withAlpha(20)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountFilter() {
    final minAmount = _workingFilter.amountRange?.min ?? 0.0;
    final maxAmount = _workingFilter.amountRange?.max ?? 100000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Amount Range',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (_workingFilter.amountRange != null)
                TextButton(
                  onPressed: () {
                    // amount range to default
                    _updateFilter(_workingFilter.copyWith(amountRange: const AmountRange(min: 0, max: 100000)));
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.space24),

          // Amount display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(minAmount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                CurrencyFormatter.format(maxAmount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.space16),

          // Range slider
          RangeSlider(
            values: RangeValues(minAmount, maxAmount),
            min: 0,
            max: 100000,
            divisions: 100,
            onChanged: (RangeValues values) {
              _updateFilter(_workingFilter.copyWith(
                amountRange: AmountRange(
                  min: values.start,
                  max: values.end,
                ),
              ));
            },
          ),
          const SizedBox(height: Spacing.space24),

          // Preset amount ranges
          Text(
            'Quick Ranges',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: Spacing.space12),

          ...[
            {'label': 'Under ৳1,000', 'min': 0.0, 'max': 1000.0},
            {'label': '৳1,000 - ৳5,000', 'min': 1000.0, 'max': 5000.0},
            {'label': '৳5,000 - ৳20,000', 'min': 5000.0, 'max': 20000.0},
            {'label': 'Above ৳20,000', 'min': 20000.0, 'max': 100000.0},
          ].map((preset) {
            final isSelected =
                _workingFilter.amountRange?.min == preset['min'] &&
                    _workingFilter.amountRange?.max == preset['max'];
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.space8),
              child: GestureDetector(
                onTap: () {
                  _updateFilter(_workingFilter.copyWith(
                    amountRange: AmountRange(
                      min: preset['min'] as double,
                      max: preset['max'] as double,
                    ),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.all(Spacing.space16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withAlpha(25)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                      ),
                      const SizedBox(width: Spacing.space12),
                      Text(
                        preset['label'] as String,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: Spacing.space16),
          ...TransactionType.values.map((type) {
            final isSelected = _workingFilter.transactionType == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.space8),
              child: GestureDetector(
                onTap: () {
                  _updateFilter(_workingFilter.copyWith(transactionType: type));
                },
                child: Container(
                  padding: const EdgeInsets.all(Spacing.space16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withAlpha(25)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                      ),
                      const SizedBox(width: Spacing.space12),
                      Icon(
                        type == TransactionType.income
                            ? Icons.trending_up_rounded
                            : type == TransactionType.expense
                                ? Icons.trending_down_rounded
                                : Icons.swap_horiz_rounded,
                        color: type == TransactionType.income
                            ? Colors.green
                            : type == TransactionType.expense
                                ? Colors.red
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(153),
                      ),
                      const SizedBox(width: Spacing.space12),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Function to show the filter bottom sheet
void showFilterBottomSheet({
  required BuildContext context,
  required TransactionFilter currentFilter,
  required Function(TransactionFilter) onApplyFilters,
  required VoidCallback onClearFilters,
  required CategoryRepository categoryRepository,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(
      currentFilter: currentFilter,
      onApplyFilters: onApplyFilters,
      onClearFilters: onClearFilters,
      categoryRepository: categoryRepository,
    ),
  );
}
