import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/history_item.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<HistoryItem>>> getHistory({
    int page = 1,
    int limit = 20,
    String? subject,
  });
  
  Future<Either<Failure, void>> deleteHistoryItem(String itemId);
  
  Future<Either<Failure, void>> clearHistory();
  
  Future<Either<Failure, HistoryItem?>> getHistoryItem(String itemId);
} 