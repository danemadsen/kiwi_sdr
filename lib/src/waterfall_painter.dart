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

  int binCount = 0;
  double pixelSize = 1.0;

  ui.Image? _imageBuffer;
  Size _lastSize = Size.zero;

  WaterfallPainter({required KiwiSdrConnection connection}) {
    connection._waterfallStream.stream.listen((samples) {
      samplesList.insert(0, samples);

      if (_lastSize != Size.zero) {
        _updateImageBuffer(_lastSize);
      }

      if (samplesList.length > maxSamples) {
        samplesList.removeRange(maxSamples, samplesList.length);
      }

      notifyListeners(); // triggers CustomPaint to repaint
    });
  }

  void _updateImageBuffer(Size size) async {
    if (samplesList.isEmpty) return;

    final width = size.width;
    final height = size.height;
    _lastSize = size;

    binCount = samplesList[0].length;
    pixelSize = width / binCount;
    maxSamples = height ~/ pixelSize;

    // Shift previous image content up
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw existing image if present
    if (_imageBuffer != null) {
      final src = Rect.fromLTWH(0, 0, width, height - pixelSize);
      final dst = Rect.fromLTWH(0, pixelSize, width, height - pixelSize);
      canvas.drawImageRect(_imageBuffer!, src, dst, Paint());
    }

    // Draw new samples row at the bottom
    final samples = samplesList.first;
    for (int x = 0; x < binCount; x++) {
      final color = _getWaterfallColor(samples[x]);
      final paint = Paint()..color = color;

      canvas.drawRect(
        Rect.fromLTWH(x * pixelSize, 0, pixelSize, pixelSize),
        paint,
      );
    }

    final picture = recorder.endRecording();
    _imageBuffer = await picture.toImage(width.toInt(), height.toInt());
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_imageBuffer == null || _lastSize != size) {
      _updateImageBuffer(size);
      return;
    }

    canvas.drawImage(_imageBuffer!, Offset.zero, Paint());
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
  bool shouldRepaint(covariant WaterfallPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant WaterfallPainter oldDelegate) => false;
}
