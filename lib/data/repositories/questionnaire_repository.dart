import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class QuestionnaireRepository {
  static const _tableName = 'questionnaires';

  Future<Database> getDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'recovery_app.db'),
      onCreate: (db, version) {
        return db.execute('''CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            gender TEXT,
            weight REAL,
            height REAL,
            mainInjuryType TEXT,
            specificInjury TEXT,
            painLevel INTEGER,
            trainingTime TEXT
          )''');
      },
      version: 1,
    );
  }

  Future<void> saveQuestionnaire(RecoveryData data) async {
    final db = await getDatabase();
    if (data.id == null) {
      await db.insert('questionnaires', data.toMap());
    } else {
      await db.update(
        'questionnaires',
        data.toMap(),
        where: 'id = ?',
        whereArgs: [data.id],
      );
    }
  }

  Future<RecoveryData?> getLatestQuestionnaire() async {
    final db = await getDatabase();
    final maps = await db.query('questionnaires', orderBy: 'id DESC', limit: 1);

    if (maps.isNotEmpty) {
      return RecoveryData.fromMap(maps.first);
    }
    return null;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'questionnaires.db'),
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            gender TEXT NOT NULL,
            weight REAL NOT NULL,
            height REAL NOT NULL,
            injuryType TEXT NOT NULL,
            painLevel INTEGER NOT NULL,
            trainingTime TEXT NOT NULL
          )
        ''');
      },
      version: 1,
    );
  }
}
