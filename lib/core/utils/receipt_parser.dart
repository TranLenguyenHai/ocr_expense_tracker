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

    for (var line in lines.take(6)) {
      for (var brand in knownBrands) {
        if (line.toLowerCase().contains(brand.toLowerCase())) {
          return brand;
        }
      }
    }

    // 2. Blacklist generic receipt titles
    final blacklist = [
      'hóa đơn', 'hoa don', 'phiếu thanh toán', 'phieu thanh toan',
      'biên lai', 'bien lai', 'phiếu thu', 'phieu thu', 'receipt', 'invoice',
      'tax invoice', 'vat', 'tel:', 'hotline', 'đt:', 'địa chỉ', 'dia chi',
      'address', 'welcome', 'xin chào', 'cảm ơn', 'ngay:', 'date:', 'table',
      'bàn:', 'thu ngân', 'cashier',
    ];

    for (var line in lines.take(5)) {
      final lower = line.toLowerCase();
      final isBlacklisted = blacklist.any((b) => lower.contains(b));
      // Must have some letters and not be too short or pure number
      final hasLetters = RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(line);
      final isNotTooLong = line.length <= 40;

      if (!isBlacklisted && hasLetters && line.length >= 3 && isNotTooLong) {
        return line;
      }
    }

    return lines.first;
  }

  /// Extracts the total monetary amount using keyword scoring and regex
  static double _extractAmount(List<String> lines) {
    final totalKeywords = [
      'tổng tiền', 'tong tien', 'tổng cộng', 'tong cong',
      'thanh toán', 'thanh toan', 'tiền mặt', 'tien mat',
      'cộng tiền hàng', 'cong tien hang', 'phải trả', 'phai tra',
      'số tiền', 'so tien', 'total', 'grand total', 'amount due',
      'net amount', 'balance due', 'cash',
    ];

    double bestAmount = 0.0;
    double highestScore = -1.0;

    // Regex to match numbers with separators like 150,000 | 150.000 | 150 000 | 15.50
    final numberRegex = RegExp(
      r'(?:^|[^\d])(\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\d{4,9})(?:\s*(?:VND|VNĐ|đ|d|\$))?',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      // Check if this line has a total keyword
      bool hasKeyword = totalKeywords.any((k) => lowerLine.contains(k));

      // Scan current line and the immediate next line (in case value is on next line)
      String searchArea = line;
      if (hasKeyword && i + 1 < lines.length) {
        searchArea = '$line ${lines[i + 1]}';
      }

      final matches = numberRegex.allMatches(searchArea);
      for (var match in matches) {
        final rawVal = match.group(1);
        if (rawVal == null) continue;

        final cleanVal = _cleanNumber(rawVal);
        if (cleanVal <= 0) continue;

        // Skip obvious non-amounts like years (2024, 2025, 2026), phone numbers, postal codes
        if ((cleanVal >= 2020 && cleanVal <= 2030) && !hasKeyword) {
          continue;
        }

        double score = 0.0;
        if (hasKeyword) {
          score += 100.0;
        }
        if (lowerLine.contains('vnd') || lowerLine.contains('vnđ') || lowerLine.contains('đ') || lowerLine.contains('\$')) {
          score += 30.0;
        }
        // Receipt totals are typically towards the lower half
        final relativePos = i / lines.length;
        score += relativePos * 25.0;

        if (score > highestScore) {
          highestScore = score;
          bestAmount = cleanVal;
        }
      }
    }

    // Fallback if no keyword match: pick the highest reasonable number in bottom half
    if (bestAmount == 0.0) {
      for (var line in lines.reversed.take(8)) {
        final matches = numberRegex.allMatches(line);
        for (var match in matches) {
          final val = _cleanNumber(match.group(1) ?? '');
          if (val > bestAmount && val > 1000 && val < 50000000) {
            bestAmount = val;
          }
        }
      }
    }

    return bestAmount;
  }

  static double _cleanNumber(String raw) {
    // Remove all non-digit and non-punctuation characters
    String s = raw.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (s.isEmpty) return 0.0;

    // Handle Vietnamese format (150.000 or 150,000)
    if (s.contains('.') && s.contains(',')) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        // e.g. 1.250,50 -> 1250.50
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // e.g. 1,250.50 -> 1250.50
        s = s.replaceAll(',', '');
      }
    } else if (s.contains('.')) {
      // Could be 150.000 (thousands) or 15.50 (decimal)
      final parts = s.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        s = s.replaceAll('.', '');
      }
    } else if (s.contains(',')) {
      final parts = s.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        s = s.replaceAll(',', '');
      }
    }

    return double.tryParse(s) ?? 0.0;
  }

  /// Extracts date from lines (DD/MM/YYYY, YYYY-MM-DD, etc.)
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

        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2020 && year <= 2030) {
          return DateTime(year, month, day);
        }
      }

      final ymdMatch = ymdRegex.firstMatch(line);
      if (ymdMatch != null) {
        int year = int.tryParse(ymdMatch.group(1)!) ?? DateTime.now().year;
        int month = int.tryParse(ymdMatch.group(2)!) ?? 1;
        int day = int.tryParse(ymdMatch.group(3)!) ?? 1;

        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2020 && year <= 2030) {
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
