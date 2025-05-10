# kiwi_sdr

`kiwi_sdr` is a Dart package for interacting with KiwiSDR instances on the web. 
It provides a simple API to access and control KiwiSDR devices, making it easier 
to integrate them into your Dart applications.

## Features

- Listen to audio streams from KiwiSDR devices
- View radio spectrum data as a waterfall
- Control frequency and gain settings

## Getting started

To use the `kiwi_sdr` package, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  kiwi_sdr: ^0.0.1
```

Then, import the package in your Dart code:

```dart
import 'package:kiwi_sdr/kiwi_sdr.dart';
```

## Usage

Here's a simple example of how to use the `kiwi_sdr` package to connect to a KiwiSDR device and listen to its audio stream:

```dart
await KiwiSDR.connect('http://22274.proxy.kiwisdr.com:8073/');
```
