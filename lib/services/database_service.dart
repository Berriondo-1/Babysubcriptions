import 'package:baby_subscription/models/baby_profile.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'baby_subscription.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE baby(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            birth_date TEXT NOT NULL,
            stage TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<BabyProfile?> getBabyProfile() async {
    final db = await database;
    final result = await db.query('baby', orderBy: 'id DESC', limit: 1);

    if (result.isEmpty) {
      return null;
    }

    return BabyProfile.fromMap(result.first);
  }

  Future<void> saveBabyProfile(BabyProfile profile) async {
    final db = await database;
    await db.delete('baby');
    await db.insert('baby', profile.toMap());
  }
}
