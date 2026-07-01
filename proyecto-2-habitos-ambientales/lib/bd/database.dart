import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'reto_verde.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabla de usuarios
        await db.execute('''
          CREATE TABLE users (
            user TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            password TEXT NOT NULL,
            image_path TEXT
          )
        ''');

        // --- NUEVA TABLA DE TAREAS ---
        // SQLite no tiene "booleanos" (true/false), usamos INTEGER (0 o 1)
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // --- MÉTODOS DE USUARIOS (Se quedan igual) ---
  Future<Map<String, dynamic>?> loginUser(String user, String password) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'user = ? AND password = ?', whereArgs: [user, password]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUserImage(String username, String imagePath) async {
    final db = await instance.database;
    return await db.update('users', {'image_path': imagePath}, where: 'user = ?', whereArgs: [username]);
  }

  Future<int> updateUserProfile(String oldUsername, String newUsername, String newName, String newPassword) async {
    final db = await instance.database;
    return await db.update('users', {'user': newUsername, 'name': newName, 'password': newPassword}, where: 'user = ?', whereArgs: [oldUsername]);
  }

  // --- NUEVOS MÉTODOS PARA LAS TAREAS (CRUD COMPLETO) ---

  // 1. Crear tarea
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await instance.database;
    return await db.insert('tasks', task);
  }

  // 2. Leer tareas de un usuario específico
  Future<List<Map<String, dynamic>>> getUserTasks(String username) async {
    final db = await instance.database;
    return await db.query('tasks', where: 'username = ?', whereArgs: [username]);
  }

  // 3. Actualizar estado (Completada o no)
  Future<int> updateTaskStatus(int id, int isCompleted) async {
    final db = await instance.database;
    return await db.update('tasks', {'is_completed': isCompleted}, where: 'id = ?', whereArgs: [id]);
  }

  // 4. Actualizar textos (Editar tarea)
  Future<int> updateTask(int id, String title, String description) async {
    final db = await instance.database;
    return await db.update('tasks', {'title': title, 'description': description}, where: 'id = ?', whereArgs: [id]);
  }

  // 5. Eliminar tarea
  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}