import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../domain/repositories/subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/config/app_config.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../datasources/subscription_local_data_source.dart';
import '../datasources/mock_subscription_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource? remoteDataSource;
  final SubscriptionLocalDataSource localDataSource;
  final MockSubscriptionDataSource? mockDataSource;

  SubscriptionRepositoryImpl({
    this.remoteDataSource,
    required this.localDataSource,
    this.mockDataSource,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSubscriptionStatus() async {
    try {
      if (AppConfig.enableMockMode && mockDataSource != null) {
        final response = await mockDataSource!.getSubscriptionStatus();
        return Right({
          'subscription': response,
          'usageStats': await mockDataSource!.getUsageStats(),
        });
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      final response = await remoteDataSource!.getSubscriptionStatus();

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
      if (AppConfig.enableMockMode && mockDataSource != null) {
        final response =
            await mockDataSource!.purchaseSubscription(purchaseData);
        // Mock doesn't return Subscription entity, create one
        return Right(Subscription(
          id: 'mock_sub_id',
          userId: 'mock_user_id',
          plan: 'pro',
          status: 'active',
          currentPeriodStart: DateTime.now(),
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          cancelAtPeriodEnd: false,
          stripeSubscriptionId: null,
          stripeCustomerId: null,
          metadata: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      final response =
          await remoteDataSource!.purchaseSubscription(plan, purchaseData);

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
      if (AppConfig.enableMockMode && mockDataSource != null) {
        await mockDataSource!.cancelSubscription();
        return const Right(null);
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      await remoteDataSource!.cancelSubscription();
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
      if (AppConfig.enableMockMode && mockDataSource != null) {
        await mockDataSource!.resumeSubscription();
        return Right(Subscription(
          id: 'mock_sub_id',
          userId: 'mock_user_id',
          plan: 'pro',
          status: 'active',
          currentPeriodStart: DateTime.now(),
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          cancelAtPeriodEnd: false,
          stripeSubscriptionId: null,
          stripeCustomerId: null,
          metadata: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      final response = await remoteDataSource!.restoreSubscription();
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
      if (AppConfig.enableMockMode && mockDataSource != null) {
        final usageStats = await mockDataSource!.getUsageStats();
        return Right(usageStats);
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      final usageStats = await remoteDataSource!.getUsageStats();
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
      case DioErrorType.other:
        return const NetworkFailure('No internet connection');
      default:
        return UnknownFailure(e.message);
    }
  }
}
