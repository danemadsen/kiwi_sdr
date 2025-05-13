part of 'package:kiwi_sdr/kiwi_sdr.dart';

class Waterfall extends StatefulWidget {
  final KiwiSdr sdr;

  const Waterfall({
    super.key,
    required this.sdr,
  });

  @override
  State<Waterfall> createState() => _WaterfallState();
}

class _WaterfallState extends State<Waterfall> {
  double _frequency = 0;

  @override
  void initState() {
    super.initState();
    _frequency = widget.sdr.frequency ?? 0;
  }

  void _updateFrequency(double frequency) {
    setState(() {
      _frequency = frequency;
    });

    widget.sdr.setFrequency(frequency / 1000);
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _buildDisplay(),
    ],
  );

  Widget _buildDisplay() => Column(
    children: [
      FrequencyScaleBar(sdr: widget.sdr),
      Flexible(child: CustomPaint(
        painter: WaterfallPainter(sdr: widget.sdr),
        size: Size.infinite,
      ))
    ]
  );
}