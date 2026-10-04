import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_categories.dart';
import '../core/database/db_helper.dart';
import '../models/expense_transaction.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<ExpenseTransaction> _transactions = [];
  bool _isLoading = true;
  String? _initError;

  String _searchQuery = '';
  ExpenseCategory? _categoryFilter;
  DateTimeRange? _dateRangeFilter;

  Map<ExpenseCategory, double> _categoryTotals = {
    for (var cat in ExpenseCategory.values) cat: 0.0,
  };
  List<double> _weeklyDailyTotals = List.filled(7, 0.0);
  DateTime _currentWeekStart = DateTime.now();

  List<ExpenseTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get initError => _initError;
  String get searchQuery => _searchQuery;
  ExpenseCategory? get categoryFilter => _categoryFilter;
  DateTimeRange? get dateRangeFilter => _dateRangeFilter;
  Map<ExpenseCategory, double> get categoryTotals => _categoryTotals;
  List<double> get weeklyDailyTotals => _weeklyDailyTotals;
  DateTime get currentWeekStart => _currentWeekStart;

  List<ExpenseTransaction> get filteredTransactions {
    try {
      return _transactions.where((tx) {
        final matchesSearch = _searchQuery.isEmpty ||
            tx.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (tx.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        final matchesCategory =
            _categoryFilter == null || tx.category == _categoryFilter;
        final matchesDate = _dateRangeFilter == null ||
            (tx.date.isAfter(_dateRangeFilter!.start.subtract(const Duration(days: 1))) &&
                tx.date.isBefore(_dateRangeFilter!.end.add(const Duration(days: 1))));
        return matchesSearch && matchesCategory && matchesDate;
      }).toList();
    } catch (e) {
      debugPrint('Error filtering transactions: $e');
      return _transactions;
    }
  }

  double get totalExpense {
    try {
      return _transactions.fold(0.0, (sum, tx) => sum + tx.amount);
    } catch (e) {
      return 0.0;
    }
  }

  ExpenseProvider() {
    try {
      _calculateCurrentWeekStart();
    } catch (e) {
      debugPrint('Error calculating week start: $e');
      _currentWeekStart = DateTime.now();
    }
    // Don't await — fire and forget, UI will rebuild via notifyListeners
    _safeInit();
  }

  void _calculateCurrentWeekStart() {
    final now = DateTime.now();
    _currentWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  Future<void> _safeInit() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try seeding sample data
      try {
        await _db.seedInitialDataIfEmpty();
      } catch (e) {
        debugPrint('Seed data failed (non-fatal): $e');
      }

      // Try loading data
      await _safeRefreshData();
    } catch (e) {
      debugPrint('Init error: $e');
      _initError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _safeRefreshData() async {
    try {
      _transactions = await _db.getAllTransactions();
    } catch (e) {
      debugPrint('Load transactions failed: $e');
      _transactions = [];
    }
    try {
      _categoryTotals = await _db.getCategoryTotals();
    } catch (e) {
      debugPrint('Load category totals failed: $e');
      _categoryTotals = {for (var cat in ExpenseCategory.values) cat: 0.0};
    }
    try {
      _weeklyDailyTotals = await _db.getWeeklyDailyTotals(_currentWeekStart);
    } catch (e) {
      debugPrint('Load weekly totals failed: $e');
      _weeklyDailyTotals = List.filled(7, 0.0);
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    await _safeRefreshData();
  }

  Future<void> addTransaction(ExpenseTransaction tx) async {
    try {
      await _db.insert(tx);
      await _safeRefreshData();
    } catch (e) {
      debugPrint('Add transaction failed: $e');
    }
  }

  Future<void> updateTransaction(ExpenseTransaction tx) async {
    try {
      await _db.update(tx);
      await _safeRefreshData();
    } catch (e) {
      debugPrint('Update transaction failed: $e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _db.delete(id);
      await _safeRefreshData();
    } catch (e) {
      debugPrint('Delete transaction failed: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(ExpenseCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setDateRangeFilter(DateTimeRange? range) {
    _dateRangeFilter = range;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _dateRangeFilter = null;
    notifyListeners();
  }

  Future<String?> cacheReceiptImage(String sourceFilePath) async {
    try {
      if (sourceFilePath.isEmpty) return null;
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      final fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourceFilePath)}';
      final savedImage =
          await File(sourceFilePath).copy(p.join(receiptsDir.path, fileName));
      return savedImage.path;
    } catch (e) {
      debugPrint('Error caching receipt image: $e');
      return sourceFilePath.isNotEmpty ? sourceFilePath : null;
    }
  }
}
