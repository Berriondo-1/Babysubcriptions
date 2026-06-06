import 'package:baby_subscription/models/app_user.dart';
import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/models/diaper_consumption.dart';
import 'package:baby_subscription/models/order_record.dart';
import 'package:baby_subscription/models/payment_record.dart';
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
      version: 5,
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
        await db.execute('''
          CREATE TABLE diaper_consumption(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            baby_profile_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            diaper_count INTEGER NOT NULL,
            FOREIGN KEY(baby_profile_id) REFERENCES baby_profiles(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE payment_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subscription_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            transaction_id TEXT NOT NULL UNIQUE,
            amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            order_number TEXT NOT NULL UNIQUE,
            diaper_type_label TEXT NOT NULL DEFAULT '',
            quantity INTEGER NOT NULL DEFAULT 0,
            frequency_label TEXT NOT NULL DEFAULT '',
            total_amount REAL NOT NULL DEFAULT 0,
            payment_method_label TEXT NOT NULL DEFAULT '',
            delivery_status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
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
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS diaper_consumption(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              baby_profile_id INTEGER NOT NULL,
              date TEXT NOT NULL,
              diaper_count INTEGER NOT NULL,
              FOREIGN KEY(baby_profile_id) REFERENCES baby_profiles(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS payment_history(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              subscription_id INTEGER NOT NULL,
              user_id INTEGER NOT NULL,
              transaction_id TEXT NOT NULL UNIQUE,
              amount REAL NOT NULL,
              payment_method TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY(subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
              FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS orders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              order_number TEXT NOT NULL UNIQUE,
              diaper_type_label TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 0,
              frequency_label TEXT NOT NULL DEFAULT '',
              total_amount REAL NOT NULL DEFAULT 0,
              payment_method_label TEXT NOT NULL DEFAULT '',
              delivery_status TEXT NOT NULL DEFAULT 'pending',
              created_at TEXT NOT NULL,
              FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  // ── Suscripciones ─────────────────────────────────────────────

  Future<Subscription?> getActiveSubscription(
    int userId,
    int babyProfileId,
  ) async {
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
      await db.update(
        'subscriptions',
        map,
        where: 'id = ?',
        whereArgs: [sub.id],
      );
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

  // ── Usuarios ──────────────────────────────────────────────────

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<AppUser> createUser(AppUser user) async {
    final db = await database;
    final map = user.toMap()..remove('id');
    final id = await db.insert('users', map);
    return user.copyWith(id: id);
  }

  // ── Bebés ─────────────────────────────────────────────────────

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
      await db.update(
        'baby_profiles',
        map,
        where: 'id = ?',
        whereArgs: [profile.id],
      );
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

  // ── Consumo ───────────────────────────────────────────────────

  Future<List<DiaperConsumption>> getConsumptionHistory(
    int babyProfileId,
  ) async {
    final db = await database;
    final result = await db.query(
      'diaper_consumption',
      where: 'baby_profile_id = ?',
      whereArgs: [babyProfileId],
      orderBy: 'date DESC',
      limit: 90,
    );
    return result.map(DiaperConsumption.fromMap).toList();
  }

  Future<DiaperConsumption> saveConsumption(DiaperConsumption entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    if (entry.id != null) {
      await db.update(
        'diaper_consumption',
        map,
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return entry;
    } else {
      final id = await db.insert('diaper_consumption', map);
      return entry.copyWith(id: id);
    }
  }

  // ── Pagos ─────────────────────────────────────────────────────

  Future<PaymentRecord> savePayment(PaymentRecord payment) async {
    final db = await database;
    final map = payment.toMap()..remove('id');
    final id = await db.insert('payment_history', map);
    return PaymentRecord(
      id: id,
      subscriptionId: payment.subscriptionId,
      userId: payment.userId,
      transactionId: payment.transactionId,
      amount: payment.amount,
      paymentMethod: payment.paymentMethod,
      status: payment.status,
      createdAt: payment.createdAt,
    );
  }

  Future<List<PaymentRecord>> getPaymentHistory(int userId) async {
    final db = await database;
    final result = await db.query(
      'payment_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 50,
    );
    return result.map(PaymentRecord.fromMap).toList();
  }

  // ── Pedidos (HU-08) ───────────────────────────────────────────

  Future<OrderRecord> saveOrder(OrderRecord order) async {
    final db = await database;
    final map = order.toMap()..remove('id');
    final id = await db.insert(
      'orders',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return OrderRecord(
      id: id,
      userId: order.userId,
      orderNumber: order.orderNumber,
      diaperTypeLabel: order.diaperTypeLabel,
      quantity: order.quantity,
      frequencyLabel: order.frequencyLabel,
      totalAmount: order.totalAmount,
      paymentMethodLabel: order.paymentMethodLabel,
      deliveryStatus: order.deliveryStatus,
      createdAt: order.createdAt,
    );
  }

  Future<List<OrderRecord>> getOrders(int userId) async {
    final db = await database;
    final result = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return result.map(OrderRecord.fromMap).toList();
  }
}
