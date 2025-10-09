import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';

/// Custom amount input field with BDT currency prefix and formatting
class AmountInputField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;

  const AmountInputField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = widget.focusNode ?? FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AmountInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Spacing.radiusL),
                  border: Border.all(
                    color: hasError
                        ? AppColors.error
                        : _isFocused
                            ? AppColors.primary
                            : AppColors.border,
                    width: hasError ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    if (_isFocused || hasError)
                      BoxShadow(
                        color: (hasError ? AppColors.error : AppColors.primary)
                            .withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.space20),
                  child: Row(
                    children: [
                      // Currency Symbol
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.space12,
                          vertical: Spacing.space8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Spacing.radiusM),
                        ),
                        child: Text(
                          '৳',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.space16),
                      
                      // Amount Input
                      Expanded(
                        child: TextFormField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: widget.autofocus,
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: AppTypography.displaySmall.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.,]'),
                            ),
                            _AmountInputFormatter(),
                          ],
                          onChanged: widget.onChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Error Message
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
                  widget.errorText!,
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
}

/// Custom input formatter for amount field
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-digit characters except decimal point and comma
    String newText = newValue.text.replaceAll(RegExp(r'[^\d.,]'), '');
    
    // Handle multiple decimal points
    final parts = newText.split('.');
    if (parts.length > 2) {
      newText = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    
    // Limit decimal places to 2
    if (newText.contains('.')) {
      final splitText = newText.split('.');
      if (splitText.length > 1 && splitText[1].length > 2) {
        newText = '${splitText[0]}.${splitText[1].substring(0, 2)}';
      }
    }
    
    // Apply thousand separators
    newText = _applyThousandSeparators(newText);
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
  
  String _applyThousandSeparators(String text) {
    if (text.isEmpty) return text;
    
    // Split by decimal point
    final parts = text.split('.');
    String integerPart = parts[0].replaceAll(',', '');
    
    // Add commas to integer part
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(
      formatter,
      (Match m) => '${m[1]},',
    );
    
    // Reconstruct with decimal part if exists
    if (parts.length > 1) {
      return '$integerPart.${parts[1]}';
    } else {
      return integerPart;
    }
  }
}