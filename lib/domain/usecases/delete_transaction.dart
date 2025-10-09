import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

/// Parameters for deleting a transaction
class DeleteTransactionParams {
  final String id;

  const DeleteTransactionParams(this.id);
}

/// Use case to delete a transaction
class DeleteTransaction implements UseCase<void, String> {
  final TransactionRepository repository;

  DeleteTransaction(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteTransaction(params);
  }
}