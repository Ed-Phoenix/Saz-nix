import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Convierte contraseñas en hashes seguros para guardarlos en la base de datos
/// y verifica una contraseña contra un hash guardado.
///
/// Usa PBKDF2 con HMAC-SHA256: a la contraseña se le agrega una sal aleatoria
/// (distinta para cada usuario) y se aplica la función hash muchas veces. Así:
/// - la contraseña original nunca se guarda;
/// - dos usuarios con la misma contraseña tienen hashes distintos;
/// - probar contraseñas por fuerza bruta es lento.
///
/// El resultado se guarda como texto con este formato:
/// `pbkdf2_sha256$<iteraciones>$<sal en base64>$<hash en base64>`.
/// Guardar el algoritmo y las iteraciones permite subirlas en el futuro sin
/// invalidar los hashes existentes.
class PasswordHasher {
  PasswordHasher._();

  static const String _algorithm = 'pbkdf2_sha256';
  static const int _iterations = 100000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  /// Genera el hash de [password] con una sal aleatoria nueva.
  static String hash(String password) {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
    final key = _pbkdf2(utf8.encode(password), salt, _iterations, _keyLength);
    return [
      _algorithm,
      _iterations.toString(),
      base64.encode(salt),
      base64.encode(key),
    ].join(r'$');
  }

  /// Indica si [stored] es un hash generado por esta clase. Las cuentas
  /// creadas antes de esta versión tienen la contraseña en texto plano.
  static bool isHash(String stored) => stored.startsWith('$_algorithm\$');

  /// Comprueba si [password] corresponde al hash guardado en [stored].
  static bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _algorithm) return false;

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;

    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }

    final actual = _pbkdf2(
      utf8.encode(password),
      salt,
      iterations,
      expected.length,
    );
    return constantTimeEquals(actual, expected);
  }

  /// Compara dos listas de bytes recorriéndolas siempre completas, para que
  /// el tiempo de respuesta no revele cuántos bytes coinciden.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  /// PBKDF2 (RFC 8018) con HMAC-SHA256.
  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    const blockSize = 32; // Bytes que produce SHA-256.
    final blocks = (keyLength / blockSize).ceil();
    final output = BytesBuilder();

    for (var block = 1; block <= blocks; block++) {
      // U1 = HMAC(contraseña, sal || número de bloque en 4 bytes)
      final blockIndex = [
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final result = List<int>.from(u);

      // Un = HMAC(contraseña, Un-1); el bloque es U1 xor U2 xor ... xor Un
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }
      output.add(result);
    }

    return Uint8List.fromList(output.takeBytes().sublist(0, keyLength));
  }
}
