import 'package:flutter/material.dart';
import 'todo_page.dart';
import 'expenses_page.dart';

class TodoExpensesPage extends StatefulWidget {
  final GlobalKey<TodoPageState> todoKey;
  final GlobalKey<ExpensesPageState> expensesKey;

  const TodoExpensesPage({
    super.key,
    required this.todoKey,
    required this.expensesKey,
  });

  @override
  State<TodoExpensesPage> createState() => TodoExpensesPageState();
}

class TodoExpensesPageState extends State<TodoExpensesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Allocating 2 tabs: Index 0 for Todo, Index 1 for Expenses
    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab/swipe changes to tell the HomePage to update its FAB action if needed
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Trigger a rebuild of the parent layout when user finishes a swipe gesture
        if (mounted) setState(() {});
      }
    });
  }

  // Exposed helper method so HomePage can check which tab is currently active
  int get activeSubTabIndex => _tabController.index;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the top level with SafeArea to push the menu down below the phone's notch
    return SafeArea(
      bottom: false, // Prevents adding unwanted padding above the bottom navigation bar
      child: Column(
        children: [
          // Clean, rounded custom switcher matching your aesthetic choices
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: "Todo List"),
                Tab(text: "Expenses"),
              ],
            ),
          ),

          // The swipable body wrapper container
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TodoPage(key: widget.todoKey),
                ExpensesPage(key: widget.expensesKey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}