import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureFieldCodec {
  static const String _prefix = 'enc:v1';
  static const String _keyName = 'local_database_field_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final AesGcm _cipher = AesGcm.with256bits();

  static SecretKey? _cachedKey;

  static bool isEncrypted(Object? value) {
    return value is String && value.startsWith('$_prefix:');
  }

  static Future<String?> encryptNullable(Object? value) async {
    if (value == null) {
      return null;
    }

    final text = value.toString();
    if (text.isEmpty || isEncrypted(text)) {
      return text;
    }

    final key = await _getKey();
    final secretBox = await _cipher.encrypt(
      utf8.encode(text),
      secretKey: key,
    );

    return [
      _prefix,
      base64UrlEncode(secretBox.nonce),
      base64UrlEncode(secretBox.cipherText),
      base64UrlEncode(secretBox.mac.bytes),
    ].join(':');
  }

  static Future<String?> decryptNullable(Object? value) async {
    if (value == null) {
      return null;
    }

    final text = value.toString();
    if (text.isEmpty || !isEncrypted(text)) {
      return text;
    }

    try {
      final parts = text.split(':');
      if (parts.length != 5) {
        return text;
      }

      final secretBox = SecretBox(
        base64Url.decode(parts[3]),
        nonce: base64Url.decode(parts[2]),
        mac: Mac(base64Url.decode(parts[4])),
      );

      final decrypted = await _cipher.decrypt(
        secretBox,
        secretKey: await _getKey(),
      );

      return utf8.decode(decrypted);
    } catch (_) {
      return text;
    }
  }

  static Future<SecretKey> _getKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    final storedKey = await _storage.read(key: _keyName);
    if (storedKey != null && storedKey.isNotEmpty) {
      _cachedKey = SecretKey(base64Url.decode(storedKey));
      return _cachedKey!;
    }

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _storage.write(
      key: _keyName,
      value: base64UrlEncode(keyBytes),
    );

    _cachedKey = SecretKey(keyBytes);
    return _cachedKey!;
  }
}
