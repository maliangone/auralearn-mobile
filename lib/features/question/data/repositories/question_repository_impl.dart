import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/question_response.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/question_remote_data_source.dart';
import '../datasources/question_local_data_source.dart';
import '../models/question_request.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final QuestionRemoteDataSource remoteDataSource;
  final QuestionLocalDataSource localDataSource;

  QuestionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, QuestionResponse>> submitQuestion(
    String? content,
    List<Map<String, dynamic>>? images,
  ) async {
    try {
      // Convert images to image URLs if provided
      List<String>? imageUrls;
      if (images != null && images.isNotEmpty) {
        // For now, assume images are already processed or contain URLs
        imageUrls = images
            .map((img) => img['url'] as String? ?? '')
            .where((url) => url.isNotEmpty)
            .toList();
      }

      final request = QuestionRequest(
        content: content,
        imageUrls: imageUrls,
      );

      final questionResponse = await remoteDataSource.submitQuestion(request);
      
      // Cache the response
      await localDataSource.cacheQuestionResponse(questionResponse);
      
      return Right(questionResponse.toEntity());
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('Network connection failed'));
      } else if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Authentication required'));
      } else if (e.response?.statusCode == 400) {
        return Left(ValidationFailure(e.response?.data['message'] ?? 'Invalid request'));
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        return const Left(ServerFailure('Server error occurred'));
      }
      return Left(UnknownFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuestionResponse>>> getQuestionHistory() async {
    try {
      // Try to get from cache first
      final cachedQuestions = await localDataSource.getCachedQuestions();
      
      if (cachedQuestions.isNotEmpty) {
        return Right(cachedQuestions.map((q) => q.toEntity()).toList());
      }
      
      // If no cached data, this would typically fetch from remote
      // For now, return empty list as history is handled by history feature
      return const Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteQuestion(String questionId) async {
    try {
      await remoteDataSource.deleteQuestion(questionId);
      return const Right(null);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('Network connection failed'));
      } else if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Authentication required'));
      } else if (e.response?.statusCode == 404) {
        return const Left(ValidationFailure('Question not found'));
      }
      return Left(UnknownFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> uploadImages(
    List<MultipartFile> images,
  ) async {
    try {
      final response = await remoteDataSource.uploadImages(images);
      return Right(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure('Network connection failed'));
      } else if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Authentication required'));
      }
      return Left(UnknownFailure(e.message ?? 'Unknown error occurred'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
} 