part of 'package:flutter_sdr/flutter_sdr.dart';

enum Modulation {
  am(-4900, 4900),
  amn(-2500, 2500),
  amw(-6000, 6000),
  sam(-4900, 4900),
  sal(-4900, 0),
  sau(0, 4900),
  sas(-4900, 4900),
  qam(-4900, 4900),
  drm(-5000, 5000),
  lsb(-2700, -300),
  lsn(-2400, -300),
  usb(300, 2700),
  usn(300, 2400),
  cw(300, 700),
  cwn(470, 530),
  nbfm(-6000, 6000),
  nnfm(-3000, 3000),
  iq(-5000, 5000);

  final int lc;
  final int hc;

  const Modulation(this.lc, this.hc);

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
}