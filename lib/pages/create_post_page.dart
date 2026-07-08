import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  final _titleController = TextEditingController();
  final _postController = TextEditingController();

  final List<String> _categories = [
    'General',
    'college',
    'ground',
    'hostels',
    'Cse',
    'ece',
    'IntMtech',
    'mech'
  ];

  String _selectedCategory = 'General';
  bool _isLoading = false;

  void _uploadPost() async {
    if (_titleController.text.trim().isEmpty || _postController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out both the title and the content!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text.trim(),
        'text': _postController.text.trim(),
        'category': _selectedCategory,
        'authorId': currentUser?.uid ?? 'anonymous_user',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _postController.clear();

      if (!context.mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published successfully!')),
      );
    } catch (e) {
      if (!context.mounted) return;

      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Create a new post",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Corrected DropdownMenu implementation
            Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thumbVisibility: WidgetStateProperty.all(true),
                  thickness: WidgetStateProperty.all(6.0),
                  thumbColor: WidgetStateProperty.all(Colors.black.withOpacity(0.5)),
                  radius: const Radius.circular(4),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return DropdownMenu<String>(
                    initialSelection: _selectedCategory,
                    menuHeight: 220,
                    width: constraints.maxWidth,
                    label: const Text("Select Category / Branch"),
                    inputDecorationTheme: InputDecorationTheme(
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    dropdownMenuEntries: _categories.map((String category) {
                      return DropdownMenuEntry<String>(
                        value: category,
                        label: category,
                      );
                    }).toList(),
                    onSelected: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Enter a catchy title...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _postController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 15),

            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : ElevatedButton.icon(
              onPressed: _uploadPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.share),
              label: const Text("Share Post", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}