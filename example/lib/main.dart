import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sdr/flutter_sdr.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WaterfallWidget(),
    );
  }
}

class WaterfallWidget extends StatefulWidget {
  const WaterfallWidget({super.key});

  @override
  State<WaterfallWidget> createState() => _WaterfallWidgetState();
}

class _WaterfallWidgetState extends State<WaterfallWidget> {
  final List<Uint8List> _samplesBuffer = [];
  late KiwiSdrConnection _connection;
  int min = 255;
  int max = 0;

  @override
  void initState() {
    super.initState();
    initilizeBuffer();
    establishConnection();
  }

  void initilizeBuffer() {
    // Buffer should have 2040 rows and 2040 columns
    for (int i = 0; i < 2040; i++) {
      _samplesBuffer.add(Uint8List(2040));
    }
  }

  Future<void> establishConnection() async {
    _connection = await KiwiSdrConnection.connect('http://22274.proxy.kiwisdr.com:8073/');
    _connection.start();
    _connection.waterfallStream.listen((samples) => setState(() {
      final newMin = samples.reduce((a, b) => a < b ? a : b);
      min = newMin < min ? newMin : min;
      final newMax = samples.reduce((a, b) => a > b ? a : b);
      max = newMax > max ? newMax : max;
      // print min and max values
      print('min: $min');
      print('max: $max');
      _samplesBuffer.insert(0, samples);
      if (_samplesBuffer.length > 2040) {
        _samplesBuffer.removeLast();
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaterfallPainter(samplesList: List<Uint8List>.from(_samplesBuffer)),
      size: Size.infinite,
    );
  }

  @override
  void dispose() {
    _connection.close();
    super.dispose();
  }
}
