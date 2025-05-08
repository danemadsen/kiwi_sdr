part of 'package:flutter_sdr/flutter_sdr.dart';

class WaterfallPainter extends CustomPainter {
  final List<Uint8List> samplesList;

  WaterfallPainter({required this.samplesList});

  static const List<Color> waterfallColors = [
    Colors.black,
    Colors.blue,
    Colors.cyan,
    Colors.green,
    Colors.yellow,
    Colors.red,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (samplesList.isEmpty) return;

    final binCount = samplesList[0].length;
    final binWidth = size.width / binCount;
    final lineHeight = size.height / samplesList.length;

    for (int y = 0; y < samplesList.length; y++) {
      final samples = samplesList[y];
      for (int x = 0; x < binCount; x++) {
        final intensity = samples[x] / 255.0;
        final color = _getWaterfallColor(intensity);
        final paint = Paint()..color = color;

        canvas.drawRect(
          Rect.fromLTWH(
              x * binWidth,
              size.height - (y + 1) * lineHeight,
              binWidth,
              lineHeight),
          paint,
        );
      }
    }
  }

  Color _getWaterfallColor(double value) {
    final step = 1 / (waterfallColors.length - 1);
    final idx = (value / step).floor();
    if (idx >= waterfallColors.length - 1) return waterfallColors.last;

    final startColor = waterfallColors[idx];
    final endColor = waterfallColors[idx + 1];
    final localValue = (value - (step * idx)) / step;

    return Color.lerp(startColor, endColor, localValue)!;
  }

  @override
  bool shouldRepaint(covariant WaterfallPainter oldDelegate) =>
      oldDelegate.samplesList != samplesList;
}

