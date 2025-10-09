import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Use case to get transactions
class GetTransactions
    implements UseCase<PaginatedResponse<Transaction>, TransactionQuery> {
  final TransactionRepository repository;

  GetTransactions(this.repository);

  @override
  Future<Either<Failure, PaginatedResponse<Transaction>>> call(
      TransactionQuery params) async {
    return await repository.getTransactions(params);
  }
}
