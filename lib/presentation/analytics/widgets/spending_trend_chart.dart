import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/analytics_models.dart';

class SpendingTrendChart extends StatefulWidget {
  final List<TrendDataPoint> trendData;
  final bool isLoading;

  const SpendingTrendChart({
    super.key,
    required this.trendData,
    this.isLoading = false,
  });

  @override
  State<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<SpendingTrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _startAnimation();
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void didUpdateWidget(SpendingTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trendData != widget.trendData) {
      _animationController.reset();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: Spacing.space16),
          _buildLegend(),
          const SizedBox(height: Spacing.space16),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 180,
                maxHeight: 220,
              ),
              child: widget.isLoading
                  ? _buildLoadingState()
                  : _buildChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: Spacing.space12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trend',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '6-month overview',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: AppColors.income,
          label: 'Income',
          icon: Icons.arrow_upward_rounded,
        ),
        const SizedBox(width: Spacing.space24),
        _buildLegendItem(
          color: AppColors.expense,
          label: 'Expenses',
          icon: Icons.arrow_downward_rounded,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacing.space8),
        Icon(icon, color: color, size: 16),
        const SizedBox(width: Spacing.space4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: Spacing.space16),
          Text(
            'Loading trend data...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (widget.trendData.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          _buildLineChartData(),
          duration: const Duration(milliseconds: 250),
          curve: Curves.linear,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: Spacing.space16),
          Text(
            'No trend data available',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.space8),
          Text(
            'Add some transactions to see your spending trends',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final maxY = _getMaxY();
    
    return LineChartData(
      gridData: _buildGridData(),
      titlesData: _buildTitlesData(),
      borderData: _buildBorderData(),
      minX: 0,
      maxX: (widget.trendData.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        _buildIncomeLineBarData(),
        _buildExpenseLineBarData(),
      ],
      lineTouchData: _buildTouchData(),
      clipData: const FlClipData.all(),
    );
  }

  FlGridData _buildGridData() {
    final maxY = _getMaxY();
    final interval = maxY > 0 ? maxY / 4 : 1.0; // Ensure interval is never zero
    
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppColors.border.withOpacity(0.5),
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: _buildBottomTitleWidgets,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: _getMaxY() > 0 ? _getMaxY() / 4 : 1.0, // Ensure interval is never zero
          getTitlesWidget: _buildLeftTitleWidgets,
          reservedSize: 50,
        ),
      ),
    );
  }

  Widget _buildBottomTitleWidgets(double value, TitleMeta meta) {
    if (value < 0 || value >= widget.trendData.length) {
      return Container();
    }

    final dataPoint = widget.trendData[value.toInt()];
    final monthName = _getMonthAbbreviation(dataPoint.date.month);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        monthName,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLeftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        CurrencyFormatter.formatCompact(value),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: AppColors.border, width: 1),
        left: BorderSide(color: AppColors.border, width: 1),
      ),
    );
  }

  LineChartBarData _buildIncomeLineBarData() {
    return LineChartBarData(
      spots: _buildSpots(isIncome: true),
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          AppColors.income.withOpacity(0.8),
          AppColors.income,
        ],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: AppColors.income,
          strokeWidth: 2,
          strokeColor: AppColors.surface,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            AppColors.income.withOpacity(0.2 * _animation.value),
            AppColors.income.withOpacity(0.05 * _animation.value),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  LineChartBarData _buildExpenseLineBarData() {
    return LineChartBarData(
      spots: _buildSpots(isIncome: false),
      isCurved: true,
      gradient: LinearGradient(
        colors: [
          AppColors.expense.withOpacity(0.8),
          AppColors.expense,
        ],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: AppColors.expense,
          strokeWidth: 2,
          strokeColor: AppColors.surface,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            AppColors.expense.withOpacity(0.2 * _animation.value),
            AppColors.expense.withOpacity(0.05 * _animation.value),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots({required bool isIncome}) {
    return widget.trendData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final dataPoint = entry.value;
      final value = isIncome ? dataPoint.income : dataPoint.expenses;
      return FlSpot(index, value * _animation.value);
    }).toList();
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      enabled: true,
      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
        // Handle touch interactions for future enhancements
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => AppColors.textPrimary.withOpacity(0.8),
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        tooltipMargin: 8,
        getTooltipItems: _buildTooltipItems,
      ),
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((spotIndex) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: barData.gradient?.colors.first ?? AppColors.primary,
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
            FlDotData(
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 6,
                color: barData.gradient?.colors.first ?? AppColors.primary,
                strokeWidth: 3,
                strokeColor: AppColors.surface,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  List<LineTooltipItem> _buildTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((LineBarSpot touchedSpot) {
      const textStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );
      
      final dataPoint = widget.trendData[touchedSpot.spotIndex];
      final monthName = _getMonthName(dataPoint.date.month);
      
      if (touchedSpot.barIndex == 0) {
        // Income line
        return LineTooltipItem(
          '$monthName\nIncome: ${CurrencyFormatter.formatCompact(touchedSpot.y)}',
          textStyle,
        );
      } else {
        // Expense line
        return LineTooltipItem(
          '$monthName\nExpenses: ${CurrencyFormatter.formatCompact(touchedSpot.y)}',
          textStyle,
        );
      }
    }).toList();
  }

  double _getMaxY() {
    if (widget.trendData.isEmpty) return 100;
    
    double maxValue = 0;
    for (final dataPoint in widget.trendData) {
      maxValue = [maxValue, dataPoint.income, dataPoint.expenses].reduce((a, b) => a > b ? a : b);
    }
    
    // Ensure minimum value and add 20% padding to the top
    final result = maxValue * 1.2;
    return result > 0 ? result : 100; // Return minimum 100 if result is 0 or negative
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}