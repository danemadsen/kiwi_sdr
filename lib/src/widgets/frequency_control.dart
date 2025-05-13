part of 'package:kiwi_sdr/kiwi_sdr.dart';

class FrequencyControl extends StatefulWidget {
  final KiwiSdr sdr;

  const FrequencyControl({
    super.key,
    required this.sdr,
  });

  @override
  State<FrequencyControl> createState() => _FrequencyControl();
}

class _FrequencyControl extends State<FrequencyControl> {
  double _frequency = 0;

  @override
  void initState() {
    super.initState();
    _frequency = widget.sdr.frequency ?? 0;
  }

  void _updateFrequency(double frequencyHz) {
    setState(() {
      _frequency = frequencyHz;
    });

    widget.sdr.setFrequency(frequencyHz / 1000); // convert to kHz
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ListenableBuilder(
      listenable: widget.sdr, 
      builder: _listenableBuilder
    ),
  );

  Widget _listenableBuilder(BuildContext context, Widget? child) => LayoutBuilder(
    builder: _layoutBuilder
  );

  Widget _layoutBuilder(BuildContext context, BoxConstraints constraints) {
    final minFreq = (widget.sdr.centerFrequency ?? 15e6) - (widget.sdr.maxFrequency ?? 30e6) / 2;
    final maxFreq = (widget.sdr.centerFrequency ?? 15e6) + (widget.sdr.maxFrequency ?? 30e6) / 2;

    final double width = constraints.maxWidth;
    final double positionX = ((_frequency - minFreq) / (maxFreq - minFreq)) * width;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        final dx = details.localPosition.dx.clamp(0.0, width);
        final freq = minFreq + (dx / width) * (maxFreq - minFreq);
        _updateFrequency(freq);
      },
      child: CustomPaint(
        painter: _DraggerPainter(positionX: positionX),
      ),
    );
  }
}

class _DraggerPainter extends CustomPainter {
  final double positionX;

  _DraggerPainter({required this.positionX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(positionX, 0),
      Offset(positionX, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DraggerPainter oldDelegate) {
    return oldDelegate.positionX != positionX;
  }
}
