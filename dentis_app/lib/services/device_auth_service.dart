import 'package:local_auth/local_auth.dart';

class DeviceAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para entrar a SmartTooth',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
