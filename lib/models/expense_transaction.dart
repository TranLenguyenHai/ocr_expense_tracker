import '../core/constants/app_categories.dart';

class ExpenseTransaction {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? imagePath;
  final String? rawOcr;
  final String? note;
  final DateTime createdAt;

  ExpenseTransaction({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawOcr,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'image_path': imagePath,
      'raw_ocr': rawOcr,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Cửa hàng không rõ',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      category: ExpenseCategory.fromString(map['category'] as String? ?? 'food'),
      imagePath: map['image_path'] as String?,
      rawOcr: map['raw_ocr'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  ExpenseTransaction copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? imagePath,
    String? rawOcr,
    String? note,
    DateTime? createdAt,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcr: rawOcr ?? this.rawOcr,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
