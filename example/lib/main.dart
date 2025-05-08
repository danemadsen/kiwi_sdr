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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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
    _connection.waterfallStream.listen((samples) {
      print(samples.sublist(0, 10));
      setState(() {
        _samplesBuffer.insert(0, samples);
        if (_samplesBuffer.length > 2040) {
          _samplesBuffer.removeLast();
        }
      });
    });
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
