import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoryDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalExpense;

  const CategoryDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalExpense,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalExpense != widget.totalExpense) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalExpense <= 0) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Chưa có dữ liệu chi tiêu',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân bổ chi tiêu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CustomPainter',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DonutChartPainter(
                      categoryTotals: widget.categoryTotals,
                      total: widget.totalExpense,
                      progress: _animation.value,
                      selectedCategory: _selectedCategory,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCategory != null
                                ? _selectedCategory!.displayName
                                : 'Tổng chi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCategory != null
                                ? CurrencyFormatter.format(
                                    widget.categoryTotals[_selectedCategory] ?? 0.0)
                                : CurrencyFormatter.formatCompact(widget.totalExpense),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (_selectedCategory != null && widget.totalExpense > 0)
                            Text(
                              '${(((widget.categoryTotals[_selectedCategory] ?? 0) / widget.totalExpense) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedCategory!.color,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Interactive Category Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: ExpenseCategory.values.map((cat) {
              final amount = widget.categoryTotals[cat] ?? 0.0;
              if (amount <= 0) return const SizedBox.shrink();
              final percent = (amount / widget.totalExpense) * 100;
              final isSelected = _selectedCategory == cat;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : cat;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color.withOpacity(0.15) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? cat.color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: cat.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${percent.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> categoryTotals;
  final double total;
  final double progress;
  final ExpenseCategory? selectedCategory;

  _DonutChartPainter({
    required this.categoryTotals,
    required this.total,
    required this.progress,
    this.selectedCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const baseStrokeWidth = 28.0;

    // Draw background track ring
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStrokeWidth;
    canvas.drawCircle(center, radius - baseStrokeWidth / 2, bgPaint);

    if (total <= 0) return;

    double startAngle = -math.pi / 2; // Start from 12 o'clock

    for (var cat in ExpenseCategory.values) {
      final amount = categoryTotals[cat] ?? 0.0;
      if (amount <= 0) continue;

      final sliceFraction = amount / total;
      final sweepAngle = sliceFraction * 2 * math.pi * progress;

      final isSelected = selectedCategory == cat;
      final currentStroke = isSelected ? baseStrokeWidth + 6 : baseStrokeWidth;

      final slicePaint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.round;

      // Draw subtle shadow for selected slice
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = cat.color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStroke + 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - baseStrokeWidth / 2),
          startAngle + 0.03,
          sweepAngle - 0.06 > 0 ? sweepAngle - 0.06 : sweepAngle,
          false,
          shadowPaint,
        );
      }

      // Small gap between arcs
      final adjustedSweep = sweepAngle > 0.08 ? sweepAngle - 0.05 : sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - baseStrokeWidth / 2),
        startAngle + 0.025,
        adjustedSweep,
        false,
        slicePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.total != total;
  }
}
