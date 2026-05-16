import 'package:baby_subscription/models/app_user.dart';
import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/models/subscription.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'baby_subscription_v2.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            display_name TEXT,
            provider TEXT NOT NULL,
            password_hash TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE baby_profiles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            birth_date TEXT NOT NULL,
            weight_kg REAL NOT NULL,
            photo_path TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE subscriptions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            baby_profile_id INTEGER NOT NULL,
            diaper_type TEXT NOT NULL,
            quantity_per_order INTEGER NOT NULL,
            frequency TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(baby_profile_id) REFERENCES baby_profiles(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS subscriptions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              baby_profile_id INTEGER NOT NULL,
              diaper_type TEXT NOT NULL,
              quantity_per_order INTEGER NOT NULL,
              frequency TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
              FOREIGN KEY(baby_profile_id) REFERENCES baby_profiles(id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Future<Subscription?> getActiveSubscription(int userId, int babyProfileId) async {
    final db = await database;
    final result = await db.query(
      'subscriptions',
      where: 'user_id = ? AND baby_profile_id = ? AND is_active = 1',
      whereArgs: [userId, babyProfileId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Subscription.fromMap(result.first);
  }

  Future<Subscription> saveSubscription(Subscription sub) async {
    final db = await database;
    final map = sub.toMap()..remove('id');
    if (sub.id != null) {
      await db.update('subscriptions', map, where: 'id = ?', whereArgs: [sub.id]);
      return sub;
    } else {
      final id = await db.insert('subscriptions', map);
      return sub.copyWith(id: id);
    }
  }

  Future<void> cancelSubscription(int subscriptionId) async {
    final db = await database;
    await db.update(
      'subscriptions',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [subscriptionId],
    );
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<AppUser> createUser(AppUser user) async {
    final db = await database;
    final map = user.toMap()..remove('id');
    final id = await db.insert('users', map);
    return user.copyWith(id: id);
  }

  Future<List<BabyProfile>> getBabyProfiles(int userId) async {
    final db = await database;
    final result = await db.query(
      'baby_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
    return result.map(BabyProfile.fromMap).toList();
  }

  Future<BabyProfile> saveBabyProfile(BabyProfile profile, int userId) async {
    final db = await database;
    final map = profile.toMap();
    map['user_id'] = userId;
    map.remove('id');

    if (profile.id != null) {
      await db.update('baby_profiles', map, where: 'id = ?', whereArgs: [profile.id]);
      return profile;
    } else {
      final id = await db.insert('baby_profiles', map);
      return profile.copyWith(id: id);
    }
  }

  Future<void> deleteBabyProfile(int profileId) async {
    final db = await database;
    await db.delete('baby_profiles', where: 'id = ?', whereArgs: [profileId]);
  }
}