import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_data_source.dart';
import '../datasources/history_local_data_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remoteDataSource;
  final HistoryLocalDataSource localDataSource;

  HistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<HistoryItem>>> getHistory({
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    try {
      final response = await remoteDataSource.getHistory(
        page: page,
        limit: limit,
        subject: subject,
      );
      
      // Cache the first page
      if (page == 1) {
        await localDataSource.cacheHistory(response.items);
      }
      
      return Right(response.items.map((item) => item.toEntity()).toList());
    } on DioError catch (e) {
      // Try to get cached data on network error
      if (e.type == DioErrorType.connectTimeout ||
          e.type == DioErrorType.receiveTimeout ||
          e.type == DioErrorType.sendTimeout) {
        
        if (page == 1) {
          final cachedItems = await localDataSource.getCachedHistory();
          if (cachedItems.isNotEmpty) {
            return Right(cachedItems.map((item) => item.toEntity()).toList());
          }
        }
        
        return const Left(NetworkFailure('Network connection failed'));
      } else if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Authentication required'));
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        return const Left(ServerFailure('Server error occurred'));
      }
      return Left(UnknownFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHistoryItem(String itemId) async {
    try {
      await remoteDataSource.deleteHistoryItem(itemId);
      
      // Remove from cache
      await localDataSource.removeCachedHistoryItem(itemId);
      
      return const Right(null);
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectTimeout ||
          e.type == DioErrorType.receiveTimeout ||
          e.type == DioErrorType.sendTimeout) {
        return const Left(NetworkFailure('Network connection failed'));
      } else if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Authentication required'));
      } else if (e.response?.statusCode == 404) {
        return const Left(ValidationFailure('History item not found'));
      }
      return Left(UnknownFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async {
    try {
      await remoteDataSource.clearHistory();
      
      // Clear cache
      await localDataSource.clearCache();
      
      return const Right(null);
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectTimeout ||
          e.type == DioErrorType.receiveTimeout ||
          e.type == DioErrorType.sendTimeout) {
        return const Left(NetworkFailure('Network connection failed'));
      } else if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Authentication required'));
      }
      return Left(UnknownFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HistoryItem?>> getHistoryItem(String itemId) async {
    try {
      // First try to get from cache
      final cachedItem = await localDataSource.getCachedHistoryItem(itemId);
      if (cachedItem != null) {
        return Right(cachedItem.toEntity());
      }
      
      // If not in cache, could fetch from remote (not implemented in current API)
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
} 