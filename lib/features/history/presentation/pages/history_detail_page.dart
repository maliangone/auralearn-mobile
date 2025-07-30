import 'package:flutter/material.dart';

class HistoryDetailPage extends StatelessWidget {
  final String historyId;
  
  const HistoryDetailPage({
    super.key,
    required this.historyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Detail'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'History ID: $historyId',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // TODO: Implement detailed history view
            // This would typically show the full question, answer, images, etc.
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('This is where the detailed question would appear.'),
                    SizedBox(height: 16),
                    Text(
                      'Answer:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('This is where the detailed answer would appear.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 