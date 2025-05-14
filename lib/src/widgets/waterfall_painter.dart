part of 'package:kiwi_sdr/kiwi_sdr.dart';

const List<Color> _waterfallColors = [
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.red,
];

/// A custom painter for rendering a waterfall display using the provided samples.
class WaterfallPainter extends ChangeNotifier implements CustomPainter {
  /// The KiwiSdr instance used to fetch waterfall samples.
  final KiwiSdr sdr;
  Float32List? _samplesBuffer;

  ui.Image? _imageBuffer;
  ui.Image? _gradientImage;
  Size _lastSize = Size.zero;

  /// Creates a [WaterfallPainter] instance with the given [sdr].
  WaterfallPainter({required this.sdr}) {
    sdr.waterfallStream.listen((samples) {
      _samplesBuffer = samples;

      if (_lastSize != Size.zero) {
        _updateImageBuffer(_lastSize);
      }

      notifyListeners();
    });

    _generateGradientImage();
  }

  Future<void> _generateGradientImage() async {
    const gradientHeight = 256.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Gradient layout:
    // - 0.0 → 0.3: Black
    // - 0.3 → 0.8: Remaining spectrum
    // - 0.8 → 1.0: Pink

    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(0, gradientHeight),
      [
        Colors.black,
        Colors.black,
        ..._waterfallColors,
        Colors.pink,
        Colors.pink,
      ],
      [
        0.0,
        0.3,
        ...List.generate(
          _waterfallColors.length,
          (i) => 0.3 + (i / (_waterfallColors.length - 1)) * 0.5,
        ),
        0.8,
        1.0,
      ],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, gradientHeight), paint);
    final picture = recorder.endRecording();
    _gradientImage = await picture.toImage(1, gradientHeight.toInt());
  }

  void _updateImageBuffer(Size size) async {
    if (_samplesBuffer == null || _gradientImage == null) return;

    final width = size.width;
    final height = size.height;
    _lastSize = size;

    final pixelSize = width / _samplesBuffer!.length;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (_imageBuffer != null) {
      final src = Rect.fromLTWH(0, 0, width, height - pixelSize);
      final dst = Rect.fromLTWH(0, pixelSize, width, height - pixelSize);
      canvas.drawImageRect(_imageBuffer!, src, dst, Paint());
    }

    final gradientPixels = await _gradientImage!.toByteData(format: ui.ImageByteFormat.rawRgba);
    for (int x = 0; x < _samplesBuffer!.length; x++) {
      final color = _getWaterfallColor(_samplesBuffer![x], gradientPixels!);
      final paint = Paint()..color = color;

      canvas.drawRect(
        Rect.fromLTWH(x * pixelSize, 0, pixelSize, pixelSize),
        paint,
      );
    }

    final picture = recorder.endRecording();
    _imageBuffer = await picture.toImage(width.toInt(), height.toInt());
  }

  Color _getWaterfallColor(double value, ByteData gradientPixels) {
    final clamped = (value.clamp(0.0, 1.0) * 255).round();
    final offset = clamped * 4;
    final r = gradientPixels.getUint8(offset);
    final g = gradientPixels.getUint8(offset + 1);
    final b = gradientPixels.getUint8(offset + 2);
    final a = gradientPixels.getUint8(offset + 3);
    return Color.fromARGB(a, r, g, b);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_imageBuffer == null || _lastSize != size) {
      _updateImageBuffer(size);
      return;
    }

    canvas.drawImage(_imageBuffer!, Offset.zero, Paint());
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
