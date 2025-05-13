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
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FrequencyScalePainter(
        maxFrequencyHz: sdr.maxFrequency?.toDouble() ?? 30000000,
      ),
      size: const Size(double.infinity, 40),
    );
  }
}

class _FrequencyScalePainter extends CustomPainter {
  final double maxFrequencyHz;

  _FrequencyScalePainter({required this.maxFrequencyHz});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    final double height = size.height;
    final double width = size.width;

    // Draw background (light gradient for contrast)
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, height),
      [Colors.black, Colors.grey.shade800],
    );
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..shader = gradient,
    );

    final tickSpacing = width / (maxFrequencyHz / 1e6); // 1 MHz per small tick

    for (double mhz = 0; mhz <= maxFrequencyHz / 1e6; mhz++) {
      final x = mhz * tickSpacing;
      final isMajor = mhz % 5 == 0;

      final tickHeight = isMajor ? height * 0.6 : height * 0.3;
      canvas.drawLine(
        Offset(x, height - tickHeight),
        Offset(x, height),
        paint,
      );

      if (isMajor) {
        final label = mhz >= 1 ? '${mhz.toInt()} MHz' : '${(mhz * 1000).toInt()} kHz';
        final textSpan = TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        );
        final tp = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, height - tickHeight - 15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
