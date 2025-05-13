part of 'package:kiwi_sdr/kiwi_sdr.dart';

/// A widget that displays a frequency scale bar for the KiwiSDR.
class FrequencyScaleBar extends StatelessWidget {
  /// The KiwiSdr instance that provides the frequency information.
  final KiwiSdr sdr;

  /// The frequency scale bar widget that displays the frequency range of the SDR.
  const FrequencyScaleBar({
    super.key,
    required this.sdr,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: sdr, 
    builder: _builder
  );

  Widget _builder(BuildContext context, Widget? child) => CustomPaint(
    painter: _FrequencyScalePainter(
      centerFrequencyHz: sdr.centerFrequency ?? 15e6,
      maxSpanHz: sdr.maxFrequency ?? 30e6,
    ),
    size: const Size(double.infinity, 40),
  );
}

class _FrequencyScalePainter extends CustomPainter {
  final double centerFrequencyHz;
  final double maxSpanHz;

  _FrequencyScalePainter({
    required this.centerFrequencyHz,
    required this.maxSpanHz,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    final double height = size.height;
    final double width = size.width;

    // Gradient background
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, height),
      [Colors.black, Colors.grey.shade800],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..shader = gradient,
    );

    final minHz = centerFrequencyHz - (maxSpanHz / 2);
    final maxHz = centerFrequencyHz + (maxSpanHz / 2);
    final totalRangeHz = maxHz - minHz;

    const double mhzStep = 1e6;
    const double majorStep = 5e6;

    final double firstTickHz = (minHz / mhzStep).ceil() * mhzStep;
    final double lastTickHz = (maxHz / mhzStep).floor() * mhzStep;

    for (double freqHz = firstTickHz; freqHz <= lastTickHz; freqHz += mhzStep) {
      final double x = ((freqHz - minHz) / totalRangeHz) * width;
      final bool isMajor = freqHz % majorStep == 0;

      final double tickHeight = isMajor ? height * 0.6 : height * 0.3;
      canvas.drawLine(
        Offset(x, height - tickHeight),
        Offset(x, height),
        paint,
      );

      if (isMajor) {
        final labelText = freqHz >= 1e6
            ? '${(freqHz / 1e6).toStringAsFixed(0)} MHz'
            : freqHz >= 1e3
            ? '${(freqHz / 1e3).toStringAsFixed(0)} kHz'
            : '${freqHz.toStringAsFixed(0)} Hz';

        final textSpan = TextSpan(
          text: labelText,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        );

        final tp = TextPainter(
          text: textSpan,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();

        Offset labelOffset;
        if ((freqHz - firstTickHz).abs() < 1e-6) {
          // First label: shift right
          labelOffset = Offset(x + 2, height - tickHeight - 15);
        } else if ((freqHz - lastTickHz).abs() < 1e-6) {
          // Last label: shift left
          labelOffset = Offset(x - tp.width - 2, height - tickHeight - 15);
        } else {
          // Centered for all others
          labelOffset = Offset(x - tp.width / 2, height - tickHeight - 15);
        }

        tp.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
