import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => ExpensesPageState();
}

class ExpensesPageState extends State<ExpensesPage> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  // List of all months for our selection logic
  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  // Track the currently selected month on the main dashboard view
  late String _selectedViewMonth;

  @override
  void initState() {
    super.initState();
    // Default to current calendar month on startup
    _resetToCurrentMonth();
  }

  // Method to easily jump back to the current real-world month
  void _resetToCurrentMonth() {
    setState(() {
      _selectedViewMonth = _months[DateTime.now().month - 1];
    });
  }

  // Public method that HomePage's shared FloatingActionButton can target via GlobalKey
  void showAddExpenseDialog() {
    final causeController = TextEditingController();
    final amountController = TextEditingController();
    String dialogSelectedMonth = _selectedViewMonth; // Default to current dashboard month

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Add New Expense", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Month Dropdown Selector Inside Dialog
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dialogSelectedMonth,
                      isExpanded: true,
                      menuMaxHeight: 250, // Limits dialog dropdown layout view extension size
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _months.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month, style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setDialogState(() => dialogSelectedMonth = newValue);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Cause TextField
                TextField(
                  controller: causeController,
                  decoration: InputDecoration(
                    hintText: "What was this for?",
                    labelText: "Cause / Description",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Amount TextField
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    labelText: "Amount (Money)",
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("₹", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final cause = causeController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;

                if (cause.isNotEmpty && amount > 0) {
                  if (_currentUser == null) return;

                  // Save record down into a subcollection grouped by month entries
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser.uid)
                      .collection('expenses')
                      .add({
                    'month': dialogSelectedMonth,
                    'cause': cause,
                    'amount': amount,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save Expense", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Opens a custom inline dialog to edit an existing expense configuration record
  void _showEditExpenseDialog(String docId, String currentCause, double currentAmount, String currentMonth) {
    final causeController = TextEditingController(text: currentCause);
    final amountController = TextEditingController(text: currentAmount.toString());
    String dialogSelectedMonth = currentMonth;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Edit Expense", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dialogSelectedMonth,
                      isExpanded: true,
                      menuMaxHeight: 250,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _months.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month, style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setDialogState(() => dialogSelectedMonth = newValue);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: causeController,
                  decoration: InputDecoration(
                    labelText: "Cause / Description",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "Amount (Money)",
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("₹", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final cause = causeController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;

                if (cause.isNotEmpty && amount > 0) {
                  if (_currentUser == null) return;

                  // Update the targeted transaction record securely in Cloud Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser.uid)
                      .collection('expenses')
                      .doc(docId)
                      .update({
                    'month': dialogSelectedMonth,
                    'cause': cause,
                    'amount': amount,
                  });

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Opens an options menu tray when an item card is interacting with the user
  void _showOptionsBottomSheet(String docId, String cause, double amount, String month) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
              title: const TextStyle(fontWeight: FontWeight.w600).text("Edit Expense"),
              onTap: () {
                Navigator.pop(context);
                _showEditExpenseDialog(docId, cause, amount, month);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const TextStyle(fontWeight: FontWeight.w600).text("Delete Expense"),
              onTap: () async {
                Navigator.pop(context);
                if (_currentUser == null) return;

                // Absolute structural removal statement targeting collection ID matching keys
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser.uid)
                    .collection('expenses')
                    .doc(docId)
                    .delete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text("Please login to see expenses"));
    }

    // Determine if the user is currently looking at the actual present month
    String currentRealMonth = _months[DateTime.now().month - 1];
    bool isPresentMonth = _selectedViewMonth == currentRealMonth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Row container handling back reset button and custom header dropdown selection
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Row(
              children: [
                // Clean UI Condition: Only render back button if NOT looking at the present month
                if (!isPresentMonth) ...[
                  InkWell(
                    onTap: _resetToCurrentMonth,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Custom header pill dropdown
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.grey[200]!, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedViewMonth,
                        icon: Icon(Icons.unfold_more_rounded, color: Colors.grey[600], size: 20),
                        isExpanded: true,
                        menuMaxHeight: 250,
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        items: _months.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _selectedViewMonth = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real-time listener streaming data matching the chosen filter month
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser.uid)
                  .collection('expenses')
                  .where('month', isEqualTo: _selectedViewMonth)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                // Gather document snapshots securely
                List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

                // Sort the items completely in memory locally (Newest transactions first)
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final Timestamp? aTime = aData['timestamp'] as Timestamp?;
                  final Timestamp? bTime = bData['timestamp'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                // Real-time calculation loop dynamically adding the total money spent
                double totalExpenses = 0.0;
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalExpenses += (data['amount'] ?? 0.0).toDouble();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No expenses tracked for $_selectedViewMonth",
                      style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final String cause = data['cause'] ?? '';
                          final double amount = (data['amount'] ?? 0.0).toDouble();
                          final String month = data['month'] ?? _selectedViewMonth;

                          return Card(
                            color: Colors.grey[50],
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              // Open control options tray on short tap or long press interaction
                              onTap: () => _showOptionsBottomSheet(doc.id, cause, amount, month),
                              onLongPress: () => _showOptionsBottomSheet(doc.id, cause, amount, month),
                              child: ListTile(
                                title: Text(cause, style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Text(
                                  "₹${amount.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Persistent footer area tracking current sum total
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total for $_selectedViewMonth",
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            "₹${totalExpenses.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                    // Adds explicit spacing block to push content clean of the center action button
                    const SizedBox(height: 76),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Micro extension method to quickly map styling to text widgets cleanly inside builders
extension TextStyleExtension on TextStyle {
  Widget text(String content) => Text(content, style: this);
}