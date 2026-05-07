import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event_model.dart';

class LocalEventRepository {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('coach.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date_time TEXT NOT NULL,
        audio_url TEXT,
        is_reminder_enabled INTEGER NOT NULL,
        reminder_minutes_before INTEGER,
        color_value INTEGER,
        tag TEXT,
        recurrence_type TEXT,
        recurrence_interval INTEGER,
        recurrence_until TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE events ADD COLUMN color_value INTEGER;');
      await db.execute('ALTER TABLE events ADD COLUMN tag TEXT;');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE events ADD COLUMN recurrence_type TEXT;');
      await db.execute('ALTER TABLE events ADD COLUMN recurrence_interval INTEGER;');
      await db.execute('ALTER TABLE events ADD COLUMN recurrence_until TEXT;');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE events ADD COLUMN reminder_minutes_before INTEGER;');
    }
  }

  Future<void> insertEvent(EventModel event) async {
    final db = await database;
    await db.insert('events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EventModel>> getEvents() async {
    final db = await database;
    final result = await db.query('events', orderBy: 'date_time ASC');
    return result.map((json) => EventModel.fromMap(json)).toList();
  }

  Future<void> deleteEvent(String id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
