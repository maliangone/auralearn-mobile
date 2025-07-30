import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../domain/repositories/subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import '../../../../core/error/failures.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../datasources/subscription_local_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;
  final SubscriptionLocalDataSource localDataSource;

  SubscriptionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSubscriptionStatus() async {
    try {
      final response = await remoteDataSource.getSubscriptionStatus();
      
      // Cache subscription data locally
      await localDataSource.cacheSubscriptionData(response);
      
      return Right({
        'subscription': _subscriptionModelToEntity(response.subscription),
        'usageStats': response.usageStats,
      });
    } on DioError catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Subscription>> purchaseSubscription(
    String plan,
    Map<String, dynamic> purchaseData,
  ) async {
    try {
      final response = await remoteDataSource.purchaseSubscription(plan, purchaseData);
      
      // Cache updated subscription data
      await localDataSource.cacheSubscriptionData(response);
      
      return Right(_subscriptionModelToEntity(response.subscription));
    } on DioError catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription() async {
    try {
      await remoteDataSource.cancelSubscription();
      return const Right(null);
    } on DioError catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Subscription>> restoreSubscription() async {
    try {
      final response = await remoteDataSource.restoreSubscription();
      return Right(_subscriptionModelToEntity(response.subscription));
    } on DioError catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUsageStats() async {
    try {
      final usageStats = await remoteDataSource.getUsageStats();
      return Right(usageStats);
    } on DioError catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Subscription _subscriptionModelToEntity(subscriptionModel) {
    return Subscription(
      id: subscriptionModel.id,
      userId: subscriptionModel.userId,
      plan: subscriptionModel.plan,
      status: subscriptionModel.status,
      currentPeriodStart: subscriptionModel.currentPeriodStart,
      currentPeriodEnd: subscriptionModel.currentPeriodEnd,
      cancelAtPeriodEnd: subscriptionModel.cancelAtPeriodEnd,
      stripeSubscriptionId: subscriptionModel.stripeSubscriptionId,
      stripeCustomerId: subscriptionModel.stripeCustomerId,
      metadata: subscriptionModel.metadata,
      createdAt: subscriptionModel.createdAt,
      updatedAt: subscriptionModel.updatedAt,
    );
  }

  Failure _handleDioException(DioError e) {
    switch (e.type) {
      case DioErrorType.connectTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
      case DioErrorType.response:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error';
        
        if (statusCode == 401) {
          return AuthFailure(message, code: statusCode);
        } else if (statusCode == 422) {
          return ValidationFailure(message, code: statusCode);
        } else {
          return ServerFailure(message, code: statusCode);
        }
      case DioErrorType.cancel:
        return const NetworkFailure('Request cancelled');
      case DioErrorType.connectionError:
        return const NetworkFailure('No internet connection');
      default:
        return UnknownFailure(e.message);
    }
  }
} 