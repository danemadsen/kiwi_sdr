part of 'package:kiwi_sdr/kiwi_sdr.dart';

const List<Color> _waterfallColors = [
  Colors.black,
  Colors.indigo,
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.red,
  Colors.pink,
  Colors.white,
];

/// A custom painter for rendering a waterfall display using the provided samples.
class WaterfallPainter extends ChangeNotifier implements CustomPainter {
  final KiwiSdr _sdr;
  Float32List? _samplesBuffer;

  ui.Image? _imageBuffer;
  Size _lastSize = Size.zero;

  /// Creates a [WaterfallPainter] instance with the given [sdr].
  WaterfallPainter(this._sdr) {
    _sdr.waterfallStream.listen((samples) {
      _samplesBuffer = samples;

      if (_lastSize != Size.zero) {
        _updateImageBuffer(_lastSize);
      }

      notifyListeners(); // triggers CustomPaint to repaint
    });
  }

  void _updateImageBuffer(Size size) async {
    if (_samplesBuffer == null) return;

    final width = size.width;
    final height = size.height;
    _lastSize = size;

    final pixelSize = width / _samplesBuffer!.length;

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
    for (int x = 0; x < _samplesBuffer!.length; x++) {
      final color = _getWaterfallColor(_samplesBuffer![x]);
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
    // Clamp and normalize to [0.0, 1.0]
    final clamped = value.clamp(0.0, 1.0);

    final step = 1.0 / (_waterfallColors.length - 1);
    final idx = (clamped / step).floor();
    if (idx >= _waterfallColors.length - 1) return _waterfallColors.last;

    final startColor = _waterfallColors[idx];
    final endColor = _waterfallColors[idx + 1];
    final localValue = (clamped - (step * idx)) / step;

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
