part of 'package:flutter_sdr/flutter_sdr.dart';

const List<Color> _waterfallColors = [
  Colors.black,
  Colors.blue,
  Colors.cyan,
  Colors.green,
  Colors.yellow,
  Colors.orange,
  Colors.red,
];

class WaterfallPainter extends ChangeNotifier implements CustomPainter {
  final List<Float32List> samplesList = [];
  int maxSamples = 512;

  WaterfallPainter({required KiwiSdrConnection connection}) {
    connection._waterfallStream.stream.listen((samples) {
      samplesList.insert(0, samples);

      if (samplesList.length >= maxSamples) {
        samplesList.removeRange(maxSamples, samplesList.length);
      }

      notifyListeners();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (samplesList.isEmpty) return;

    final binCount = samplesList[0].length;
    final pixelSize = size.width / binCount;
    maxSamples = size.height ~/ pixelSize;

    for (int y = 0; y < samplesList.length; y++) {
      final samples = samplesList[y];

      for (int x = 0; x < binCount; x++) {
        final color = _getWaterfallColor(samples[x]);
        final paint = Paint()..color = color;

        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelSize,
            y * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );
      }
    }
  }

  Color _getWaterfallColor(double value) {
    final step = 1 / (_waterfallColors.length - 1);
    final idx = (value / step).floor();
    if (idx >= _waterfallColors.length - 1) return _waterfallColors.last;

    final startColor = _waterfallColors[idx];
    final endColor = _waterfallColors[idx + 1];
    final localValue = (value - (step * idx)) / step;

    return Color.lerp(startColor, endColor, localValue)!;
  }

  @override
  bool shouldRepaint(covariant WaterfallPainter oldDelegate) =>
      oldDelegate.samplesList != samplesList;
      
  @override
  bool? hitTest(Offset position) => null;
      
  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
      
  @override
  bool shouldRebuildSemantics(covariant WaterfallPainter oldDelegate) => shouldRepaint(oldDelegate);
}

