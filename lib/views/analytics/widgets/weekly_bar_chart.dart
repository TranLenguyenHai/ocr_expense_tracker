import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<double> weeklyTotals;
  final DateTime weekStart;

  const WeeklyBarChart({
    super.key,
    required this.weeklyTotals,
    required this.weekStart,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.weeklyTotals.fold(0.0, (m, v) => math.max(m, v));
    final totalWeek = widget.weeklyTotals.fold(0.0, (s, v) => s + v);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiêu trong tuần',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tổng: ${CurrencyFormatter.format(totalWeek)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CustomPainter',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0891B2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar Chart Canvas
          GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final width = box.size.width - 40; // minus padding
              final barSpacing = width / 7;
              final tapX = details.localPosition.dx;
              final index = (tapX / barSpacing).floor().clamp(0, 6);
              setState(() {
                _selectedBarIndex = _selectedBarIndex == index ? null : index;
              });
            },
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WeeklyBarChartPainter(
                      weeklyTotals: widget.weeklyTotals,
                      maxValue: maxAmount > 0 ? maxAmount : 100000,
                      progress: _animation.value,
                      selectedIndex: _selectedBarIndex,
                      todayIndex: DateTime.now().weekday - 1,
                    ),
                  );
                },
              ),
            ),
          ),
          if (_selectedBarIndex != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_getDayName(_selectedBarIndex!)}: ${CurrencyFormatter.format(widget.weeklyTotals[_selectedBarIndex!])}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDayName(int index) {
    const names = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    return names[index];
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<double> weeklyTotals;
  final double maxValue;
  final double progress;
  final int? selectedIndex;
  final int todayIndex;

  _WeeklyBarChartPainter({
    required this.weeklyTotals,
    required this.maxValue,
    required this.progress,
    this.selectedIndex,
    required this.todayIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 24.0;
    const topPadding = 24.0;
    final chartHeight = size.height - bottomLabelHeight - topPadding;
    final columnWidth = size.width / 7;
    const barWidth = 22.0;

    // 1. Draw horizontal gridlines (3 lines: 100%, 50%, 0%)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 2; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    // 2. Draw each bar
    for (int i = 0; i < 7; i++) {
      final amount = i < weeklyTotals.length ? weeklyTotals[i] : 0.0;
      final ratio = (amount / maxValue).clamp(0.0, 1.0);
      final barHeight = chartHeight * ratio * progress;

      final centerX = columnWidth * i + columnWidth / 2;
      final left = centerX - barWidth / 2;
      final top = topPadding + chartHeight - barHeight;
      final bottom = topPadding + chartHeight;

      final isSelected = selectedIndex == i;
      final isToday = todayIndex == i;

      // Draw background bar track
      final trackPaint = Paint()
        ..color = const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, topPadding, left + barWidth, bottom),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Draw active bar if height > 0
      if (barHeight > 0) {
        final barRect = Rect.fromLTRB(left, top, left + barWidth, bottom);
        final roundedBar = RRect.fromRectAndRadius(
          barRect,
          const Radius.circular(8),
        );

        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isSelected
              ? [const Color(0xFFF43F5E), const Color(0xFFE11D48)]
              : isToday
                  ? [const Color(0xFF4F46E5), const Color(0xFF6366F1)]
                  : [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
        );

        final barPaint = Paint()
          ..shader = gradient.createShader(barRect)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(roundedBar, barPaint);

        // Draw amount text above bar
        if (amount > 0 && progress > 0.7) {
          final textSpan = TextSpan(
            text: CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFFE11D48)
                  : const Color(0xFF64748B),
            ),
          );
          final tp = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(canvas, Offset(centerX - tp.width / 2, top - tp.height - 3));
        }
      }

      // 3. Draw day labels at bottom
      final dayTextSpan = TextSpan(
        text: dayLabels[i],
        style: TextStyle(
          fontSize: 12,
          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
          color: isToday
              ? const Color(0xFF4F46E5)
              : isSelected
                  ? const Color(0xFFE11D48)
                  : const Color(0xFF94A3B8),
        ),
      );
      final dayPainter = TextPainter(
        text: dayTextSpan,
        textDirection: TextDirection.ltr,
      );
      dayPainter.layout();
      dayPainter.paint(
        canvas,
        Offset(centerX - dayPainter.width / 2, bottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.maxValue != maxValue;
  }
}
