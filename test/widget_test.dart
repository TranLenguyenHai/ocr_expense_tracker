import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/constants/app_categories.dart';
import 'package:ocr_expense_tracker/core/utils/receipt_parser.dart';

void main() {
  group('ReceiptParser Regex Heuristic Engine Tests', () {
    test('Correctly extracts merchant, amount, date and category from WinMart receipt', () {
      const receiptText = '''
WINMART+ LÊ DUẨN
ĐC: 182 Lê Duẩn, Đà Nẵng
HÓA ĐƠN BÁN HÀNG
Ngày: 24/10/2026 14:30
Sữa tươi tiệt trùng: 36.000
Bánh mì Sandwich: 24.000
TỔNG TIỀN: 60.000 VND
Cảm ơn quý khách!
''';

      final parsed = ReceiptParser.parse(receiptText);

      expect(parsed.merchant, contains('WinMart'));
      expect(parsed.amount, 60000.0);
      expect(parsed.date.year, 2026);
      expect(parsed.date.month, 10);
      expect(parsed.date.day, 24);
      expect(parsed.suggestedCategory, ExpenseCategory.food);
    });

    test('Correctly extracts Fahasa bookstore receipt as Study category', () {
      const receiptText = '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
300 Lê Duẩn, Thanh Khê
PHIẾU THANH TOÁN
Ngày: 22/10/2026
Giáo trình Cấu trúc dữ liệu: 180.000
TỔNG CỘNG: 180.000 đ
''';

      final parsed = ReceiptParser.parse(receiptText);

      expect(parsed.merchant, contains('Fahasa'));
      expect(parsed.amount, 180000.0);
      expect(parsed.suggestedCategory, ExpenseCategory.study);
    });

    test('Correctly extracts Grab bike as Travel category', () {
      const receiptText = '''
GRAB VIETNAM
Chuyến đi GrabBike
Ngày: 15/10/2026
Cước phí: 32.000 VND
TOTAL: 32.000 đ
''';

      final parsed = ReceiptParser.parse(receiptText);

      expect(parsed.merchant, contains('Grab'));
      expect(parsed.amount, 32000.0);
      expect(parsed.suggestedCategory, ExpenseCategory.travel);
    });
  });
}
