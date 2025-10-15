import 'dart:math';

import '../models/question_request.dart';
import '../models/question_response.dart';
import '../../../../core/utils/logger.dart';

class MockQuestionDataSource {
  static const List<String> _mockSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History'
  ];

  static const List<String> _mockExplanations = [
    'This is a comprehensive explanation of the mathematical concept. Let me break this down step by step:\n\n1. First, we need to understand the basic principle\n2. Then we apply the formula\n3. Finally, we solve for the unknown variable\n\nThe key insight here is understanding the relationship between variables.',
    'Looking at this physics problem, we can apply Newton\'s laws of motion:\n\n• First Law: An object at rest stays at rest\n• Second Law: F = ma\n• Third Law: For every action, there\'s an equal and opposite reaction\n\nBy applying these principles, we can solve this step by step.',
    'This chemistry question involves understanding molecular structure and bonding:\n\n1. Identify the elements involved\n2. Determine their valence electrons\n3. Apply bonding rules\n4. Draw the molecular structure\n\nRemember that atoms want to achieve stable electron configurations.',
    'For this biology concept, let\'s examine the cellular process:\n\n• Cell membrane controls what enters and exits\n• Mitochondria produce energy (ATP)\n• Nucleus contains genetic material\n• Ribosomes synthesize proteins\n\nUnderstanding cell structure helps explain function.',
    'This English literature analysis requires examining:\n\n1. Theme and central message\n2. Character development\n3. Literary devices used\n4. Historical context\n\nConsider how the author uses symbolism to convey meaning.',
  ];

  Future<QuestionResponseModel> submitQuestion(QuestionRequest request) async {
    AppLogger.info('Mock Question: Submitting question - ${request.subject}');

    // Simulate processing time
    await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1000)));

    final random = Random();
    final subject =
        request.subject ?? _mockSubjects[random.nextInt(_mockSubjects.length)];
    final explanation =
        _mockExplanations[random.nextInt(_mockExplanations.length)];

    // Simulate different response types
    final responseTypes = ['text', 'steps', 'formula'];
    final responseType = responseTypes[random.nextInt(responseTypes.length)];

    Map<String, dynamic> mockResponse;

    switch (responseType) {
      case 'steps':
        mockResponse = {
          'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
          'question': request.content ?? 'Extracted question from image',
          'answer': 'The answer is 42',
          'explanation': explanation,
          'subject': subject,
          'confidence': 0.85 + random.nextDouble() * 0.14,
          'steps': [
            {
              'step': 1,
              'description': 'Identify the given information',
              'formula': null
            },
            {
              'step': 2,
              'description': 'Apply the relevant formula',
              'formula': 'y = mx + b'
            },
            {
              'step': 3,
              'description': 'Substitute values and solve',
              'formula': null
            },
            {'step': 4, 'description': 'Verify the answer', 'formula': null},
          ],
          'difficulty': ['Easy', 'Medium', 'Hard'][random.nextInt(3)],
          'estimated_time': '${5 + random.nextInt(20)} minutes',
          'related_topics': ['Linear Equations', 'Algebra', 'Problem Solving'],
          'created_at': DateTime.now().toIso8601String(),
        };
        break;

      case 'formula':
        mockResponse = {
          'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
          'question': request.content ?? 'Extracted question from image',
          'answer': '∫x²dx = x³/3 + C',
          'explanation': explanation,
          'subject': subject,
          'confidence': 0.90 + random.nextDouble() * 0.09,
          'formula': {
            'name': 'Integration by Power Rule',
            'expression': '∫x^n dx = x^(n+1)/(n+1) + C',
            'variables': {
              'x': 'variable of integration',
              'n': 'power (n ≠ -1)',
              'C': 'constant of integration'
            }
          },
          'difficulty': 'Medium',
          'estimated_time': '${10 + random.nextInt(15)} minutes',
          'created_at': DateTime.now().toIso8601String(),
        };
        break;

      default:
        mockResponse = {
          'id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
          'question': request.content ?? 'Extracted question from image',
          'answer':
              'Based on the analysis of your question, here is the detailed answer...',
          'explanation': explanation,
          'subject': subject,
          'confidence': 0.80 + random.nextDouble() * 0.19,
          'difficulty': ['Easy', 'Medium', 'Hard'][random.nextInt(3)],
          'estimated_time': '${3 + random.nextInt(12)} minutes',
          'keywords': ['analysis', 'solution', 'concept'],
          'created_at': DateTime.now().toIso8601String(),
        };
    }

    return QuestionResponseModel.fromJson(mockResponse);
  }

  Future<Map<String, dynamic>> uploadImages(List<String> imagePaths) async {
    AppLogger.info('Mock Question: Uploading ${imagePaths.length} images');

    // Simulate upload time
    await Future.delayed(Duration(milliseconds: 500 * imagePaths.length));

    return {
      'success': true,
      'message': 'Images uploaded successfully',
      'image_urls': imagePaths
          .map((path) => 'https://mock.storage/images/${path.split('/').last}')
          .toList(),
      'extracted_text': 'Sample extracted text from uploaded images',
    };
  }

  Future<Map<String, dynamic>> getQuestionHints(String questionId) async {
    AppLogger.info('Mock Question: Getting hints for $questionId');

    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'hints': [
        'Start by identifying what type of problem this is',
        'Look for key formulas or concepts that apply',
        'Break the problem into smaller, manageable steps',
        'Check your units and make sure they\'re consistent',
      ],
      'related_examples': [
        {'title': 'Similar Problem 1', 'url': 'https://example.com/problem1'},
        {'title': 'Similar Problem 2', 'url': 'https://example.com/problem2'}
      ]
    };
  }
}
