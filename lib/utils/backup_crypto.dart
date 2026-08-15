import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class BackupCrypto {
  static const associatedData = 'GaleriProBackup:v1';

  static Map<String, Object> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
  }) {
    _validateInputs(key, nonce);
    final cipher = _cipher(true, key, nonce);
    final ciphertext = cipher.process(plaintext);

    return {
      'versiyon': 1,
      'algoritma': 'AES-256-GCM',
      'nonce': base64Encode(nonce),
      'veri': base64Encode(ciphertext),
    };
  }

  static Uint8List decrypt({
    required Map<String, dynamic> envelope,
    required Uint8List key,
  }) {
    if (envelope['versiyon'] != 1 || envelope['algoritma'] != 'AES-256-GCM') {
      throw const FormatException('Desteklenmeyen yedek formati.');
    }

    final nonce = base64Decode(envelope['nonce'] as String);
    final ciphertext = base64Decode(envelope['veri'] as String);
    _validateInputs(key, nonce);
    return _cipher(false, key, nonce).process(ciphertext);
  }

  static GCMBlockCipher _cipher(
    bool forEncryption,
    Uint8List key,
    Uint8List nonce,
  ) {
    return GCMBlockCipher(AESEngine())..init(
      forEncryption,
      AEADParameters(
        KeyParameter(key),
        128,
        nonce,
        Uint8List.fromList(utf8.encode(associatedData)),
      ),
    );
  }

  static void _validateInputs(Uint8List key, Uint8List nonce) {
    if (key.length != 32) {
      throw const FormatException('AES-256 anahtari 32 bayt olmali.');
    }
    if (nonce.length != 12) {
      throw const FormatException('AES-GCM nonce degeri 12 bayt olmali.');
    }
  }
}
