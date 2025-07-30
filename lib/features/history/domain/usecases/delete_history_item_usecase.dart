import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/history_repository.dart';

class DeleteHistoryItemUseCase {
  final HistoryRepository repository;

  DeleteHistoryItemUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteHistoryItemParams params) async {
    return await repository.deleteHistoryItem(params.itemId);
  }
}

class DeleteHistoryItemParams {
  final String itemId;

  DeleteHistoryItemParams({required this.itemId});
} 