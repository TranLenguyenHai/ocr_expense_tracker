import '../constants/app_categories.dart';

class ParsedReceipt {
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory suggestedCategory;
  final String rawText;
  final List<String> lines;

  ParsedReceipt({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.suggestedCategory,
    required this.rawText,
    required this.lines,
  });
}

class ReceiptParser {
  /// Heuristic rule engine for parsing receipt text
  static ParsedReceipt parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = _extractMerchant(lines);
    final amount = _extractAmount(lines);
    final date = _extractDate(lines);
    final category = _suggestCategory(merchant, text);

    return ParsedReceipt(
      merchant: merchant,
      amount: amount,
      date: date,
      suggestedCategory: category,
      rawText: text,
      lines: lines,
    );
  }

  /// Extracts the most probable merchant name from receipt header
  static String _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Cửa hàng không rõ';

    // 1. Check known retail/dining brands
    final knownBrands = [
      'WinMart', 'Co.opmart', 'Circle K', 'GS25', '7-Eleven', 'FamilyMart',
      'Highlands Coffee', 'Phúc Long', 'The Coffee House', 'Trung Nguyên',
      'KFC', 'Lotteria', 'Jollibee', 'McDonald\'s', 'Pizza Hut', 'Domino\'s',
      'Fahasa', 'Nhà sách Phương Nam', 'Nhà sách Tiền Phong',
      'GearVN', 'FPT Shop', 'Thế Giới Di Động', 'CellphoneS', 'Phong Vũ',
      'CGV', 'Lotte Cinema', 'BHD Star', 'Galaxy Cinema',
      'Grab', 'Be', 'Xanh SM', 'ShopeeFood',
    ];

    for (var line in lines.take(8)) {
      for (var brand in knownBrands) {
        if (line.toLowerCase().contains(brand.toLowerCase())) {
          return brand;
        }
      }
    }

    // 2. Priority for lines with business indicators (e.g. QUÁN ĂN THIỆN TÂN, NHÀ HÀNG, TIỆM, CÀ PHÊ)
    final businessPrefixes = [
      'quán ăn', 'quan an', 'quán', 'quan', 'nhà hàng', 'nha hang',
      'tiệm', 'tiem', 'cà phê', 'ca phe', 'coffee', 'cafe',
      'trà sữa', 'tra sua', 'bakery', 'food', 'store', 'shop',
      'cửa hàng', 'cua hang', 'siêu thị', 'sieu thi', 'bếp', 'bep',
    ];

    for (var line in lines.take(6)) {
      final lower = line.toLowerCase();
      for (var prefix in businessPrefixes) {
        if (lower.contains(prefix) && line.length >= 4 && line.length <= 45) {
          // Clean out leading symbols or numbers
          return line.replaceAll(RegExp(r'^[\W\d_]+'), '').trim();
        }
      }
    }

    // 3. Blacklist generic receipt titles & headers
    final blacklist = [
      'hóa đơn', 'hoa don', 'phiếu thanh toán', 'phieu thanh toan',
      'biên lai', 'bien lai', 'phiếu thu', 'phieu thu', 'receipt', 'invoice',
      'tax invoice', 'vat', 'tel:', 'hotline', 'đt:', 'dt:', 'địa chỉ', 'dia chi',
      'address', 'welcome', 'xin chào', 'cảm ơn', 'cam on', 'ngay:', 'date:', 'table',
      'bàn:', 'thu ngân', 'cashier', 'reg ', 'mc #', 'banso', 'bàn số',
    ];

    for (var line in lines.take(6)) {
      final lower = line.toLowerCase();
      final isBlacklisted = blacklist.any((b) => lower.contains(b));
      final hasLetters = RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(line);
      final isNotTooLong = line.length <= 40;

      // Filter out strange short gibberish tokens (e.g. "day VKUX" if first line is noise)
      if (!isBlacklisted && hasLetters && line.length >= 4 && isNotTooLong) {
        return line.trim();
      }
    }

    return lines.first;
  }

  /// Extracts the total monetary amount using keyword scoring and regex
  static double _extractAmount(List<String> lines) {
    final totalKeywords = [
      'tiền cần thanh toán', 'tien can thanh toan',
      'tổng thanh toán', 'tong thanh toan',
      'khách phải trả', 'khach phai tra',
      'tổng tiền', 'tong tien',
      'tổng cộng', 'tong cong',
      'phải thanh toán', 'phai thanh toan',
      'cộng tiền hàng', 'cong tien hang',
      'tiền mặt', 'tien mat',
      'thanh toán', 'thanh toan',
      'phải trả', 'phai tra',
      'số tiền', 'so tien',
      'grand total', 'total', 'amount due', 'balance due', 'cash',
    ];

    final nonMoneyUnits = RegExp(
      r'^\s*(?:phút|phut|giờ|gio|ngày|ngay|tháng|thang|năm|nam|g|kg|ml|l|chai|lon|cái|cai|gói|goi|bịch|bich|km|sl|item|pcs|ly|dĩa|dia|bát|bat|phần|phan)\b',
      caseSensitive: false,
    );

    // 1. First strategy: find total amount on lines containing total keywords
    final candidateAmounts = <_AmountCandidate>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      String? matchedKw;
      for (var kw in totalKeywords) {
        if (lower.contains(kw)) {
          matchedKw = kw;
          break;
        }
      }

      if (matchedKw != null) {
        // Look on current line first
        final nums = _findValidNumbers(line, nonMoneyUnits);
        if (nums.isNotEmpty) {
          // Filter out discounts (preceded by minus '-')
          final posNums = <double>[];
          for (var item in nums) {
            final startIdx = item.start;
            final prefix = line.substring(0, startIdx).trimRight();
            if (!prefix.endsWith('-')) {
              posNums.add(item.value);
            }
          }

          if (posNums.isNotEmpty) {
            posNums.sort();
            candidateAmounts.add(_AmountCandidate(
              amount: posNums.last,
              score: 300.0 - i,
            ));
          } else {
            nums.sort((a, b) => a.value.compareTo(b.value));
            candidateAmounts.add(_AmountCandidate(
              amount: nums.last.value,
              score: 250.0 - i,
            ));
          }
        } else if (i + 1 < lines.length) {
          // Amount is on the next line (e.g. "TIEN MAT\n537,000")
          final nextNums = _findValidNumbers(lines[i + 1], nonMoneyUnits);
          if (nextNums.isNotEmpty) {
            nextNums.sort((a, b) => a.value.compareTo(b.value));
            candidateAmounts.add(_AmountCandidate(
              amount: nextNums.last.value,
              score: 280.0 - i,
            ));
          }
        }
      }
    }

    if (candidateAmounts.isNotEmpty) {
      candidateAmounts.sort((a, b) => b.score.compareTo(a.score));
      return candidateAmounts.first.amount;
    }

    // 2. Fallback: if no keyword match was found on any line,
    // scan bottom half of the receipt for the largest plausible amount
    final bottomLines = lines.length > 3 ? lines.sublist(lines.length ~/ 3) : lines;
    double fallbackMax = 0.0;
    for (var line in bottomLines) {
      final nums = _findValidNumbers(line, nonMoneyUnits);
      for (var item in nums) {
        if (item.value >= 1000 && item.value <= 100000000 && item.value > fallbackMax) {
          fallbackMax = item.value;
        }
      }
    }

    return fallbackMax;
  }

  static List<_ExtractedNumber> _findValidNumbers(String line, RegExp nonMoneyUnits) {
    final results = <_ExtractedNumber>[];
    // Matches: 237,576 | 537.000 | 537 000 | 17,500 | 537,00 | 537.00 | 50k | 537 | 25000
    final pattern = RegExp(
      r'(?:^|[^\w.,])(\d{1,3}(?:[.,\s][0-9OoQD]{3})+(?:[.,][0-9OoQD]{1,2})?|\d{1,3}[.,][0-9OoQD]{2}|\d{1,4}[kK]|\d{3,9})(?:\s*(?:VND|VNĐ|đ|d|\$))?',
      caseSensitive: false,
    );

    for (var m in pattern.allMatches(line)) {
      final raw = m.group(1);
      if (raw == null) continue;

      final startPos = m.start;
      final endPos = m.end;

      // Check if followed by non-money unit (e.g. "60 phút", "110g", "500ml")
      if (endPos < line.length) {
        final remainder = line.substring(endPos);
        if (nonMoneyUnits.hasMatch(remainder)) {
          continue;
        }
      }

      final val = _cleanNumber(raw);
      if (val > 0) {
        results.add(_ExtractedNumber(value: val, raw: raw, start: startPos));
      }
    }

    return results;
  }

  static double _cleanNumber(String raw) {
    // Handle 'k' e.g. 50k -> 50000
    if (raw.toLowerCase().endsWith('k')) {
      final n = raw.replaceAll(RegExp(r'[^\d.,]'), '');
      final d = double.tryParse(n) ?? 0.0;
      return d * 1000;
    }

    // Replace common OCR character misreads (O, o, Q, D for 0)
    String s = raw.replaceAll(RegExp(r'[OoQD]'), '0');
    s = s.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (s.isEmpty) return 0.0;

    // Handle thousand separators
    if (s.contains('.') && s.contains(',')) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (s.contains(',')) {
      final parts = s.split(',');
      if (parts.length == 2 && parts[1].length == 2 && parts[1] == '00') {
        // e.g. 537,00 (faint zero) -> 537000
        s = '${parts[0]}000';
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (s.contains('.')) {
      final parts = s.split('.');
      if (parts.length == 2 && parts[1].length == 2 && parts[1] == '00') {
        s = '${parts[0]}000';
      } else if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        s = s.replaceAll('.', '');
      }
    }

    double val = double.tryParse(s) ?? 0.0;
    // In VN receipts, an amount between 10 and 999 on a total line is written in thousands (e.g. 537 -> 537,000)
    if (val >= 10 && val < 1000) {
      val = val * 1000;
    }

    return val;
  }

  /// Extracts date from lines (DD/MM/YYYY, YYYY-MM-DD, DD-MM-YYYY, etc.)
  static DateTime _extractDate(List<String> lines) {
    // Regex for DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyRegex = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b');
    // Regex for YYYY-MM-DD
    final ymdRegex = RegExp(r'\b(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})\b');

    for (var line in lines) {
      final dmyMatch = dmyRegex.firstMatch(line);
      if (dmyMatch != null) {
        int day = int.tryParse(dmyMatch.group(1)!) ?? 1;
        int month = int.tryParse(dmyMatch.group(2)!) ?? 1;
        int year = int.tryParse(dmyMatch.group(3)!) ?? DateTime.now().year;
        if (year < 100) year += 2000;

        // Valid years from 2000 to 2099
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2000 && year <= 2099) {
          return DateTime(year, month, day);
        }
      }

      final ymdMatch = ymdRegex.firstMatch(line);
      if (ymdMatch != null) {
        int year = int.tryParse(ymdMatch.group(1)!) ?? DateTime.now().year;
        int month = int.tryParse(ymdMatch.group(2)!) ?? 1;
        int day = int.tryParse(ymdMatch.group(3)!) ?? 1;

        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2000 && year <= 2099) {
          return DateTime(year, month, day);
        }
      }
    }

    return DateTime.now();
  }

  /// Classifies into one of the 5 required categories based on merchant and items
  static ExpenseCategory _suggestCategory(String merchant, String fullText) {
    final lower = '$merchant $fullText'.toLowerCase();

    // 1. Study
    if (lower.contains('fahasa') ||
        lower.contains('nhà sách') || lower.contains('nha sach') ||
        lower.contains('học tập') || lower.contains('hoc tap') ||
        lower.contains('sách') || lower.contains('sach') ||
        lower.contains('vở') || lower.contains('bút') ||
        lower.contains('photocopy') || lower.contains('in ấn') ||
        lower.contains('university') || lower.contains('học phí')) {
      return ExpenseCategory.study;
    }

    // 2. Travel
    if (lower.contains('grab') || lower.contains('be ') || lower.contains('xanh sm') ||
        lower.contains('gojek') || lower.contains('taxi') ||
        lower.contains('xăng') || lower.contains('xang') ||
        lower.contains('petrolimex') || lower.contains('pv oil') ||
        lower.contains('vé xe') || lower.contains('vé tàu') || lower.contains('máy bay')) {
      return ExpenseCategory.travel;
    }

    // 3. Gear & Equipment
    if (lower.contains('gear') || lower.contains('gearvn') ||
        lower.contains('phong vũ') || lower.contains('phong vu') ||
        lower.contains('fpt shop') || lower.contains('thế giới di động') ||
        lower.contains('cellphones') || lower.contains('chuột') ||
        lower.contains('bàn phím') || lower.contains('tai nghe') ||
        lower.contains('laptop') || lower.contains('máy tính') ||
        lower.contains('cáp sạc') || lower.contains('usb')) {
      return ExpenseCategory.gear;
    }

    // 4. Entertainment
    if (lower.contains('cgv') || lower.contains('lotte cinema') ||
        lower.contains('galaxy') || lower.contains('bhd') ||
        lower.contains('rạp phim') || lower.contains('cinema') ||
        lower.contains('bida') || lower.contains('karaoke') ||
        lower.contains('steam') || lower.contains('game') ||
        lower.contains('vé xem phim')) {
      return ExpenseCategory.entertainment;
    }

    // Default to Food (most common for student receipts)
    return ExpenseCategory.food;
  }
}

class _AmountCandidate {
  final double amount;
  final double score;
  _AmountCandidate({required this.amount, required this.score});
}

class _ExtractedNumber {
  final double value;
  final String raw;
  final int start;
  _ExtractedNumber({required this.value, required this.raw, required this.start});
}

