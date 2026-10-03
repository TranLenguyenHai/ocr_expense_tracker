import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/expense_transaction.dart';
import '../../providers/expense_provider.dart';
import '../details/transaction_detail_screen.dart';

class TransactionListTab extends StatelessWidget {
  const TransactionListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final list = provider.filteredTransactions;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sổ Thu Chi Sinh Viên',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Quản lý chi tiêu qua hóa đơn thông minh',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      onChanged: (val) => provider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm cửa hàng, ghi chú...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Tất cả',
                            isSelected: provider.categoryFilter == null,
                            color: const Color(0xFF4F46E5),
                            onTap: () => provider.setCategoryFilter(null),
                          ),
                          ...ExpenseCategory.values.map((cat) {
                            final isSel = provider.categoryFilter == cat;
                            return _buildFilterChip(
                              label: cat.vietnameseName,
                              icon: cat.icon,
                              isSelected: isSel,
                              color: cat.color,
                              onTap: () => provider.setCategoryFilter(isSel ? null : cat),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  provider.searchQuery.isNotEmpty || provider.categoryFilter != null
                                      ? 'Không tìm thấy chi tiêu phù hợp'
                                      : 'Chưa có khoản chi tiêu nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Chạm nút camera bên dưới để quét hóa đơn mới',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final item = list[index];
                              return _buildTransactionCard(context, item, provider);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    ExpenseTransaction item,
    ExpenseProvider provider,
  ) {
    final cat = item.category;
    final hasImage = item.imagePath != null &&
        item.imagePath!.isNotEmpty &&
        File(item.imagePath!).existsSync();

    return Dismissible(
      key: Key(item.id?.toString() ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text('Bạn có chắc muốn xóa giao dịch tại "${item.merchant}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (item.id != null) provider.deleteTransaction(item.id!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(cat.icon, color: cat.color, size: 24),
          ),
          title: Text(
            item.merchant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.formatDate(item.date),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.vietnameseName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cat.color,
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.image_outlined, size: 14, color: Color(0xFF4F46E5)),
                  ],
                ],
              ),
              if (item.note != null && item.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
          trailing: Text(
            CurrencyFormatter.format(item.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(transaction: item),
              ),
            );
          },
        ),
      ),
    );
  }
}
