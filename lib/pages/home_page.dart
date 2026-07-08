import 'package:calc_app/pages/game_page.dart';
import 'package:calc_app/pages/todo_expenses.page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:calc_app/pages/feed_page.dart';
import 'package:calc_app/pages/todo_page.dart';
import 'package:calc_app/pages/profile_page.dart';
import 'package:calc_app/pages/create_post_page.dart';
import 'package:calc_app/pages/expenses_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;

  //generally i need fab button to execute different things in different pages soo
  final GlobalKey<TodoPageState> _todoPageKey = GlobalKey<TodoPageState>();

  // Dynamic keys to access the nested swipable tabs framework
  final GlobalKey<ExpensesPageState> _expensesPageKey = GlobalKey<ExpensesPageState>();
  final GlobalKey<TodoExpensesPageState> _swipeTabsKey = GlobalKey<TodoExpensesPageState>();

  // Explicit ScrollController tracking to force layout view snaps upon navigation tap
  final ScrollController _profileScrollController = ScrollController();

  late final List<Widget> _pages = [
    const FeedPage(),
    TodoExpensesPage(
      key: _swipeTabsKey,
      todoKey: _todoPageKey,
      expensesKey: _expensesPageKey,
    ), // Replaced standalone TodoPage with the dynamic swipe manager
    const SizedBox(),
    const GamePage(),
    ProfilePage(scrollController: _profileScrollController), // Pass the controller here
  ];

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPromptUsername();
      });
    }
  }

  void _checkAndPromptUsername() async {
    if (currentUser == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!userDoc.exists ||
        userDoc.data() == null ||
        (userDoc.data()?['username'] ?? '').toString().trim().isEmpty) {
      _showUsernameDialog();
    }
  }

  void _showUsernameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Setup Username"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter unique username"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .set({'username': name, 'email': currentUser!.email});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _authGuard(VoidCallback action) {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to continue!")),
      );
    } else {
      action();
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    bool isSelected = _currentIndex == index;
    Color itemColor = isSelected ? Colors.black : Colors.grey[500]!;

    return Expanded(
      child: InkWell(
        onTap: () {
          // If switching to the Profile tab, instantly snap its scroll position back to the top
          if (index == 4) {
            if (_profileScrollController.hasClients) {
              _profileScrollController.jumpTo(0);
            }
          }
          setState(() => _currentIndex = index);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.black.withValues(alpha: 0.06),
        highlightColor: Colors.black.withValues(alpha: 0.03),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: itemColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


// only one fab excutes different things in different pages
  Widget? _buildContextualFab() {
    switch (_currentIndex) {
    //in thread page naa it is used to create post
      case 0:
        return FloatingActionButton(
          onPressed: () {
            _authGuard(() {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => const CreatePostPage(),
              );
            });
          },
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        );
    //in Todo page to add task
      case 1:
        return FloatingActionButton(
          onPressed: () {
            _authGuard(() {
              // Read which sub-tab user is on before sending the GlobalKey trigger
              final subIndex = _swipeTabsKey.currentState?.activeSubTabIndex ?? 0;
              if (subIndex == 0) {
                _todoPageKey.currentState?.showAddTaskDialog();
              } else {
                _expensesPageKey.currentState?.showAddExpenseDialog();
              }
            });
          },
          backgroundColor: Colors.black,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        );

    // in others pages we don't need fab button
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // bug fixed here to not resize keyboard
      resizeToAvoidBottomInset: false,

      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildContextualFab(),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //method to create bottom nav bar properly
              _buildNavItem(
                index: 0,
                icon: _currentIndex == 0 ? Icons.view_stream_rounded : Icons.view_stream_outlined,
                label: "Thread",
              ),
              _buildNavItem(
                index: 1,
                icon: _currentIndex == 1 ? Icons.task_alt : Icons.task_alt_outlined,
                label: "Todo List",
              ),

              const SizedBox(width: 48), // Explicit layout spacing for center FloatingActionButton

              _buildNavItem(
                index: 3,
                icon: _currentIndex == 3 ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                label: "Games",
              ),
              _buildNavItem(
                index: 4,
                icon: _currentIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded,
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}