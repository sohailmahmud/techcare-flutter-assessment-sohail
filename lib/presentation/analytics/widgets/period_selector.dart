import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../bloc/analytics_bloc.dart';
import '../../../domain/entities/analytics.dart';

class PeriodSelector extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final DateRange dateRange;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final ValueChanged<DateRange>? onCustomRangeChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.dateRange,
    required this.onPeriodChanged,
    this.onCustomRangeChanged,
  });

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late TimePeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedPeriod;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(PeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPeriod != oldWidget.selectedPeriod) {
      setState(() {
        _selectedPeriod = widget.selectedPeriod;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 20),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(Spacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: Spacing.space8),
                Text(
                  'Time Period',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _buildDateRangeDisplay(),
              ],
            ),
            const SizedBox(height: Spacing.space16),
            _buildPeriodChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.space12,
        vertical: Spacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatDateRange(widget.dateRange),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return Wrap(
      spacing: Spacing.space8,
      runSpacing: Spacing.space8,
      children: TimePeriod.values.map((period) {
        final isSelected = _selectedPeriod == period;
        return _buildPeriodChip(period, isSelected);
      }).toList(),
    );
  }

  Widget _buildPeriodChip(TimePeriod period, bool isSelected) {
    return AnimatedContainer(
      key: ValueKey('period_chip_${period.name}'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onPeriodTap(period),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.space16,
              vertical: Spacing.space8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (period == TimePeriod.custom)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      key: ValueKey('calendar_icon_$isSelected'),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                if (period == TimePeriod.custom) const SizedBox(width: Spacing.space4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(period.displayName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPeriodTap(TimePeriod period) {
    if (period == TimePeriod.custom) {
      _showCustomDatePicker();
    } else {
      setState(() {
        _selectedPeriod = period;
      });
      widget.onPeriodChanged(period);
      context.read<AnalyticsBloc>().add(ChangePeriod(period));
    }
  }

  Future<void> _showCustomDatePicker() async {
    final now = DateTime.now();
    final startDate = widget.dateRange.startDate.isBefore(DateTime(2020)) 
        ? DateTime(2020) 
        : (widget.dateRange.startDate.isAfter(now) ? now : widget.dateRange.startDate);
    final endDate = widget.dateRange.endDate.isAfter(now) 
        ? now 
        : widget.dateRange.endDate;
    
    // Ensure startDate is not after endDate
    final safeStartDate = startDate.isAfter(endDate) ? endDate : startDate;
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: safeStartDate,
        end: endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final customRange = DateRange(
        startDate: picked.start,
        endDate: picked.end,
      );
      
      setState(() {
        _selectedPeriod = TimePeriod.custom;
      });
      
      widget.onPeriodChanged(TimePeriod.custom);
      widget.onCustomRangeChanged?.call(customRange);
      
      if (mounted) {
        context.read<AnalyticsBloc>().add(
          ChangePeriod(TimePeriod.custom, customRange: customRange),
        );
      }
    }
  }

  String _formatDateRange(DateRange range) {
    final start = DateFormatter.formatDisplay(range.startDate);
    final end = DateFormatter.formatDisplay(range.endDate);
    
    if (range.dayCount == 1) {
      return start;
    }
    
    return '$start - $end';
  }
}