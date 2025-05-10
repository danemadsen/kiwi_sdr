part of 'package:kiwi_sdr/kiwi_sdr.dart';

/// An enumaration representing various modulation types used in KiwiSDR.
enum Modulation {
  /// Amplitude Modulation (AM)
  am(-4900, 4900),

  /// Amplitude Modulation with negative frequency range
  amn(-2500, 2500),

  /// Amplitude Modulation with wide frequency range
  amw(-6000, 6000),

  /// Single Sideband Amplitude Modulation (SAM)
  sam(-4900, 4900),

  /// Single Sideband Amplitude Modulation with negative frequency range
  sal(-4900, 0),

  /// Single Sideband Amplitude Modulation with upper sideband
  sau(0, 4900),

  /// Single Sideband Amplitude Modulation with suppressed carrier
  sas(-4900, 4900),

  /// Quadrature Amplitude Modulation (QAM)
  qam(-4900, 4900),

  /// Digital Radio Mondiale (DRM)
  drm(-5000, 5000),

  /// Lower Sideband Amplitude Modulation (LSB)
  lsb(-2700, -300),

  /// Lower Sideband Amplitude Modulation with negative frequency range
  lsn(-2400, -300),

  /// Upper Sideband Amplitude Modulation (USB)
  usb(300, 2700),

  /// Upper Sideband Amplitude Modulation with negative frequency range
  usn(300, 2400),

  /// Continuous Wave (CW)
  cw(300, 700),

  /// Continuous Wave with negative frequency range
  cwn(470, 530),

  /// Narrowband Frequency Modulation (NBFM)
  nbfm(-6000, 6000),

  /// Narrowband Frequency Modulation with negative frequency range
  nnfm(-3000, 3000),

  /// IQ data modulation
  iq(-5000, 5000);

  /// The lower cutoff frequency for the modulation type.
  final int lc;

  /// The higher cutoff frequency for the modulation type.
  final int hc;

  const Modulation(this.lc, this.hc);

  /// Creates a [Modulation] instance from a string representation.
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
