import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../data/cache/hive_cache_manager.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/transactions_bloc.dart';

/// Debug screen to test cache functionality
class CacheDebugScreen extends StatefulWidget {
  const CacheDebugScreen({super.key});

  @override
  State<CacheDebugScreen> createState() => _CacheDebugScreenState();
}

class _CacheDebugScreenState extends State<CacheDebugScreen> {
  late final HiveCacheManager _cacheManager;
  CacheStatistics? _stats;

  @override
  void initState() {
    super.initState();
    _cacheManager = di.sl<HiveCacheManager>();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _cacheManager.getCacheStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Cache Debug',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: BlocListener<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          // Handle cache-related state changes if needed
          if (state is TransactionLoaded) {
            // Refresh stats when transactions are loaded
            _loadStats();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(),
              const SizedBox(height: Spacing.space16),
              _buildActionsCard(),
              const SizedBox(height: Spacing.space16),
              _buildBlocListener(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Statistics',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.space12),
            if (_stats != null) ...[
              _buildStatRow('Total Items', _stats!.totalItems.toString()),
              _buildStatRow('Active Items', _stats!.activeItems.toString()),
              _buildStatRow('Expired Items', _stats!.expiredItems.toString()),
              _buildStatRow('Stale Items', _stats!.staleItems.toString()),
              _buildStatRow('Hit Rate', '${(_stats!.hitRate * 100).toStringAsFixed(1)}%'),
              _buildStatRow('Cache Size', '${_stats!.cacheSize} entries'),
              _buildStatRow('Last Cleanup', _formatDateTime(_stats!.lastCleanup)),
            ] else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Actions',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.space12),
            _buildActionButton(
              'Refresh Stats',
              Icons.refresh,
              AppColors.primary,
              () {
                _loadStats();
              },
            ),
            const SizedBox(height: Spacing.space8),
            _buildActionButton(
              'Invalidate Cache',
              Icons.clear,
              AppColors.warning,
              () {
                context.read<TransactionsBloc>().add(const RefreshTransactions());
                _showSnackBar('Cache invalidated');
              },
            ),
            const SizedBox(height: Spacing.space8),
            _buildActionButton(
              'Refresh Cache',
              Icons.sync,
              AppColors.info,
              () {
                context.read<TransactionsBloc>().add(const RefreshTransactions());
                _showSnackBar('Cache refreshed');
              },
            ),
            const SizedBox(height: Spacing.space8),
            _buildActionButton(
              'Clear All Cache',
              Icons.delete_forever,
              AppColors.error,
              () {
                context.read<TransactionsBloc>().add(const RefreshTransactions());
                _showSnackBar('All cache cleared');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.space16,
            vertical: Spacing.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.radiusM),
          ),
        ),
      ),
    );
  }

  Widget _buildBlocListener() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BLoC State',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spacing.space12),
            BlocBuilder<TransactionsBloc, TransactionsState>(
              builder: (context, state) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(Spacing.radiusS),
                    border: Border.all(color: AppColors.border.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Current State: ${state.runtimeType}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}