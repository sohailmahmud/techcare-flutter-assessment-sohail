import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/transaction_form_bloc.dart';
import '../models/transaction_form_models.dart' hide TransactionFormState;
import '../widgets/amount_input_field.dart';
import '../widgets/transaction_type_selector.dart';
import '../widgets/category_selector.dart';
import '../widgets/transaction_details_form.dart';

class AddEditTransactionScreen extends StatefulWidget {
  static const routeName = '/add-edit-transaction';
  final Transaction? transaction; // null for add, non-null for edit

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _heroScaleAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Hero animation controller
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Content animation controller
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Hero scale animation
    _heroScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Content slide animation
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Content fade animation
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    // Start animations
    _heroAnimationController.forward();
    _contentAnimationController.forward();

    // Auto-focus amount field for new transactions
    if (widget.transaction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    _scrollController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  bool get isEditMode => widget.transaction != null;

  @override
  Widget build(BuildContext context) {
    // Get route arguments for transaction type if provided
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final transactionType = routeArgs?['type'] as TransactionType?;

    return BlocProvider(
      create: (context) {
        final bloc = di.sl<TransactionFormBloc>();
        bloc.add(InitializeForm(transaction: widget.transaction));
        if (transactionType != null) {
          bloc.add(TransactionTypeChanged(transactionType));
        }
        return bloc;
      },
      child: BlocListener<TransactionFormBloc, TransactionFormBlocState>(
        listener: (context, state) {
          if (state is TransactionFormReady && state.isSuccessful) {
            _onFormSubmissionSuccess();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _contentFadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _contentFadeAnimation,
                        child: SlideTransition(
                          position: _contentSlideAnimation,
                          child: _buildContent(),
                        ),
                      );
                    },
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(Spacing.space16),
      child: Row(
        children: [
          // Back Button
          AnimatedBuilder(
            animation: _heroScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _heroScaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Spacing.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _onBackPressed,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: Spacing.space16),

          // Title
          Expanded(
            child: AnimatedBuilder(
              animation: _heroScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _heroScaleAnimation.value,
                  child: Text(
                    isEditMode ? 'Edit Transaction' : 'Add Transaction',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<TransactionFormBloc, TransactionFormBlocState>(
      builder: (context, state) {
        if (state is! TransactionFormReady) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(Spacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              AmountInputField(
                value: state.formData.amount,
                onChanged: (value) => context
                    .read<TransactionFormBloc>()
                    .add(AmountChanged(value)),
                errorText:
                    state.getFieldError(TransactionFormError.amountRequired),
                autofocus: !isEditMode,
                focusNode: _amountFocusNode,
              ),
              const SizedBox(height: Spacing.space24),

              // Transaction Type Selector
              TransactionTypeSelector(
                selectedType: state.formData.type,
                onChanged: (type) => context
                    .read<TransactionFormBloc>()
                    .add(TransactionTypeChanged(type)),
              ),
              const SizedBox(height: Spacing.space24),

              // Category Selector
              CategorySelector(
                categories: state.formData.availableCategories,
                selectedCategory: state.formData.selectedCategory,
                onCategorySelected: (category) => context
                    .read<TransactionFormBloc>()
                    .add(CategorySelected(category)),
                errorText:
                    state.getFieldError(TransactionFormError.categoryRequired),
              ),
              const SizedBox(height: Spacing.space24),

              // Transaction Details
              TransactionDetailsForm(
                title: state.formData.title,
                notes: state.formData.notes,
                selectedDate: state.formData.date,
                selectedTime: state.formData.time,
                onTitleChanged: (title) => context
                    .read<TransactionFormBloc>()
                    .add(TitleChanged(title)),
                onNotesChanged: (notes) => context
                    .read<TransactionFormBloc>()
                    .add(NotesChanged(notes)),
                onDateChanged: (date) =>
                    context.read<TransactionFormBloc>().add(DateChanged(date)),
                onTimeChanged: (time) =>
                    context.read<TransactionFormBloc>().add(TimeChanged(time)),
                titleError:
                    state.getFieldError(TransactionFormError.titleRequired) ??
                        state.getFieldError(TransactionFormError.titleTooLong),
                notesError:
                    state.getFieldError(TransactionFormError.notesTooLong),
                dateError:
                    state.getFieldError(TransactionFormError.dateInFuture),
              ),

              // Bottom spacing for action buttons
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<TransactionFormBloc, TransactionFormBlocState>(
      builder: (context, state) {
        if (state is! TransactionFormReady) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(Spacing.space16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isSubmitting ? null : _onBackPressed,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: Spacing.space16),
                    side: const BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusL),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.space16),

              // Save Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.isSubmitting || !state.isValid
                      ? null
                      : _onSavePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: Spacing.space16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusL),
                    ),
                    elevation: 0,
                  ),
                  child: state.isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: Spacing.space8),
                            Text(
                              'Saving...',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isEditMode
                              ? 'Update Transaction'
                              : 'Save Transaction',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onBackPressed() {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Animate out and then navigate back
    _heroAnimationController.reverse();
    _contentAnimationController.reverse().then((_) {
      if (mounted) {
        // Check if we can pop (there's a previous route)
        if (context.canPop()) {
          context.pop();
        } else {
          // If we can't pop, determine the appropriate route based on context
          // This handles deep links or direct navigation to transaction form
          _navigateToAppropriateRoute();
        }
      }
    });
  }

  void _navigateToAppropriateRoute() {
    // Get any extra data passed to this route
    final routeState = GoRouterState.of(context);
    final extra = routeState.extra as Map<String, dynamic>?;

    // Check if theres a source page indication in extra data
    final sourcePage = extra?['sourcePage'] as String?;

    if (sourcePage == 'transactions') {
      context.go(AppRoutes.transactions);
    } else if (sourcePage == 'dashboard') {
      context.go(AppRoutes.dashboard);
    } else {
      // Default fallback - go to dashboard
      context.go(AppRoutes.dashboard);
    }
  }

  void _onSavePressed() {
    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Validate and submit form
    context.read<TransactionFormBloc>().add(const ValidateForm());
    context.read<TransactionFormBloc>().add(const SubmitForm());
  }

  void _onFormSubmissionSuccess() {
    // Add haptic feedback
    HapticFeedback.heavyImpact();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditMode
              ? 'Transaction updated successfully!'
              : 'Transaction added successfully!',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusM),
        ),
      ),
    );

    // Navigate back with a slight delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _onBackPressed();
      }
    });
  }
}
