import 'package:flutter/material.dart';
import 'package:kiwi_sdr/kiwi_sdr.dart';

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
      debugShowCheckedModeBanner: false,
    );
  }
}

class WaterfallWidget extends StatefulWidget {
  const WaterfallWidget({super.key});

  @override
  State<WaterfallWidget> createState() => _WaterfallWidgetState();
}

class _WaterfallWidgetState extends State<WaterfallWidget> {
  KiwiSdr? _connection;

  @override
  void initState() {
    super.initState();
    establishConnection();
  }

  Future<void> establishConnection() async {
    _connection = await KiwiSdr.connect('http://vk4een.proxy.kiwisdr.com:8073/');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_connection == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            FrequencyScaleBar(sdr: _connection!),
            Flexible(
              child: CustomPaint(
                painter: WaterfallPainter(sdr: _connection!),
                size: Size.infinite
              )
            )
          ]
        ),
        FrequencyControl(sdr: _connection!),
      ],
    );
  }

  @override
  void dispose() {
    _connection!.close();
    super.dispose();
  }
}
