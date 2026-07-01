import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reto_verde/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de integración - PantallaLogin', () {

    testWidgets('Muestra error si los campos están vacíos', (tester) async {
      app.main();
      await tester.pump(); // primer frame
      await tester.pumpAndSettle(const Duration(seconds: 5)); // espera Firebase

      final botonLogin = find.text('Iniciar Sesión');
      expect(botonLogin, findsOneWidget);
      await tester.tap(botonLogin);
      await tester.pumpAndSettle();

      expect(find.text('Por favor llena todos los campos'), findsOneWidget);
    });

    testWidgets('Navega a pantalla de registro', (tester) async {
      app.main();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final botonRegistro = find.text('Regístrate aquí');
      expect(botonRegistro, findsOneWidget);
      await tester.tap(botonRegistro);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Únete a Reto Verde'), findsOneWidget);
    });

    testWidgets('Muestra advertencia al recuperar contraseña sin correo',
            (tester) async {
          app.main();
          await tester.pump();
          await tester.pumpAndSettle(const Duration(seconds: 5));

          final botonOlvide = find.text('¿Olvidaste tu contraseña?');
          expect(botonOlvide, findsOneWidget);
          await tester.tap(botonOlvide);
          await tester.pumpAndSettle();

          expect(
            find.text('Por favor, escribe tu correo arriba para enviarte el enlace.'),
            findsOneWidget,
          );
        });

    testWidgets('Muestra error con credenciales incorrectas', (tester) async {
      app.main();
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).first, 'noexiste@test.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpass');

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(
        find.text('Correo o contraseña incorrectos.'),
        findsOneWidget,
      );
    });

  });
}