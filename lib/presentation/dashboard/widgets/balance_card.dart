import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import 'animated_counter.dart';

/// Balance card with glassmorphism effect and flip animation
class BalanceCard extends StatefulWidget {
  final double balance;
  final double monthlyIncome;
  final double monthlyExpense;
  final bool initiallyVisible;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.initiallyVisible = true,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with SingleTickerProviderStateMixin {
  late bool _isVisible;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.initiallyVisible;
    _flipController = AnimationController(
      duration: AppConstants.flipAnimation,
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _flipController.reverse();
      } else {
        _flipController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * 3.14159; // π radians
        final isUnder = _flipAnimation.value > 0.5;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isUnder
              ? Transform(
                  transform: Matrix4.identity()..rotateY(3.14159),
                  alignment: Alignment.center,
                  child: _buildHiddenCard(),
                )
              : _buildVisibleCard(),
        );
      },
    );
  }

  Widget _buildVisibleCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Spacing.radiusL),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.space24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Spacing.radiusL),
            // Multi-layer glassmorphism background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.primaryLight.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.25),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
            // Glass border effect
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.0,
            ),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: const Offset(0, 15),
                spreadRadius: -5,
              ),
              // Secondary glow
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 8),
                spreadRadius: -10,
              ),
              // Inner highlight (top)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -1),
                spreadRadius: -8,
              ),
            ],
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with visibility toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: Icon(
                  _isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _toggleVisibility,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: Spacing.space12),

          // Balance amount
          AnimatedCounter(
            value: widget.balance,
            prefix: '৳',
            decimalPlaces: 0, // Taka typically doesn't use decimal places
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: Spacing.space24),

          // Income and Expense row
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn(
                  icon: Icons.arrow_downward,
                  label: 'Income',
                  amount: widget.monthlyIncome,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: Spacing.space16),
              Expanded(
                child: _buildInfoColumn(
                  icon: Icons.arrow_upward,
                  label: 'Expense',
                  amount: widget.monthlyExpense,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildHiddenCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Spacing.radiusL),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.space24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Spacing.radiusL),
            // Darker glassmorphism for hidden state
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.textSecondary.withValues(alpha: 0.25),
                AppColors.textTertiary.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
            // Glass border effect
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, 15),
                spreadRadius: -5,
              ),
              // Subtle glow
              BoxShadow(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 8),
                spreadRadius: -10,
              ),
            ],
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance Hidden',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: _toggleVisibility,
              ),
            ],
          ),
          const SizedBox(height: Spacing.space16),
          Text(
            '••••••••',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.space12),
      decoration: BoxDecoration(
        // Enhanced glassmorphism for info columns
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(Spacing.radiusM),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: Spacing.iconS),
              const SizedBox(width: Spacing.space4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.space4),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
