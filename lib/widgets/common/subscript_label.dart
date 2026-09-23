import 'package:flutter/material.dart';

/// Text with a trailing typographic subscript, e.g. the 2 in CO₂ / SpO₂.
///
/// The bundled fonts do not reliably carry the U+2082 glyph, so it renders as
/// a tofu box. Drawing a shifted, smaller digit works everywhere instead.
class SubscriptLabel extends StatelessWidget {
  const SubscriptLabel({
    super.key,
    required this.text,
    required this.subscript,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String subscript;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 14;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, fontSize * 0.18),
              child: Text(
                subscript,
                style: style.copyWith(fontSize: fontSize * 0.7, height: 1),
              ),
            ),
          ),
        ],
      ),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
