import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';
import 'password_hasher.dart';

// El hash tarda unos cientos de milisegundos a propósito (así se frena la
// fuerza bruta). Se calcula en otro isolate con compute() para no congelar
// la interfaz mientras tanto.
bool _verifyPassword((String, String) args) =>
    PasswordHasher.verify(args.$1, args.$2);

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Inicializar y cargar usuario actual
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('currentUserId');
    if (userId != null) {
      _currentUser = await DatabaseHelper.instance.getUserById(userId);
    }
  }

  // Registro de usuario
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Verificar si el email ya existe
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'Este correo ya está registrado',
        };
      }

      // Validaciones
      if (username.length < 3) {
        return {
          'success': false,
          'message': 'El nombre de usuario debe tener al menos 3 caracteres',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'La contraseña debe tener al menos 6 caracteres',
        };
      }

      if (!email.contains('@')) {
        return {
          'success': false,
          'message': 'Ingresa un correo válido',
        };
      }

      // Crear usuario. Solo se guarda el hash, nunca la contraseña.
      final user = User(
        username: username,
        email: email,
        password: await compute(PasswordHasher.hash, password),
      );

      _currentUser = await DatabaseHelper.instance.createUser(user);

      // Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentUserId', _currentUser!.id!);

      return {
        'success': true,
        'message': 'Usuario registrado exitosamente',
        'user': _currentUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al registrar usuario: $e',
      };
    }
  }

  // Inicio de sesión
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      var user = await DatabaseHelper.instance.getUserByEmail(email);

      if (user == null || !await _passwordMatches(password, user.password)) {
        return {
          'success': false,
          'message': 'Correo o contraseña incorrectos',
        };
      }

      // Cuentas creadas antes de usar hashes: al iniciar sesión con la
      // contraseña correcta, se reemplaza el texto plano por su hash.
      if (!PasswordHasher.isHash(user.password)) {
        user = user.copyWith(
          password: await compute(PasswordHasher.hash, password),
        );
        await DatabaseHelper.instance.updateUser(user);
      }

      _currentUser = user;

      // Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentUserId', user.id!);

      return {
        'success': true,
        'message': 'Inicio de sesión exitoso',
        'user': _currentUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al iniciar sesión: $e',
      };
    }
  }

  // Compara la contraseña escrita con la guardada, sea hash o texto plano
  // heredado de versiones anteriores.
  Future<bool> _passwordMatches(String password, String stored) async {
    if (PasswordHasher.isHash(stored)) {
      return compute(_verifyPassword, (password, stored));
    }
    return PasswordHasher.constantTimeEquals(
      password.codeUnits,
      stored.codeUnits,
    );
  }

  // Cerrar sesión
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
  }

  // Verificar si hay sesión activa
  bool isLoggedIn() {
    return _currentUser != null;
  }

  // Actualizar perfil
  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? bio,
  }) async {
    try {
      if (_currentUser == null) {
        return {
          'success': false,
          'message': 'No hay sesión activa',
        };
      }

      final updatedUser = _currentUser!.copyWith(
        username: username ?? _currentUser!.username,
        bio: bio ?? _currentUser!.bio,
      );

      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;

      return {
        'success': true,
        'message': 'Perfil actualizado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al actualizar perfil: $e',
      };
    }
  }
}