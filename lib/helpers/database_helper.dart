import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static const _databaseName = "tasks_database.db";
  static const _databaseVersion = 1;

  static const table = 'tasks';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDescription = 'description';
  static const columnPriority = 'priority';
  static const columnDeadline = 'deadline';
  static const columnIsComplete = 'isComplete';

  // Singleton pattern to create a single instance of the database helper.
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Open the database and create the table if it doesn't exist.
  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnTitle TEXT NOT NULL,
        $columnDescription TEXT,
        $columnPriority TEXT NOT NULL,
        $columnDeadline TEXT,
        $columnIsComplete INTEGER NOT NULL
      )
    ''');
  }

  // Insert a task into the database.
  Future<int> insert(Task task) async {
    Database db = await instance.database;
    return await db.insert(table, task.toMap());
  }

  // Get all tasks from the database.
  Future<List<Task>> getAllTasks() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Update a task.
  Future<int> update(Task task) async {
    Database db = await instance.database;
    return await db.update(
      table,
      task.toMap(),
      where: '$columnId = ?',
      whereArgs: [task.id],
    );
  }

  // Delete a task.
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  getTasks() {}
}
