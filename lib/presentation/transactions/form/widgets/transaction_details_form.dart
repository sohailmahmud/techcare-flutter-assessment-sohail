import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';

/// Transaction details form with title, description, date, and time inputs
class TransactionDetailsForm extends StatelessWidget {
  final String title;
  final String? notes;
  final DateTime selectedDate;
  final DateTime selectedTime;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTime> onTimeChanged;
  final String? titleError;
  final String? notesError;
  final String? dateError;

  const TransactionDetailsForm({
    super.key,
    required this.title,
    required this.notes,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTitleChanged,
    required this.onNotesChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.titleError,
    this.notesError,
    this.dateError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Input
        _buildTitleInput(),
        const SizedBox(height: Spacing.space20),
        
        // Date and Time Picker
        _buildDateTimePicker(context),
        const SizedBox(height: Spacing.space20),
        
        // Notes Input
        _buildNotesInput(),
      ],
    );
  }

  Widget _buildTitleInput() {
    final hasError = titleError != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Title',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.space8),
        TextFormField(
          initialValue: title,
          onChanged: onTitleChanged,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Enter transaction title',
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(Spacing.space16),
            counterText: '${title.length}/100',
            counterStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Spacing.space4),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: Spacing.space4),
              Expanded(
                child: Text(
                  titleError!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    final hasError = dateError != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.space8),
        Row(
          children: [
            // Date Picker
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _showDatePicker(context),
                child: Container(
                  padding: const EdgeInsets.all(Spacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Spacing.radiusL),
                    border: Border.all(
                      color: hasError ? AppColors.error : AppColors.border,
                      width: hasError ? 2.0 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: hasError ? AppColors.error : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.space8),
                      Expanded(
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.space12),
            
            // Time Picker
            Expanded(
              child: GestureDetector(
                onTap: () => _showTimePicker(context),
                child: Container(
                  padding: const EdgeInsets.all(Spacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Spacing.radiusL),
                    border: Border.all(
                      color: hasError ? AppColors.error : AppColors.border,
                      width: hasError ? 2.0 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: hasError ? AppColors.error : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.space8),
                      Expanded(
                        child: Text(
                          DateFormat('HH:mm').format(selectedTime),
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: Spacing.space8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: Spacing.space4),
              Expanded(
                child: Text(
                  dateError!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNotesInput() {
    final hasError = notesError != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.space8),
        TextFormField(
          initialValue: notes ?? '',
          onChanged: onNotesChanged,
          maxLength: 500,
          maxLines: 4,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'Add additional notes (optional)',
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacing.radiusL),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(Spacing.space16),
            counterText: '${(notes ?? '').length}/500',
            counterStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Spacing.space4),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: Spacing.space4),
              Expanded(
                child: Text(
                  notesError!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime = DateTime(
        selectedTime.year,
        selectedTime.month,
        selectedTime.day,
        picked.hour,
        picked.minute,
      );
      onTimeChanged(newTime);
    }
  }
}