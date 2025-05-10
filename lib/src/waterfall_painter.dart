part of 'package:kiwi_sdr/kiwi_sdr.dart';

const List<Color> _waterfallColors = [
  Colors.black,
  Colors.blue,
  Colors.cyan,
  Colors.green,
  Colors.yellow,
  Colors.orange,
  Colors.red,
];

/// A custom painter for rendering a waterfall display using the provided samples.
class WaterfallPainter extends ChangeNotifier implements CustomPainter {
  final List<Float32List> _samplesList = [];
  int _maxSamples = 512;

  int _binCount = 0;
  double _pixelSize = 1.0;

  ui.Image? _imageBuffer;
  Size _lastSize = Size.zero;

  /// Creates a [WaterfallPainter] instance with the given [connection].
  WaterfallPainter({required KiwiSdr connection}) {
    connection.waterfallStream.listen((samples) {
      _samplesList.insert(0, samples);

      if (_lastSize != Size.zero) {
        _updateImageBuffer(_lastSize);
      }

      if (_samplesList.length > _maxSamples) {
        _samplesList.removeRange(_maxSamples, _samplesList.length);
      }

      notifyListeners(); // triggers CustomPaint to repaint
    });
  }

  void _updateImageBuffer(Size size) async {
    if (_samplesList.isEmpty) return;

    final width = size.width;
    final height = size.height;
    _lastSize = size;

    _binCount = _samplesList[0].length;
    _pixelSize = width / _binCount;
    _maxSamples = height ~/ _pixelSize;

    // Shift previous image content up
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw existing image if present
    if (_imageBuffer != null) {
      final src = Rect.fromLTWH(0, 0, width, height - _pixelSize);
      final dst = Rect.fromLTWH(0, _pixelSize, width, height - _pixelSize);
      canvas.drawImageRect(_imageBuffer!, src, dst, Paint());
    }

    // Draw new samples row at the bottom
    final samples = _samplesList.first;
    for (int x = 0; x < _binCount; x++) {
      final color = _getWaterfallColor(samples[x]);
      final paint = Paint()..color = color;

      canvas.drawRect(
        Rect.fromLTWH(x * _pixelSize, 0, _pixelSize, _pixelSize),
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
