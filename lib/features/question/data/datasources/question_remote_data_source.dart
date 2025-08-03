import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/question_request.dart';
import '../models/question_response.dart';

abstract class QuestionRemoteDataSource {
  Future<QuestionResponseModel> submitQuestion(QuestionRequest request);
  Future<Map<String, dynamic>> uploadImages(List<MultipartFile> images);
  Future<List<QuestionResponseModel>> getQuestionHistory();
  Future<void> deleteQuestion(String questionId);
}

class QuestionRemoteDataSourceImpl implements QuestionRemoteDataSource {
  final ApiClient apiClient;

  QuestionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<QuestionResponseModel> submitQuestion(QuestionRequest request) async {
    try {
      final response = await apiClient.submitQuestion(request);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> uploadImages(List<MultipartFile> images) async {
    try {
      return await apiClient.uploadImages(images);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuestionResponseModel>> getQuestionHistory() async {
    try {
      // This would typically come from the history endpoint
      // For now, return empty list as history is handled separately
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    try {
      // This would typically delete a specific question
      // Implementation depends on backend API
    } catch (e) {
      rethrow;
    }
  }
}
