import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../features/auth/data/models/login_request.dart';
import '../../features/auth/data/models/register_request.dart';
import '../../features/auth/data/models/auth_response.dart';
import '../../features/question/data/models/question_request.dart';
import '../../features/question/data/models/question_response.dart';
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
  Future<AuthResponse> refreshToken(
      @Field('refresh_token') String refreshToken);

  @GET('/auth/profile')
  Future<AuthResponse> getProfile();

  // Question endpoints
  @POST('/questions/submit')
  Future<QuestionResponseModel> submitQuestion(@Body() QuestionRequest request);

  @POST('/questions/upload-images')
  @MultiPart()
  Future<dynamic> uploadImages(@Part() List<MultipartFile> images);

  // History is now 100% local-first (Drift); remote history endpoints removed.

  // Subscription endpoints
  @GET('/subscription/status')
  Future<SubscriptionResponse> getSubscriptionStatus();

  @POST('/subscription/purchase')
  Future<SubscriptionResponse> purchaseSubscription(
    @Body() Map<String, dynamic> purchaseData,
  );

  @GET('/subscription/usage')
  Future<dynamic> getUsageStats();
}
