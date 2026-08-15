import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

/// Rich text for model-generated tutor output (problem transcription, steps,
/// conclusion). Renders Markdown structure plus LaTeX math (`$…$`, `$$…$$`,
/// and the `\(…\)` / `\[…\]` delimiters GPT models prefer) via
/// flutter_math_fork.
///
/// Why not plain [Text]: reasoning-tier models (e.g. GPT-5.6 Luna at high
/// effort) ignore the "no LaTeX" prompt rule and emit `\frac` / `\sqrt` /
/// `\[…\]` blocks; a plain Text widget shows the raw markup, which reads as
/// "内容无法 render" to the student.
class TutorMarkdown extends StatelessWidget {
  final String data;

  /// Base text style (color/size) — the LaTeX nodes inherit it so math picks
  /// up the surrounding theme color automatically.
  final TextStyle? style;

  const TutorMarkdown(this.data, {super.key, this.style});

  /// Normalizes `\(...\)` → `$...$` and `\[...\]` → `$$...$$` so the single
  /// [LatexSyntax] below handles every delimiter style.
  static String normalizeDelimiters(String input) {
    return input
        .replaceAll(r'\[', r'$$')
        .replaceAll(r'\]', r'$$')
        .replaceAll(r'\(', r'$')
        .replaceAll(r'\)', r'$');
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    return MarkdownBlock(
      data: normalizeDelimiters(data),
      selectable: false,
      config: MarkdownConfig(configs: [
        if (baseStyle != null) PConfig(textStyle: baseStyle),
      ]),
      generator: MarkdownGenerator(
        linesMargin: const EdgeInsets.symmetric(vertical: 4),
        generators: [_latexGenerator],
        inlineSyntaxList: [_LatexSyntax()],
      ),
    );
  }
}

final _latexGenerator = SpanNodeGeneratorWithTag(
  tag: _latexTag,
  generator: (e, config, visitor) =>
      _LatexNode(e.attributes, e.textContent, config),
);

const _latexTag = 'latex';

class _LatexSyntax extends m.InlineSyntax {
  _LatexSyntax() : super(r'(\$\$[\s\S]+?\$\$)|(\$[^\$\n]+?\$)');

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final matchValue = match.input.substring(match.start, match.end);
    String content = '';
    var isInline = true;
    if (matchValue.length > 4 &&
        matchValue.startsWith(r'$$') &&
        matchValue.endsWith(r'$$')) {
      content = matchValue.substring(2, matchValue.length - 2);
      isInline = false;
    } else if (matchValue.length > 2 &&
        matchValue.startsWith(r'$') &&
        matchValue.endsWith(r'$')) {
      content = matchValue.substring(1, matchValue.length - 1);
    }
    final el = m.Element.text(_latexTag, matchValue);
    el.attributes['content'] = content;
    el.attributes['isInline'] = '$isInline';
    parser.addNode(el);
    return true;
  }
}

class _LatexNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  _LatexNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final isInline = attributes['isInline'] == 'true';
    final style = parentStyle ?? config.p.textStyle;
    if (content.isEmpty) return TextSpan(style: style, text: textContent);
    final latex = Math.tex(
      content,
      mathStyle: MathStyle.text,
      textStyle: style,
      textScaleFactor: 1,
      onErrorFallback: (error) => Text(
        textContent,
        style: style,
      ),
    );
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: isInline
          ? latex
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Center(child: latex),
                  ),
                ),
              ),
            ),
    );
  }
}
