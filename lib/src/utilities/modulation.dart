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
  iq;

  static Modulation fromString(String str) {
    switch (str) {
      case 'am':
        return Modulation.am;
      case 'amn':
        return Modulation.amn;
      case 'amw':
        return Modulation.amw;
      case 'sam':
        return Modulation.sam;
      case 'sal':
        return Modulation.sal;
      case 'sau':
        return Modulation.sau;
      case 'sas':
        return Modulation.sas;
      case 'qam':
        return Modulation.qam;
      case 'drm':
        return Modulation.drm;
      case 'lsb':
        return Modulation.lsb;
      case 'lsn':
        return Modulation.lsn;
      case 'usb':
        return Modulation.usb;
      case 'usn':
        return Modulation.usn;
      case 'cw':
        return Modulation.cw;
      case 'cwn':
        return Modulation.cwn;
      case 'nbfm':
        return Modulation.nbfm;
      case 'nnfm':
        return Modulation.nnfm;
      case 'iq':
        return Modulation.iq;
      default:
        throw ArgumentError('Unknown modulation type: $str');
    }
  }

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