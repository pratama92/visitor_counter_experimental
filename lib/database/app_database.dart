import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._privateConstructor();

  static final AppDatabase instance = AppDatabase._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'playground_counter.db');

    return openDatabase(
      path,
      version: 3,

      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE visits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            counter INTEGER NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            session_cost INTEGER NOT NULL,
            is_invalid INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await database.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            session_time REAL NOT NULL,
            session_cost INTEGER NOT NULL
          )
        ''');

        await database.insert('settings', {
          'id': 1,
          'title': 'Playground Counter',
          'session_time': 1.0,
          'session_cost': 10000,
        });

        await database.execute('''
          CREATE TABLE visitors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await database.execute('''
          CREATE TABLE face_samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            visitor_id INTEGER NOT NULL,
            embedding TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (visitor_id)
              REFERENCES visitors (id)
              ON DELETE CASCADE
          )
        ''');

        await database.execute('''
          CREATE TABLE visit_visitors (
            visit_id INTEGER NOT NULL,
            visitor_id INTEGER NOT NULL,
            PRIMARY KEY (visit_id, visitor_id),
            FOREIGN KEY (visit_id)
              REFERENCES visits (id)
              ON DELETE CASCADE,
            FOREIGN KEY (visitor_id)
              REFERENCES visitors (id)
              ON DELETE CASCADE
          )
        ''');
      },

      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE visits ADD COLUMN session_cost INTEGER NOT NULL DEFAULT 10000',
          );
        }

        if (oldVersion < 3) {
          await database.execute('''
            CREATE TABLE visitors (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          await database.execute('''
            CREATE TABLE face_samples (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              visitor_id INTEGER NOT NULL,
              embedding TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (visitor_id)
                REFERENCES visitors (id)
                ON DELETE CASCADE
            )
          ''');

          await database.execute('''
            CREATE TABLE visit_visitors (
              visit_id INTEGER NOT NULL,
              visitor_id INTEGER NOT NULL,
              PRIMARY KEY (visit_id, visitor_id),
              FOREIGN KEY (visit_id)
                REFERENCES visits (id)
                ON DELETE CASCADE,
              FOREIGN KEY (visitor_id)
                REFERENCES visitors (id)
                ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Future<int> insertVisit({
    required int counter,
    required DateTime startTime,
    required DateTime endTime,
    required int sessionCost,
  }) async {
    final db = await database;

    return db.insert('visits', {
      'counter': counter,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'session_cost': sessionCost,
      'is_invalid': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getVisits() async {
    final db = await database;

    return db.query('visits', orderBy: 'start_time DESC');
  }

  Future<int> updateVisit(int id, Map<String, dynamic> values) async {
    final db = await database;

    return db.update('visits', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;

    final rows = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final visits = await db.query('visits');
    final settings = await db.query('settings');

    return {
      'backup_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'settings': settings,
      'visits': visits,
    };
  }

  Future<void> saveSettings({
    required String title,
    required double sessionTime,
    required int sessionCost,
  }) async {
    final db = await database;

    await db.insert('settings', {
      'id': 1,
      'title': title,
      'session_time': sessionTime,
      'session_cost': sessionCost,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
