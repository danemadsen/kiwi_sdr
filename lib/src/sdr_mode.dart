part of 'package:flutter_sdr/flutter_sdr.dart';

enum SdrMode {
  am,
  amn,
  amw,
  sam,
  sal,
  sau,
  sas,
  qam,
  drm,
  lsb,
  lsn,
  usb,
  usn,
  cw,
  cwn,
  nbfm,
  nnfm,
  iq
}

extension SdrModeExtension on SdrMode {
  int get lc {
    switch (this) {
      case SdrMode.am:
        return -4900;
      case SdrMode.amn:
        return -2500;
      case SdrMode.amw:
        return -6000;
      case SdrMode.sam:
        return -4900;
      case SdrMode.sal:
        return -4900;
      case SdrMode.sau:
        return 0;
      case SdrMode.sas:
        return -4900;
      case SdrMode.qam:
        return -4900;
      case SdrMode.drm:
        return -5000;
      case SdrMode.lsb:
        return -2700;
      case SdrMode.lsn:
        return -2400;
      case SdrMode.usb:
        return 300;
      case SdrMode.usn:
        return 300;
      case SdrMode.cw:
        return 300;
      case SdrMode.cwn:
        return 470;
      case SdrMode.nbfm:
        return -6000;
      case SdrMode.nnfm:
        return -3000;
      case SdrMode.iq:
        return -5000;
    }
  }

  int get hc {
    switch (this) {
      case SdrMode.am:
        return 4900;
      case SdrMode.amn:
        return 2500;
      case SdrMode.amw:
        return 6000;
      case SdrMode.sam:
        return 4900;
      case SdrMode.sal:
        return 0;
      case SdrMode.sau:
        return 4900;
      case SdrMode.sas:
        return 4900;
      case SdrMode.qam:
        return 4900;
      case SdrMode.drm:
        return 5000;
      case SdrMode.lsb:
        return -300;
      case SdrMode.lsn:
        return -300;
      case SdrMode.usb:
        return 2700;
      case SdrMode.usn:
        return 2400;
      case SdrMode.cw:
        return 700;
      case SdrMode.cwn:
        return 530;
      case SdrMode.nbfm:
        return 6000;
      case SdrMode.nnfm:
        return 3000;
      case SdrMode.iq:
        return 5000;
    }
  }
}