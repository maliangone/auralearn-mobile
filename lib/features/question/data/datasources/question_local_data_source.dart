import 'package:hive/hive.dart';
import '../models/question_response.dart';

abstract class QuestionLocalDataSource {
  Future<void> cacheQuestionResponse(QuestionResponseModel questionResponse);
  Future<QuestionResponseModel?> getLastQuestionResponse();
  Future<List<QuestionResponseModel>> getCachedQuestions();
  Future<void> clearCache();
}

class QuestionLocalDataSourceImpl implements QuestionLocalDataSource {
  static const String boxName = 'questions';
  static const String lastQuestionKey = 'last_question';

  @override
  Future<void> cacheQuestionResponse(QuestionResponseModel questionResponse) async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      await box.put(lastQuestionKey, questionResponse.toJson());
      
      // Also add to cached questions list
      final cachedQuestions = await getCachedQuestions();
      cachedQuestions.add(questionResponse);
      
      // Keep only last 50 questions
      if (cachedQuestions.length > 50) {
        cachedQuestions.removeRange(0, cachedQuestions.length - 50);
      }
      
      await box.put('questions_list', cachedQuestions.map((q) => q.toJson()).toList());
    } catch (e) {
      // Handle cache errors gracefully
    }
  }

  @override
  Future<QuestionResponseModel?> getLastQuestionResponse() async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      final questionJson = box.get(lastQuestionKey);
      
      if (questionJson != null) {
        return QuestionResponseModel.fromJson(Map<String, dynamic>.from(questionJson));
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<QuestionResponseModel>> getCachedQuestions() async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      final questionsJson = box.get('questions_list', defaultValue: <Map>[]);
      
      if (questionsJson is List) {
        return questionsJson
            .map((json) => QuestionResponseModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      await box.clear();
    } catch (e) {
      // Handle cache errors gracefully
    }
  }
} 