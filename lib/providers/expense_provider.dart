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

  String _searchQuery = '';
  ExpenseCategory? _categoryFilter;
  DateTimeRange? _dateRangeFilter;

  Map<ExpenseCategory, double> _categoryTotals = {};
  List<double> _weeklyDailyTotals = List.filled(7, 0.0);
  DateTime _currentWeekStart = DateTime.now();

  List<ExpenseTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ExpenseCategory? get categoryFilter => _categoryFilter;
  DateTimeRange? get dateRangeFilter => _dateRangeFilter;
  Map<ExpenseCategory, double> get categoryTotals => _categoryTotals;
  List<double> get weeklyDailyTotals => _weeklyDailyTotals;
  DateTime get currentWeekStart => _currentWeekStart;

  List<ExpenseTransaction> get filteredTransactions {
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
  }

  double get totalExpense {
    return _transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  ExpenseProvider() {
    _calculateCurrentWeekStart();
    init();
  }

  void _calculateCurrentWeekStart() {
    final now = DateTime.now();
    // Monday is weekday 1
    _currentWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _db.seedInitialDataIfEmpty();
    await refreshData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _transactions = await _db.getAllTransactions();
    _categoryTotals = await _db.getCategoryTotals();
    _weeklyDailyTotals = await _db.getWeeklyDailyTotals(_currentWeekStart);
    notifyListeners();
  }

  Future<void> addTransaction(ExpenseTransaction tx) async {
    await _db.insert(tx);
    await refreshData();
  }

  Future<void> updateTransaction(ExpenseTransaction tx) async {
    await _db.update(tx);
    await refreshData();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.delete(id);
    await refreshData();
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

  /// Copies captured or picked image to app document storage directory
  Future<String?> cacheReceiptImage(String sourceFilePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourceFilePath)}';
      final savedImage = await File(sourceFilePath).copy(p.join(receiptsDir.path, fileName));
      return savedImage.path;
    } catch (e) {
      debugPrint('Error caching receipt image: $e');
      return sourceFilePath;
    }
  }
}
