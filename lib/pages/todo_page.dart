import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => TodoPageState();
}

class TodoPageState extends State<TodoPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _todoController = TextEditingController();

  DateTime? _selectedDueDateTime;
  String _selectedPriority = 'none';

  final List<String> _priorities = ['high', 'medium', 'low', 'none'];

  void _addTaskFromDialog() async {
    String taskText = _todoController.text.trim();
    if (taskText.isEmpty || currentUser == null) return;

    int priorityIndex = 3;
    if (_selectedPriority == 'high') priorityIndex = 0;
    if (_selectedPriority == 'medium') priorityIndex = 1;
    if (_selectedPriority == 'low') priorityIndex = 2;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('todos')
        .add({
      'title': taskText,
      'isCompleted': false,
      'priority': _selectedPriority,
      'priorityIndex': priorityIndex,
      'startDate': FieldValue.serverTimestamp(),
      'dueDate': _selectedDueDateTime != null ? Timestamp.fromDate(_selectedDueDateTime!) : null,
    });

    _todoController.clear();
    _selectedDueDateTime = null;
    _selectedPriority = 'none';
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

  void showAddTaskDialog() {
    _todoController.clear();
    _selectedDueDateTime = null;
    _selectedPriority = 'none';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Add New Task",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Priority", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPriority,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        isExpanded: true,
                        items: _priorities.map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              _selectedPriority = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text("Task", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _todoController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "What needs to be done?",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text("Due Date & Time", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      DateTime now = DateTime.now();

                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );

                      if (pickedDate != null) {
                        if (!context.mounted) return;
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (pickedTime != null) {
                          DateTime combinedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );

                          if (combinedDateTime.isBefore(DateTime.now())) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Selected time has already passed!")),
                            );
                            return;
                          }

                          setDialogState(() {
                            _selectedDueDateTime = combinedDateTime;
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDueDateTime == null
                                ? "No due date set"
                                : DateFormat('dd/MM/yyyy hh:mm a').format(_selectedDueDateTime!),
                            style: TextStyle(
                              color: _selectedDueDateTime == null ? Colors.grey : Colors.white,
                              fontWeight: _selectedDueDateTime == null ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.calendar_month_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
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

  Stream<QuerySnapshot> _getGlobalTodosStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('todos')
        .orderBy('priorityIndex', descending: false)
        .orderBy('startDate', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _todoController.dispose();
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getGlobalTodosStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

          var tasks = snapshot.data!.docs;

          if (tasks.isEmpty) {
            return const Center(child: Text("No tasks created yet!", style: TextStyle(color: Colors.grey)));
          }

          DateTime systemNow = DateTime.now();

          return ListView.builder(
            itemCount: tasks.length,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemBuilder: (context, index) {
              var taskDoc = tasks[index];
              var taskData = taskDoc.data() as Map<String, dynamic>;
              String docId = taskDoc.id;
              bool isCompleted = taskData['isCompleted'] ?? false;
              String priority = taskData['priority'] ?? 'none';

              String dueText = "";
              bool isOverdue = false;

              if (taskData['dueDate'] != null) {
                DateTime dueDateTime = (taskData['dueDate'] as Timestamp).toDate();
                dueText = "Due: ${DateFormat('dd/MM/yyyy hh:mm a').format(dueDateTime)}";

                if (dueDateTime.isBefore(systemNow) && !isCompleted) {
                  isOverdue = true;
                }
              }

              Color priorityColor = Colors.grey;
              if (priority == 'high') priorityColor = Colors.red;
              if (priority == 'medium') priorityColor = Colors.orange;
              if (priority == 'low') priorityColor = Colors.blue;

              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOverdue)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Text(
                          "⚠️ Due Date Completed - Not Done",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ListTile(
                      leading: Checkbox(
                        activeColor: Colors.black,
                        value: isCompleted,
                        onChanged: (val) => _toggleTask(docId, isCompleted),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              taskData['title'] ?? '',
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                color: isCompleted ? Colors.grey : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (priority != 'none')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                priority.toUpperCase(),
                                style: TextStyle(fontSize: 10, color: priorityColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: dueText.isNotEmpty
                          ? Text(dueText, style: TextStyle(fontSize: 12, color: isOverdue ? Colors.red : Colors.grey[600]))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteTask(docId),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}