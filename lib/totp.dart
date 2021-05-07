
import 'otp.dart';
import 'util.dart';

class TOTP extends OTP {
  ///
  /// @param {secret}
  /// @type {String}
  /// @desc random base32-encoded key to generate OTP.
  ///
  /// @param {interval}
  /// @type {int}
  /// @desc the time interval in seconds for OTP.
  /// This defaults to 30.
  ///
  /// @return {TOTP}
  ///
  int _interval=30;
  TOTP(String secret, [int interval = 30]) : super(secret) {
    this._interval = interval;
  }

  ///
  /// Generate the OTP with current time.
  ///
  /// @return {OTP}
  ///
  /// @example
  /// TOTP totp = dotp.TOTP('BASE32ENCODEDSECRET');
  /// totp.now(); // => 432143
  ///
  String now() {
    DateTime _now = DateTime.now();
    int _formatTime = Util.timeFormat(_now, this._interval);

    return super.generateOTP(_formatTime);
  }
}
