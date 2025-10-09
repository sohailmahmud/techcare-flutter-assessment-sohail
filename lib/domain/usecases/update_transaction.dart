import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Use case to update an existing transaction
class UpdateTransaction implements UseCase<Transaction, Transaction> {
  final TransactionRepository repository;

  UpdateTransaction(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(Transaction params) async {
    return await repository.updateTransaction(params);
  }
}
