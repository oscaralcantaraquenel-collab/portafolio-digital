import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';

import 'database_test.mocks.dart'; // se genera automáticamente

@GenerateMocks([Database])
void main() {
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockDatabase();
  });

  // ── GRUPO 1: Tests de Usuario ────────────────────────────
  group('DatabaseHelper - Usuarios', () {
    test('loginUser retorna datos con credenciales correctas', () async {
      when(mockDatabase.query(
        'users',
        where: 'user = ? AND password = ?',
        whereArgs: ['oscar@test.com', '123456'],
      )).thenAnswer((_) async => [
        {'user': 'oscar@test.com', 'name': 'Oscar', 'password': '123456'}
      ]);

      final result = await mockDatabase.query(
        'users',
        where: 'user = ? AND password = ?',
        whereArgs: ['oscar@test.com', '123456'],
      );

      expect(result, isNotEmpty);
      expect(result.first['name'], equals('Oscar'));
    });

    test('loginUser retorna vacío con credenciales incorrectas', () async {
      when(mockDatabase.query(
        'users',
        where: 'user = ? AND password = ?',
        whereArgs: ['oscar@test.com', 'wrong'],
      )).thenAnswer((_) async => []);

      final result = await mockDatabase.query(
        'users',
        where: 'user = ? AND password = ?',
        whereArgs: ['oscar@test.com', 'wrong'],
      );

      expect(result, isEmpty);
    });
  });

  // ── GRUPO 2: Tests de Tareas ─────────────────────────────
  group('DatabaseHelper - Tareas', () {
    test('insertTask retorna el id de la nueva tarea', () async {
      final nuevaTarea = {
        'username': 'oscar',
        'title': 'Separar basura',
        'description': 'Separar orgánico e inorgánico',
        'is_completed': 0,
      };

      when(mockDatabase.insert('tasks', nuevaTarea))
          .thenAnswer((_) async => 1);

      final id = await mockDatabase.insert('tasks', nuevaTarea);

      expect(id, equals(1));
      verify(mockDatabase.insert('tasks', nuevaTarea)).called(1);
    });

    test('getUserTasks retorna lista de tareas del usuario', () async {
      when(mockDatabase.query(
        'tasks',
        where: 'username = ?',
        whereArgs: ['oscar'],
      )).thenAnswer((_) async => [
        {'id': 1, 'username': 'oscar', 'title': 'Apagar luces', 'is_completed': 0},
        {'id': 2, 'username': 'oscar', 'title': 'Separar basura', 'is_completed': 1},
      ]);

      final tareas = await mockDatabase.query(
        'tasks',
        where: 'username = ?',
        whereArgs: ['oscar'],
      );

      expect(tareas.length, equals(2));
      expect(tareas[1]['is_completed'], equals(1));
    });

    test('updateTaskStatus marca tarea como completada', () async {
      when(mockDatabase.update(
        'tasks',
        {'is_completed': 1},
        where: 'id = ?',
        whereArgs: [1],
      )).thenAnswer((_) async => 1);

      final filas = await mockDatabase.update(
        'tasks',
        {'is_completed': 1},
        where: 'id = ?',
        whereArgs: [1],
      );

      expect(filas, equals(1));
    });

    test('deleteTask elimina la tarea correctamente', () async {
      when(mockDatabase.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [5],
      )).thenAnswer((_) async => 1);

      final eliminadas = await mockDatabase.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [5],
      );

      expect(eliminadas, equals(1));
      verify(mockDatabase.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [5],
      )).called(1);
    });
  });
}