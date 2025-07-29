import 'package:flutter_bloc/flutter_bloc.dart';

import 'subscription_event.dart';
import 'subscription_state.dart';
import '../../domain/usecases/get_subscription_status_usecase.dart';
import '../../domain/usecases/purchase_subscription_usecase.dart';
import '../../../../core/utils/logger.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetSubscriptionStatusUseCase getSubscriptionStatusUseCase;
  final PurchaseSubscriptionUseCase purchaseSubscriptionUseCase;

  SubscriptionBloc({
    required this.getSubscriptionStatusUseCase,
    required this.purchaseSubscriptionUseCase,
  }) : super(SubscriptionInitial()) {
    on<SubscriptionStatusRequested>(_onSubscriptionStatusRequested);
    on<SubscriptionPurchaseRequested>(_onSubscriptionPurchaseRequested);
    on<SubscriptionCancelRequested>(_onSubscriptionCancelRequested);
    on<SubscriptionRestoreRequested>(_onSubscriptionRestoreRequested);
    on<UsageUpdated>(_onUsageUpdated);
  }

  Future<void> _onSubscriptionStatusRequested(
    SubscriptionStatusRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    final result = await getSubscriptionStatusUseCase.call();
    
    result.fold(
      (failure) {
        AppLogger.error('Failed to get subscription status: ${failure.message}');
        emit(SubscriptionError(message: failure.message, code: failure.code));
      },
      (data) {
        AppLogger.info('Subscription status loaded successfully');
        emit(SubscriptionLoaded(
          subscription: data['subscription'],
          usageStats: data['usageStats'],
        ));
      },
    );
  }

  Future<void> _onSubscriptionPurchaseRequested(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionPurchasing());
    
    final result = await purchaseSubscriptionUseCase.call(
      PurchaseSubscriptionParams(
        plan: event.plan,
        purchaseData: event.purchaseData,
      ),
    );
    
    result.fold(
      (failure) {
        AppLogger.error('Failed to purchase subscription: ${failure.message}');
        emit(SubscriptionError(message: failure.message, code: failure.code));
      },
      (subscription) {
        AppLogger.info('Subscription purchased successfully: ${event.plan}');
        emit(SubscriptionPurchaseSuccess(subscription: subscription));
      },
    );
  }

  Future<void> _onSubscriptionCancelRequested(
    SubscriptionCancelRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    // TODO: Implement subscription cancellation
    AppLogger.info('Subscription cancellation requested');
  }

  Future<void> _onSubscriptionRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    // TODO: Implement subscription restoration
    AppLogger.info('Subscription restoration requested');
  }

  Future<void> _onUsageUpdated(
    UsageUpdated event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (state is SubscriptionLoaded) {
      final currentState = state as SubscriptionLoaded;
      final updatedUsageStats = Map<String, dynamic>.from(currentState.usageStats);
      updatedUsageStats['usageCount'] = event.newUsageCount;
      
      emit(SubscriptionLoaded(
        subscription: currentState.subscription,
        usageStats: updatedUsageStats,
      ));
      
      AppLogger.info('Usage updated: ${event.newUsageCount}');
    }
  }
} 