import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../features/auth/data/models/login_request.dart';
import '../../features/auth/data/models/register_request.dart';
import '../../features/auth/data/models/auth_response.dart';
import '../../features/question/data/models/question_request.dart';
import '../../features/question/domain/entities/question_response.dart';
import '../../features/history/data/models/history_response.dart';
import '../../features/subscription/data/models/subscription_response.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // Auth endpoints
  @POST('/auth/login')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @POST('/auth/register')
  Future<AuthResponse> register(@Body() RegisterRequest request);

  @POST('/auth/logout')
  Future<void> logout();

  @POST('/auth/refresh')
  Future<AuthResponse> refreshToken(@Field('refresh_token') String refreshToken);

  @GET('/auth/profile')
  Future<AuthResponse> getProfile();

  // Question endpoints
  @POST('/questions/submit')
  Future<QuestionResponse> submitQuestion(@Body() QuestionRequest request);

  @POST('/questions/upload-images')
  @MultiPart()
  Future<Map<String, dynamic>> uploadImages(@Part() List<MultipartFile> images);

  // History endpoints
  @GET('/history')
  Future<HistoryResponse> getHistory(
    @Query('page') int page,
    @Query('limit') int limit,
    @Query('subject') String? subject,
  );

  @DELETE('/history/{id}')
  Future<void> deleteHistoryItem(@Path('id') String id);

  @DELETE('/history')
  Future<void> clearHistory();

  // Subscription endpoints
  @GET('/subscription/status')
  Future<SubscriptionResponse> getSubscriptionStatus();

  @POST('/subscription/purchase')
  Future<SubscriptionResponse> purchaseSubscription(
    @Body() Map<String, dynamic> purchaseData,
  );

  @GET('/subscription/usage')
  Future<Map<String, dynamic>> getUsageStats();
} 