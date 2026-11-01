import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  factory DatabaseHelper() => instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final directory = await getDatabasesPath();
    final path = join(directory, 'campus_challenge.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        targetUnits INTEGER NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createActivities(db);
    await _createNotes(db);

    await db.execute('''
      CREATE TABLE progress_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challengeId INTEGER NOT NULL,
        loggedAt TEXT NOT NULL,
        units INTEGER NOT NULL CHECK(units >= 0),
        note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (challengeId) REFERENCES challenges(id)
          ON DELETE RESTRICT
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE challenges
        ADD COLUMN isCompleted INTEGER NOT NULL DEFAULT 0
      ''');
      await _createActivities(db);
      await _createNotes(db);
    }
  }

  Future<void> _createActivities(Database db) async {
    await db.execute('''
      CREATE TABLE challenge_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challengeId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (challengeId) REFERENCES challenges(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createNotes(Database db) async {
    await db.execute('''
      CREATE TABLE challenge_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challengeId INTEGER NOT NULL,
        note TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (challengeId) REFERENCES challenges(id)
          ON DELETE CASCADE
      )
    ''');
  }

  // Challenge methods

  Future<int> createChallenge(ChallengeRecord challenge) async {
    final db = await database;
    return db.insert('challenges', challenge.toMap());
  }

  Future<List<ChallengeRecord>> getAllChallenges() async {
    final db = await database;
    final rows = await db.query('challenges', orderBy: 'id ASC');
    return rows.map(ChallengeRecord.fromMap).toList();
  }

  Future<ChallengeRecord?> getChallenge(int id) async {
    final db = await database;
    final rows = await db.query(
      'challenges',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isEmpty ? null : ChallengeRecord.fromMap(rows.first);
  }

  Future<int> updateChallenge(ChallengeRecord challenge) async {
    if (challenge.id == null) {
      throw ArgumentError('A challenge ID is required to update it.');
    }

    final db = await database;
    return db.update(
      'challenges',
      challenge.toMap(),
      where: 'id = ?',
      whereArgs: [challenge.id],
    );
  }

  Future<int> setChallengeCompleted(int id, bool completed) async {
    final db = await database;
    return db.update(
      'challenges',
      {'isCompleted': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChallenge(int id) async {
    final db = await database;
    return db.delete(
      'challenges',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Activity methods

  Future<int> addActivity(int challengeId, String title) async {
    final db = await database;
    return db.insert('challenge_activities', {
      'challengeId': challengeId,
      'title': title,
      'isCompleted': 0,
    });
  }

  Future<List<ActivityRecord>> getActivities(int challengeId) async {
    final db = await database;
    final rows = await db.query(
      'challenge_activities',
      where: 'challengeId = ?',
      whereArgs: [challengeId],
      orderBy: 'id ASC',
    );

    return rows.map(ActivityRecord.fromMap).toList();
  }

  Future<int> setActivityCompleted(int id, bool completed) async {
    final db = await database;
    return db.update(
      'challenge_activities',
      {'isCompleted': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteActivity(int id) async {
    final db = await database;
    return db.delete(
      'challenge_activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Note methods

  Future<int> addNote(int challengeId, String note) async {
    final db = await database;
    return db.insert('challenge_notes', {
      'challengeId': challengeId,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<NoteRecord>> getNotes(int challengeId) async {
    final db = await database;
    final rows = await db.query(
      'challenge_notes',
      where: 'challengeId = ?',
      whereArgs: [challengeId],
      orderBy: 'createdAt DESC',
    );

    return rows.map(NoteRecord.fromMap).toList();
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete(
      'challenge_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Progress log methods

  Future<int> addProgressLog(ProgressLogRecord log) async {
    final db = await database;
    return db.insert('progress_logs', log.toMap());
  }

  Future<List<ProgressLogRecord>> getAllProgressLogs() async {
    final db = await database;
    final rows = await db.query(
      'progress_logs',
      orderBy: 'loggedAt DESC',
    );

    return rows.map(ProgressLogRecord.fromMap).toList();
  }

  Future<List<ProgressLogRecord>> getProgressLogs(int challengeId) async {
    final db = await database;
    final rows = await db.query(
      'progress_logs',
      where: 'challengeId = ?',
      whereArgs: [challengeId],
      orderBy: 'loggedAt DESC',
    );

    return rows.map(ProgressLogRecord.fromMap).toList();
  }

  Future<int> getTotalUnits(int challengeId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(units), 0) AS total '
      'FROM progress_logs WHERE challengeId = ?',
      [challengeId],
    );

    return (result.first['total'] as num).toInt();
  }
}

class ChallengeRecord {
  final int? id;
  final String title;
  final String category;
  final int targetUnits;
  final String description;
  final bool isCompleted;

  const ChallengeRecord({
    this.id,
    required this.title,
    required this.category,
    required this.targetUnits,
    this.description = '',
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'targetUnits': targetUnits,
        'description': description,
        'isCompleted': isCompleted ? 1 : 0,
      };

  factory ChallengeRecord.fromMap(Map<String, dynamic> map) {
    return ChallengeRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      targetUnits: (map['targetUnits'] as num).toInt(),
      description: map['description'] as String? ?? '',
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }
}

class ActivityRecord {
  final int id;
  final int challengeId;
  final String title;
  final bool isCompleted;

  const ActivityRecord({
    required this.id,
    required this.challengeId,
    required this.title,
    required this.isCompleted,
  });

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['id'] as int,
      challengeId: map['challengeId'] as int,
      title: map['title'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }
}

class NoteRecord {
  final int id;
  final int challengeId;
  final String note;
  final DateTime createdAt;

  const NoteRecord({
    required this.id,
    required this.challengeId,
    required this.note,
    required this.createdAt,
  });

  factory NoteRecord.fromMap(Map<String, dynamic> map) {
    return NoteRecord(
      id: map['id'] as int,
      challengeId: map['challengeId'] as int,
      note: map['note'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class ProgressLogRecord {
  final int? id;
  final int challengeId;
  final DateTime loggedAt;
  final int units;
  final String note;

  const ProgressLogRecord({
    this.id,
    required this.challengeId,
    required this.loggedAt,
    required this.units,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'challengeId': challengeId,
        'loggedAt': loggedAt.toIso8601String(),
        'units': units,
        'note': note,
      };

  factory ProgressLogRecord.fromMap(Map<String, dynamic> map) {
    return ProgressLogRecord(
      id: map['id'] as int?,
      challengeId: map['challengeId'] as int,
      loggedAt: DateTime.parse(map['loggedAt'] as String),
      units: (map['units'] as num).toInt(),
      note: map['note'] as String? ?? '',
    );
  }
}