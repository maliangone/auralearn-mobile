import '../models/subscription_response.dart';
import '../../../../core/utils/logger.dart';

class MockSubscriptionDataSource {
  static final Map<String, dynamic> _mockSubscriptionData = {
    'current_plan': 'pro',
    'usage_count': 156,
    'monthly_limit': 500,
    'billing_cycle_start':
        DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    'billing_cycle_end':
        DateTime.now().add(const Duration(days: 15)).toIso8601String(),
    'next_billing_date':
        DateTime.now().add(const Duration(days: 15)).toIso8601String(),
    'amount_due': 39.99,
    'currency': 'USD',
    'auto_renew': true,
    'status': 'active',
    'trial_ends_at': null,
    'canceled_at': null,
  };

  Future<SubscriptionResponse> getSubscriptionStatus() async {
    AppLogger.info('Mock Subscription: Getting subscription status');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    return SubscriptionResponse.fromJson(_mockSubscriptionData);
  }

  Future<SubscriptionResponse> purchaseSubscription(
      Map<String, dynamic> purchaseData) async {
    final plan = purchaseData['plan'] as String? ?? 'standard';
    AppLogger.info('Mock Subscription: Purchasing $plan subscription');

    // Simulate payment processing time
    await Future.delayed(const Duration(milliseconds: 1200));

    // Update mock data based on purchased plan
    switch (plan) {
      case 'standard':
        _mockSubscriptionData.addAll({
          'current_plan': 'standard',
          'monthly_limit': 100,
          'amount_due': 19.99,
          'usage_count': 0, // Reset usage on new subscription
          'billing_cycle_start': DateTime.now().toIso8601String(),
          'billing_cycle_end':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'next_billing_date':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'status': 'active',
        });
        break;
      case 'pro':
        _mockSubscriptionData.addAll({
          'current_plan': 'pro',
          'monthly_limit': 500,
          'amount_due': 39.99,
          'usage_count': 0,
          'billing_cycle_start': DateTime.now().toIso8601String(),
          'billing_cycle_end':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'next_billing_date':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'status': 'active',
        });
        break;
    }

    return SubscriptionResponse.fromJson(_mockSubscriptionData);
  }

  Future<Map<String, dynamic>> getUsageStats() async {
    AppLogger.info('Mock Subscription: Getting usage statistics');

    await Future.delayed(const Duration(milliseconds: 300));

    final usageCount = _mockSubscriptionData['usage_count'] as int;
    final monthlyLimit = _mockSubscriptionData['monthly_limit'] as int;
    final currentPlan = _mockSubscriptionData['current_plan'] as String;

    return {
      'current_usage': usageCount,
      'monthly_limit': monthlyLimit,
      'usage_percentage': (usageCount / monthlyLimit * 100).round(),
      'remaining_questions': monthlyLimit - usageCount,
      'days_until_reset':
          DateTime.parse(_mockSubscriptionData['billing_cycle_end'])
              .difference(DateTime.now())
              .inDays,
      'current_plan': currentPlan,
      'daily_average': (usageCount / DateTime.now().day).round(),
      'weekly_usage': [
        {'day': 'Mon', 'count': 12},
        {'day': 'Tue', 'count': 8},
        {'day': 'Wed', 'count': 15},
        {'day': 'Thu', 'count': 10},
        {'day': 'Fri', 'count': 18},
        {'day': 'Sat', 'count': 5},
        {'day': 'Sun', 'count': 7},
      ],
      'monthly_breakdown': [
        {'week': 1, 'count': 45},
        {'week': 2, 'count': 52},
        {'week': 3, 'count': 38},
        {'week': 4, 'count': 21}, // Current week
      ],
      'top_subjects': [
        {'subject': 'Mathematics', 'count': 45, 'percentage': 28.8},
        {'subject': 'Physics', 'count': 32, 'percentage': 20.5},
        {'subject': 'Chemistry', 'count': 28, 'percentage': 17.9},
        {'subject': 'Biology', 'count': 25, 'percentage': 16.0},
        {'subject': 'English', 'count': 15, 'percentage': 9.6},
        {'subject': 'History', 'count': 11, 'percentage': 7.1},
      ],
    };
  }

  Future<void> cancelSubscription() async {
    AppLogger.info('Mock Subscription: Canceling subscription');

    await Future.delayed(const Duration(milliseconds: 600));

    _mockSubscriptionData.addAll({
      'status': 'canceled',
      'canceled_at': DateTime.now().toIso8601String(),
      'auto_renew': false,
    });
  }

  Future<void> resumeSubscription() async {
    AppLogger.info('Mock Subscription: Resuming subscription');

    await Future.delayed(const Duration(milliseconds: 500));

    _mockSubscriptionData.addAll({
      'status': 'active',
      'canceled_at': null,
      'auto_renew': true,
    });
  }

  Future<Map<String, dynamic>> getAvailablePlans() async {
    AppLogger.info('Mock Subscription: Getting available plans');

    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'plans': [
        {
          'id': 'free',
          'name': 'Free',
          'price': 0.0,
          'currency': 'USD',
          'billing_period': 'monthly',
          'questions_limit': 10,
          'features': [
            'Basic question solving',
            'Text-based answers',
            'Community support',
          ],
          'overage_rate': 0.3,
          'popular': false,
        },
        {
          'id': 'standard',
          'name': 'Standard',
          'price': 19.99,
          'currency': 'USD',
          'billing_period': 'monthly',
          'questions_limit': 100,
          'features': [
            'Advanced question solving',
            'Step-by-step solutions',
            'Image recognition',
            'Priority support',
            'History tracking',
          ],
          'overage_rate': 0.3,
          'popular': true,
        },
        {
          'id': 'pro',
          'name': 'Pro',
          'price': 39.99,
          'currency': 'USD',
          'billing_period': 'monthly',
          'questions_limit': 500,
          'features': [
            'Unlimited question types',
            'Detailed explanations',
            'Formula breakdowns',
            'Instant answers',
            'Premium support',
            'Advanced analytics',
            'Export capabilities',
          ],
          'overage_rate': 0.2,
          'popular': false,
        }
      ],
      'current_plan': _mockSubscriptionData['current_plan'],
      'currency_options': ['USD', 'EUR', 'GBP'],
      'billing_periods': ['monthly', 'yearly'],
    };
  }

  Future<void> incrementUsage() async {
    final currentUsage = _mockSubscriptionData['usage_count'] as int;
    _mockSubscriptionData['usage_count'] = currentUsage + 1;

    AppLogger.info(
        'Mock Subscription: Usage incremented to ${currentUsage + 1}');
  }
}
