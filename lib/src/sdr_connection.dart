part of 'package:flutter_sdr/flutter_sdr.dart';

abstract class SdrConnection {
  void start();

  void stop();

  void close();
}