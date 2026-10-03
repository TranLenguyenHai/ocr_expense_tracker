import 'package:flutter/material.dart';
import '../analytics/analytics_screen.dart';
import '../camera/camera_viewfinder_screen.dart';
import 'transaction_list_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TransactionListTab(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: const Color(0xFF4F46E5),
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraViewfinderScreen(),
            ),
          );
        },
        child: const Icon(
          Icons.document_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 1: Transactions
              InkWell(
                onTap: () => setState(() => _currentIndex = 0),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentIndex == 0
                            ? Icons.account_balance_wallet_rounded
                            : Icons.account_balance_wallet_outlined,
                        color: _currentIndex == 0
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF94A3B8),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thu Chi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _currentIndex == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _currentIndex == 0
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 48), // Gap for docked FloatingActionButton

              // Tab 2: Analytics & CustomPainter Charts
              InkWell(
                onTap: () => setState(() => _currentIndex = 1),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentIndex == 1
                            ? Icons.pie_chart_rounded
                            : Icons.pie_chart_outline_rounded,
                        color: _currentIndex == 1
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF94A3B8),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Thống kê',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _currentIndex == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _currentIndex == 1
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
