import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';

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

      // Crear usuario
      final user = User(
        username: username,
        email: email,
        password: password, // En producción, usar hash
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
      final user = await DatabaseHelper.instance.getUserByEmail(email);

      if (user == null || user.password != password) {
        return {
          'success': false,
          'message': 'Correo o contraseña incorrectos',
        };
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