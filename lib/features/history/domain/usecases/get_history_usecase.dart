import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository repository;

  GetHistoryUseCase(this.repository);

  Future<Either<Failure, List<HistoryItem>>> call(GetHistoryParams params) async {
    return await repository.getHistory(
      page: params.page,
      limit: params.limit,
      subject: params.subject,
    );
  }
}

class GetHistoryParams {
  final int page;
  final int limit;
  final String? subject;

  GetHistoryParams({
    this.page = 1,
    this.limit = 20,
    this.subject,
  });
} 