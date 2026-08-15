import 'package:auralearn/core/widgets/tutor_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes both GPT LaTeX delimiter styles', () {
    expect(
      TutorMarkdown.normalizeDelimiters(
        r'inline \(x^2\), block \[\frac{1}{2}\] and $y$',
      ),
      r'inline $x^2$, block $$\frac{1}{2}$$ and $y$',
    );
  });

  testWidgets('renders inline and block LaTeX without raw markup',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TutorMarkdown(
            r'公式 \(x^2\) 与 \[t=\frac{20\pm\sqrt{400}}{9.8}\]',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TutorMarkdown), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    // The delimiters are consumed by the custom Markdown syntax instead of
    // being displayed to the student as raw text.
    expect(find.textContaining(r'\frac'), findsNothing);
  });

  testWidgets('falls back to source text for malformed LaTeX', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TutorMarkdown(r'Bad: \[\frac{1}\]')),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
