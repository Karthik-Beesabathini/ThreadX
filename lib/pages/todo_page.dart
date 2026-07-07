import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => TodoPageState();
}

class TodoPageState extends State<TodoPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _todoController = TextEditingController();

  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Act/Ass', 'Quizzes'];
  final PageController _pageController = PageController(initialPage: 0);

  DateTime? _selectedDueDate;

  void _addTaskFromDialog() async {
    String taskText = _todoController.text.trim();
    if (taskText.isEmpty || currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('todos')
        .add({
      'title': taskText,
      'category': _selectedCategory,
      'isCompleted': false,
      'startDate': FieldValue.serverTimestamp(),
      'dueDate': _selectedDueDate != null ? Timestamp.fromDate(_selectedDueDate!) : null,
    });

    _todoController.clear();
    _selectedDueDate = null;
  }

  void _toggleTask(String docId, bool currentStatus) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('todos')
        .doc(docId)
        .update({'isCompleted': !currentStatus});
  }

  void _deleteTask(String docId) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('todos')
        .doc(docId)
        .delete();
  }

  // Public so HomePage's single shared FAB can trigger this via GlobalKey —
  // TodoPage no longer owns its own FloatingActionButton.
  void showAddTaskDialog() {
    _todoController.clear();
    _selectedDueDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "Add Task to $_selectedCategory",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Title Input field
                TextField(
                  controller: _todoController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "What needs to be done?",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Optional Calendar Date picker anchor row
                const Text("Due Date (Optional)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        _selectedDueDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDueDate == null
                              ? "No due date set"
                              : "${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}",
                          style: TextStyle(
                            color: _selectedDueDate == null ? Colors.grey[600] : Colors.black,
                            fontWeight: _selectedDueDate == null ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.calendar_month_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _todoController.clear();
                  _selectedDueDate = null;
                },
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (_todoController.text.trim().isNotEmpty) {
                    _addTaskFromDialog();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredTodosStream(String category) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('todos')
        .where('category', isEqualTo: category)
        .orderBy('startDate', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _todoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please login to see tasks.")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("MY TASKS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                String cat = _categories[index];
                bool isSelected = _selectedCategory == cat;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.black,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() { _selectedCategory = cat; });
                        _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),

      // ✅ CLEAN BODY: No squeezed overlapping input layouts at the base
      body: PageView.builder(
        controller: _pageController,
        itemCount: _categories.length,
        onPageChanged: (int index) {
          setState(() { _selectedCategory = _categories[index]; });
        },
        itemBuilder: (context, pageIndex) {
          String currentPageCategory = _categories[pageIndex];

          return StreamBuilder<QuerySnapshot>(
            stream: _getFilteredTodosStream(currentPageCategory),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

              var tasks = snapshot.data!.docs;
              if (tasks.isEmpty) {
                return Center(child: Text("No items in $currentPageCategory yet!", style: const TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                itemCount: tasks.length,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra bottom padding so items don't hide behind buttons
                itemBuilder: (context, index) {
                  var taskDoc = tasks[index];
                  var taskData = taskDoc.data() as Map<String, dynamic>;
                  String docId = taskDoc.id;
                  bool isCompleted = taskData['isCompleted'] ?? false;

                  String dueText = "";
                  if (taskData['dueDate'] != null) {
                    DateTime dueDateTime = (taskData['dueDate'] as Timestamp).toDate();
                    dueText = "Due: ${dueDateTime.day}/${dueDateTime.month}/${dueDateTime.year}";
                  }

                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Checkbox(
                        activeColor: Colors.black,
                        value: isCompleted,
                        onChanged: (val) => _toggleTask(docId, isCompleted),
                      ),
                      title: Text(
                        taskData['title'] ?? '',
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          color: isCompleted ? Colors.grey : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: dueText.isNotEmpty
                          ? Text(dueText, style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteTask(docId),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}