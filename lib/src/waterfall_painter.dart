part of 'package:flutter_sdr/flutter_sdr.dart';

class WaterfallPainter extends ChangeNotifier implements CustomPainter {
  final List<Float32List> samplesList = [];

  WaterfallPainter({required KiwiSdrConnection connection}) {
    connection._waterfallStream.stream.listen((samples) {
      samplesList.insert(0, samples);

      if (samplesList.length >= 2040) {
        samplesList.removeLast();
      }

      notifyListeners();
    });
  }

  static const List<Color> waterfallColors = [
    Colors.black,
    Colors.blue,
    Colors.cyan,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (samplesList.isEmpty) return;
  
    final binCount = samplesList[0].length;
    final binWidth = size.width / binCount;
    final pixelSize = binWidth; // for square pixels
  
    final totalNeededHeight = pixelSize * samplesList.length;
    final padding = size.height - totalNeededHeight;
  
    for (int y = 0; y < samplesList.length; y++) {
      final samples = samplesList[y];
  
      for (int x = 0; x < binCount; x++) {
        final color = _getWaterfallColor(samples[x]);
        final paint = Paint()..color = color;
  
        canvas.drawRect(
          Rect.fromLTWH(
            x * binWidth,
            padding + y * pixelSize,
            binWidth,
            pixelSize,
          ),
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
      
  @override
  bool? hitTest(Offset position) => null;
      
  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
      
  @override
  bool shouldRebuildSemantics(covariant WaterfallPainter oldDelegate) => shouldRepaint(oldDelegate);
}

