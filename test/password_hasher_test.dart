import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sazonix/services/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('verifica la contraseña correcta', () {
      final stored = PasswordHasher.hash('secreta123');
      expect(PasswordHasher.verify('secreta123', stored), isTrue);
    });

    test('rechaza una contraseña incorrecta', () {
      final stored = PasswordHasher.hash('secreta123');
      expect(PasswordHasher.verify('secreta124', stored), isFalse);
    });

    test('no guarda la contraseña en el resultado', () {
      final stored = PasswordHasher.hash('secreta123');
      expect(stored.contains('secreta123'), isFalse);
      expect(stored.startsWith(r'pbkdf2_sha256$100000$'), isTrue);
    });

    test('usa una sal distinta en cada hash', () {
      expect(
        PasswordHasher.hash('secreta123'),
        isNot(PasswordHasher.hash('secreta123')),
      );
    });

    test('distingue un hash de una contraseña heredada en texto plano', () {
      expect(PasswordHasher.isHash(PasswordHasher.hash('abc123')), isTrue);
      expect(PasswordHasher.isHash('abc123'), isFalse);
      expect(PasswordHasher.verify('abc123', 'abc123'), isFalse);
    });

    test('rechaza hashes mal formados sin lanzar excepciones', () {
      expect(PasswordHasher.verify('x', r'pbkdf2_sha256$abc$$'), isFalse);
      expect(PasswordHasher.verify('x', r'pbkdf2_sha256$10$%%%$%%%'), isFalse);
    });

    // Vector de prueba publicado para PBKDF2-HMAC-SHA256
    // (contraseña "password", sal "salt", 1 iteración, 32 bytes).
    test('coincide con el vector de prueba de PBKDF2-HMAC-SHA256', () {
      final salt = base64.encode(utf8.encode('salt'));
      const expectedHex =
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b';
      final expected = base64.encode(
        List<int>.generate(
          32,
          (i) => int.parse(expectedHex.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );
      expect(
        PasswordHasher.verify('password', 'pbkdf2_sha256\$1\$$salt\$$expected'),
        isTrue,
      );
    });
  });
}
