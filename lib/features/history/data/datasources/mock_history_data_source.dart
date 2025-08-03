import '../models/history_response.dart';
import '../../../../core/utils/logger.dart';

class MockHistoryDataSource {
  static final List<Map<String, dynamic>> _mockHistoryItems = [
    {
      'id': 'hist_001',
      'question': 'Solve for x: 2x + 5 = 13',
      'answer': 'x = 4',
      'subject': 'Mathematics',
      'difficulty': 'Easy',
      'created_at':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'confidence': 0.95,
    },
    {
      'id': 'hist_002',
      'question': 'What is the process of photosynthesis?',
      'answer':
          'Photosynthesis is the process by which plants convert light energy into chemical energy...',
      'subject': 'Biology',
      'difficulty': 'Medium',
      'created_at':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'confidence': 0.88,
    },
    {
      'id': 'hist_003',
      'question': 'Find the derivative of f(x) = x³ + 2x² - 5x + 1',
      'answer': 'f\'(x) = 3x² + 4x - 5',
      'subject': 'Mathematics',
      'difficulty': 'Medium',
      'created_at':
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'confidence': 0.92,
    },
    {
      'id': 'hist_004',
      'question': 'Explain Newton\'s First Law of Motion',
      'answer':
          'An object at rest stays at rest and an object in motion stays in motion...',
      'subject': 'Physics',
      'difficulty': 'Easy',
      'created_at':
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'confidence': 0.90,
    },
    {
      'id': 'hist_005',
      'question': 'What is the molecular formula for glucose?',
      'answer': 'C₆H₁₂O₆',
      'subject': 'Chemistry',
      'difficulty': 'Easy',
      'created_at':
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'confidence': 0.98,
    },
    {
      'id': 'hist_006',
      'question': 'Analyze the themes in "To Kill a Mockingbird"',
      'answer':
          'The main themes include racial injustice, moral growth, and loss of innocence...',
      'subject': 'English',
      'difficulty': 'Hard',
      'created_at':
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      'confidence': 0.85,
    },
    {
      'id': 'hist_007',
      'question': 'Calculate the area of a circle with radius 5 cm',
      'answer': 'Area = πr² = π(5)² = 25π ≈ 78.54 cm²',
      'subject': 'Mathematics',
      'difficulty': 'Easy',
      'created_at':
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'confidence': 0.96,
    },
    {
      'id': 'hist_008',
      'question': 'What caused World War I?',
      'answer':
          'Multiple factors including imperialism, alliances, militarism, and nationalism...',
      'subject': 'History',
      'difficulty': 'Medium',
      'created_at':
          DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      'confidence': 0.87,
    },
  ];

  Future<HistoryResponse> getHistory({
    required int page,
    required int limit,
    String? subject,
  }) async {
    AppLogger.info(
        'Mock History: Getting history - page: $page, limit: $limit, subject: $subject');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    List<Map<String, dynamic>> filteredItems = List.from(_mockHistoryItems);

    // Filter by subject if provided
    if (subject != null && subject.isNotEmpty) {
      filteredItems = filteredItems
          .where(
              (item) => item['subject'].toLowerCase() == subject.toLowerCase())
          .toList();
    }

    // Sort by date (newest first)
    filteredItems.sort((a, b) => DateTime.parse(b['created_at'])
        .compareTo(DateTime.parse(a['created_at'])));

    // Pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    final paginatedItems = filteredItems.skip(startIndex).take(limit).toList();

    // Convert Map<String, dynamic> to HistoryItemModel
    final historyItems = paginatedItems
        .map((item) => HistoryItemModel(
              id: item['id'] as String,
              question: item['question'] as String?,
              answer: item['answer'] as String?,
              subject: item['subject'] as String?,
              confidence: item['confidence'] as double?,
              createdAt: DateTime.parse(item['created_at'] as String),
              updatedAt: DateTime.parse(item['created_at'] as String),
            ))
        .toList();

    return HistoryResponse(
      items: historyItems,
      totalCount: filteredItems.length,
      page: page,
      limit: limit,
      hasNext: endIndex < filteredItems.length,
    );
  }

  Future<void> deleteHistoryItem(String id) async {
    AppLogger.info('Mock History: Deleting item $id');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _mockHistoryItems.removeWhere((item) => item['id'] == id);
  }

  Future<void> clearHistory() async {
    AppLogger.info('Mock History: Clearing all history');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _mockHistoryItems.clear();
  }

  Future<Map<String, dynamic>> getHistoryStats() async {
    AppLogger.info('Mock History: Getting history statistics');

    await Future.delayed(const Duration(milliseconds: 400));

    final subjectCounts = <String, int>{};
    final difficultyCounts = <String, int>{};

    for (final item in _mockHistoryItems) {
      final subject = item['subject'] as String;
      final difficulty = item['difficulty'] as String;

      subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
      difficultyCounts[difficulty] = (difficultyCounts[difficulty] ?? 0) + 1;
    }

    return {
      'total_questions': _mockHistoryItems.length,
      'subjects': subjectCounts,
      'difficulty_distribution': difficultyCounts,
      'average_confidence': _mockHistoryItems.isEmpty
          ? 0.0
          : _mockHistoryItems
                  .map((item) => item['confidence'] as double)
                  .reduce((a, b) => a + b) /
              _mockHistoryItems.length,
      'questions_this_week': _mockHistoryItems
          .where((item) => DateTime.parse(item['created_at'])
              .isAfter(DateTime.now().subtract(const Duration(days: 7))))
          .length,
      'most_active_subject': subjectCounts.isNotEmpty
          ? subjectCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : 'None',
    };
  }

  Future<Map<String, dynamic>> searchHistory({
    required String query,
    String? subject,
    String? difficulty,
  }) async {
    AppLogger.info('Mock History: Searching history - query: $query');

    await Future.delayed(const Duration(milliseconds: 500));

    List<Map<String, dynamic>> results = _mockHistoryItems.where((item) {
      final matchesQuery = query.isEmpty ||
          item['question'].toLowerCase().contains(query.toLowerCase()) ||
          item['answer'].toLowerCase().contains(query.toLowerCase());

      final matchesSubject = subject == null ||
          item['subject'].toLowerCase() == subject.toLowerCase();

      final matchesDifficulty = difficulty == null ||
          item['difficulty'].toLowerCase() == difficulty.toLowerCase();

      return matchesQuery && matchesSubject && matchesDifficulty;
    }).toList();

    // Sort by relevance (mock implementation)
    results.sort((a, b) => DateTime.parse(b['created_at'])
        .compareTo(DateTime.parse(a['created_at'])));

    return {
      'results': results,
      'total_found': results.length,
      'query': query,
      'filters': {
        'subject': subject,
        'difficulty': difficulty,
      }
    };
  }
}
