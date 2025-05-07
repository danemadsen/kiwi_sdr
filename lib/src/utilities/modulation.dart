part of 'package:flutter_sdr/flutter_sdr.dart';

enum Modulation {
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

extension SdrModeExtension on Modulation {
  int get lc {
    switch (this) {
      case Modulation.am:
        return -4900;
      case Modulation.amn:
        return -2500;
      case Modulation.amw:
        return -6000;
      case Modulation.sam:
        return -4900;
      case Modulation.sal:
        return -4900;
      case Modulation.sau:
        return 0;
      case Modulation.sas:
        return -4900;
      case Modulation.qam:
        return -4900;
      case Modulation.drm:
        return -5000;
      case Modulation.lsb:
        return -2700;
      case Modulation.lsn:
        return -2400;
      case Modulation.usb:
        return 300;
      case Modulation.usn:
        return 300;
      case Modulation.cw:
        return 300;
      case Modulation.cwn:
        return 470;
      case Modulation.nbfm:
        return -6000;
      case Modulation.nnfm:
        return -3000;
      case Modulation.iq:
        return -5000;
    }
  }

  int get hc {
    switch (this) {
      case Modulation.am:
        return 4900;
      case Modulation.amn:
        return 2500;
      case Modulation.amw:
        return 6000;
      case Modulation.sam:
        return 4900;
      case Modulation.sal:
        return 0;
      case Modulation.sau:
        return 4900;
      case Modulation.sas:
        return 4900;
      case Modulation.qam:
        return 4900;
      case Modulation.drm:
        return 5000;
      case Modulation.lsb:
        return -300;
      case Modulation.lsn:
        return -300;
      case Modulation.usb:
        return 2700;
      case Modulation.usn:
        return 2400;
      case Modulation.cw:
        return 700;
      case Modulation.cwn:
        return 530;
      case Modulation.nbfm:
        return 6000;
      case Modulation.nnfm:
        return 3000;
      case Modulation.iq:
        return 5000;
    }
  }
}