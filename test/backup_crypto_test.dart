import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oto_galeri_app/utils/backup_crypto.dart';
import 'package:pointycastle/export.dart';

void main() {
  final key = Uint8List.fromList(List<int>.generate(32, (index) => index));
  final nonce = Uint8List.fromList(List<int>.generate(12, (index) => index));

  test('AES-GCM yedegi sifreler ve geri acar', () {
    final plaintext = Uint8List.fromList(utf8.encode('{"plaka":"34 TEST 34"}'));

    final envelope = BackupCrypto.encrypt(
      plaintext: plaintext,
      key: key,
      nonce: nonce,
    );
    final decrypted = BackupCrypto.decrypt(envelope: envelope, key: key);

    expect(decrypted, plaintext);
    expect(envelope['veri'], isNot(contains('34 TEST 34')));
  });

  test('kurcalanmis AES-GCM yedegini reddeder', () {
    final envelope = BackupCrypto.encrypt(
      plaintext: Uint8List.fromList(utf8.encode('hassas veri')),
      key: key,
      nonce: nonce,
    );
    final ciphertext = base64Decode(envelope['veri']! as String);
    ciphertext[0] ^= 1;
    envelope['veri'] = base64Encode(ciphertext);

    expect(
      () => BackupCrypto.decrypt(envelope: envelope, key: key),
      throwsA(isA<InvalidCipherTextException>()),
    );
  });
}
