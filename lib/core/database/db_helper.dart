import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/expense_transaction.dart';
import '../constants/app_categories.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT,
        raw_ocr TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(ExpenseTransaction transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseTransaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return result.map((json) => ExpenseTransaction.fromMap(json)).toList();
  }

  Future<int> update(ExpenseTransaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> totals = {
      for (var cat in ExpenseCategory.values) cat: 0.0,
    };

    for (var row in result) {
      final categoryName = row['category'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (categoryName != null) {
        final cat = ExpenseCategory.fromString(categoryName);
        totals[cat] = (totals[cat] ?? 0.0) + total;
      }
    }

    return totals;
  }

  Future<List<double>> getWeeklyDailyTotals(DateTime startOfWeek) async {
    final db = await database;
    final List<double> dailyTotals = List.filled(7, 0.0);

    // Calculate dates for Mon (0) to Sun (6)
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM transactions
        WHERE date LIKE '$dayStr%'
      ''');

      if (result.isNotEmpty && result.first['total'] != null) {
        dailyTotals[i] = (result.first['total'] as num).toDouble();
      }
    }

    return dailyTotals;
  }

  Future<void> seedInitialDataIfEmpty() async {
    final list = await getAllTransactions();
    if (list.isNotEmpty) return;

    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final sampleTransactions = [
      ExpenseTransaction(
        merchant: 'WinMart+ Lê Duẩn',
        amount: 145000,
        date: monday.add(const Duration(hours: 9)),
        category: ExpenseCategory.food,
        note: 'Mua bánh mì, sữa tươi, trái cây',
      ),
      ExpenseTransaction(
        merchant: 'Nhà sách Fahasa Đà Nẵng',
        amount: 280000,
        date: monday.add(const Duration(days: 1, hours: 14)),
        category: ExpenseCategory.study,
        note: 'Sách giải thuật và sổ tay ghi chép',
      ),
      ExpenseTransaction(
        merchant: 'Highlands Coffee',
        amount: 59000,
        date: monday.add(const Duration(days: 2, hours: 8)),
        category: ExpenseCategory.food,
        note: 'Cà phê phin sữa đá sáng học bài',
      ),
      ExpenseTransaction(
        merchant: 'Grab Bike - Đi học',
        amount: 32000,
        date: monday.add(const Duration(days: 2, hours: 12)),
        category: ExpenseCategory.travel,
        note: 'Chuyến xe từ phòng trọ đến trường VKU',
      ),
      ExpenseTransaction(
        merchant: 'Cửa hàng Phụ kiện GearVN',
        amount: 450000,
        date: monday.add(const Duration(days: 3, hours: 16)),
        category: ExpenseCategory.gear,
        note: 'Chuột không dây Logitech Bluetooth',
      ),
      ExpenseTransaction(
        merchant: 'CGV Vincom Đà Nẵng',
        amount: 210000,
        date: monday.add(const Duration(days: 4, hours: 20)),
        category: ExpenseCategory.entertainment,
        note: '2 vé xem phim cuối tuần cùng bạn',
      ),
      ExpenseTransaction(
        merchant: 'Circle K Trần Đại Nghĩa',
        amount: 75000,
        date: monday.add(const Duration(days: 5, hours: 11)),
        category: ExpenseCategory.food,
        note: 'Mì trộn trứng xúc xích và trà đào',
      ),
    ];

    for (var tx in sampleTransactions) {
      await insert(tx);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
