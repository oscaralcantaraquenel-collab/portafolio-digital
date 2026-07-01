import 'package:flutter_test/flutter_test.dart';

// Lógica pura de validación extraída de PantallaLogin
String? validarCamposLogin(String correo, String password) {
  if (correo.isEmpty || password.isEmpty) {
    return 'Por favor llena todos los campos';
  }
  if (!correo.contains('@')) {
    return 'El formato del correo no es válido.';
  }
  if (password.length < 6) {
    return 'La contraseña es muy débil (mínimo 6 caracteres).';
  }
  return null; // null = todo válido
}

// Lógica pura de validación extraída de PantallaRegistro
String? validarRegistro(String nombre, String correo, String password) {
  if (nombre.isEmpty || correo.isEmpty || password.isEmpty) {
    return 'Por favor llena todos los campos';
  }
  if (!correo.contains('@')) {
    return 'El formato del correo no es válido.';
  }
  if (password.length < 6) {
    return 'La contraseña es muy débil (mínimo 6 caracteres).';
  }
  return null;
}

// Lógica del código de clase de PantallaDocente
bool validarCodigoClase(String codigo) {
  return codigo.startsWith('VERDE-') && codigo.length == 10;
}

void main() {
  // ── GRUPO 1: Tests de Login ──────────────────────────────
  group('Validaciones de PantallaLogin', () {
    test('retorna error si el correo está vacío', () {
      final resultado = validarCamposLogin('', '123456');
      expect(resultado, equals('Por favor llena todos los campos'));
    });

    test('retorna error si la contraseña está vacía', () {
      final resultado = validarCamposLogin('oscar@test.com', '');
      expect(resultado, equals('Por favor llena todos los campos'));
    });

    test('retorna error si ambos campos están vacíos', () {
      final resultado = validarCamposLogin('', '');
      expect(resultado, equals('Por favor llena todos los campos'));
    });

    test('retorna error si el correo no tiene @', () {
      final resultado = validarCamposLogin('oscarsinformato', '123456');
      expect(resultado, equals('El formato del correo no es válido.'));
    });

    test('retorna error si la contraseña tiene menos de 6 caracteres', () {
      final resultado = validarCamposLogin('oscar@test.com', '123');
      expect(resultado, equals('La contraseña es muy débil (mínimo 6 caracteres).'));
    });

    test('retorna null cuando correo y contraseña son válidos', () {
      final resultado = validarCamposLogin('oscar@test.com', 'password123');
      expect(resultado, isNull);
    });
  });

  // ── GRUPO 2: Tests de Registro ───────────────────────────
  group('Validaciones de PantallaRegistro', () {
    test('retorna error si el nombre está vacío', () {
      final resultado = validarRegistro('', 'oscar@test.com', '123456');
      expect(resultado, equals('Por favor llena todos los campos'));
    });

    test('retorna error si el correo no tiene @', () {
      final resultado = validarRegistro('Oscar', 'oscarsinformato', '123456');
      expect(resultado, equals('El formato del correo no es válido.'));
    });

    test('retorna error si la contraseña es muy corta', () {
      final resultado = validarRegistro('Oscar', 'oscar@test.com', '123');
      expect(resultado, equals('La contraseña es muy débil (mínimo 6 caracteres).'));
    });

    test('retorna null cuando todos los datos son válidos', () {
      final resultado = validarRegistro('Oscar', 'oscar@test.com', 'password123');
      expect(resultado, isNull);
    });
  });

  // ── GRUPO 3: Tests del código de clase (PantallaDocente) ─
  group('Validación de código de clase', () {
    test('código VERDE-1234 es válido', () {
      expect(validarCodigoClase('VERDE-1234'), isTrue);
    });

    test('código sin prefijo VERDE- es inválido', () {
      expect(validarCodigoClase('1234-VERDE'), isFalse);
    });

    test('código vacío es inválido', () {
      expect(validarCodigoClase(''), isFalse);
    });

    test('código corto es inválido', () {
      expect(validarCodigoClase('VERDE-12'), isFalse);
    });
  });
}