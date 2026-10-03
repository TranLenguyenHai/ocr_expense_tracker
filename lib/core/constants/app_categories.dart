import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.study:
        return 'Study';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.gear:
        return 'Gear';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
    }
  }

  String get vietnameseName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.study:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Đi lại';
      case ExpenseCategory.gear:
        return 'Thiết bị & Đồ dùng';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.study:
        return Icons.school_rounded;
      case ExpenseCategory.travel:
        return Icons.directions_bus_rounded;
      case ExpenseCategory.gear:
        return Icons.devices_rounded;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B); // Coral Red/Orange
      case ExpenseCategory.study:
        return const Color(0xFF4D96FF); // Royal Blue
      case ExpenseCategory.travel:
        return const Color(0xFF6BCB77); // Emerald Green
      case ExpenseCategory.gear:
        return const Color(0xFF9D4EDD); // Purple
      case ExpenseCategory.entertainment:
        return const Color(0xFFFFD93D); // Warm Yellow
    }
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == value.toLowerCase() ||
             c.displayName.toLowerCase() == value.toLowerCase() ||
             c.vietnameseName.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.food,
    );
  }
}
