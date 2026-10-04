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
      'tổng tiền', 'tong tien', 'tổng cộng', 'tong cong',
      'thanh toán', 'thanh toan', 'tiền mặt', 'tien mat',
      'cộng tiền hàng', 'cong tien hang', 'phải trả', 'phai tra',
      'số tiền', 'so tien', 'total', 'grand total', 'amount due',
      'net amount', 'balance due', 'cash',
    ];

    // Non-currency units: numbers immediately followed by these are NOT money amounts
    final nonMoneyUnits = RegExp(
      r'^\s*(?:phút|phut|giờ|gio|ngày|ngay|tháng|thang|năm|nam|g|kg|ml|l|chai|lon|cái|cai|gói|goi|bịch|bich|km|sl|item|pcs|mã|ma)\b',
      caseSensitive: false,
    );

    double bestAmount = 0.0;
    double highestScore = -1.0;

    // Matches numbers with thousand separators (e.g. 237,576 | 537,000 | 17,500),
    // numbers with faint zero (.00 | ,00), or pure 4-9 digit numbers (e.g. 25000)
    final numberRegex = RegExp(
      r'(?:^|[^\d.,])(\d{1,3}(?:[.,][0-9OoQD]{3})+(?:[.,][0-9OoQD]{1,2})?|\d{1,3}[.,][0-9OoQD]{2}|\d{4,9})(?:\s*(?:VND|VNĐ|đ|d|\$))?',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      bool hasKeyword = totalKeywords.any((k) => lowerLine.contains(k));
      double keywordBoost = 0.0;
      if (lowerLine.contains('tiền cần thanh toán') || lowerLine.contains('tien can thanh toan')) {
        keywordBoost = 250.0;
      } else if (lowerLine.contains('tổng tiền') || lowerLine.contains('tong tien') || lowerLine.contains('tổng cộng')) {
        keywordBoost = 200.0;
      } else if (hasKeyword) {
        keywordBoost = 150.0;
      }

      // If current line has keyword but no number, peek next line
      String searchArea = line;
      final hasNumberOnLine = numberRegex.hasMatch(line);
      if (hasKeyword && !hasNumberOnLine && i + 1 < lines.length) {
        searchArea = '$line ${lines[i + 1]}';
      }

      final matches = numberRegex.allMatches(searchArea);
      for (var match in matches) {
        final rawVal = match.group(1);
        if (rawVal == null) continue;

        // Check if followed by non-money unit (e.g. "60 phút", "110g", "500ml")
        final endPos = match.end;
        if (endPos < searchArea.length) {
          final remainder = searchArea.substring(endPos);
          if (nonMoneyUnits.hasMatch(remainder)) {
            continue; // Skip durations, quantities, weights
          }
        }

        final cleanVal = _cleanNumber(rawVal);
        if (cleanVal <= 0) continue;

        // Skip years when no total keyword
        if ((cleanVal >= 2010 && cleanVal <= 2030) && !hasKeyword) {
          continue;
        }

        double score = keywordBoost;
        if (lowerLine.contains('vnd') || lowerLine.contains('vnđ') || lowerLine.contains('đ') || lowerLine.contains('\$')) {
          score += 30.0;
        }

        if (score > 0) {
          // Receipt totals are typically lower down
          final relativePos = i / lines.length;
          score += relativePos * 30.0;
          // In lines with discounts (-34,250 237,576), prefer the actual total
          score += (cleanVal / 1000000) * 10.0;
        } else if (i >= lines.length ~/ 2 && cleanVal >= 1000) {
          // Fallback: bottom half candidates
          score = (i / lines.length) * 25.0;
        }

        if (score > highestScore) {
          highestScore = score;
          bestAmount = cleanVal;
        }
      }
    }

    return bestAmount;
  }

  static double _cleanNumber(String raw) {
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

    return double.tryParse(s) ?? 0.0;
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
