import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  String? _targetCommentId;
  String? _targetCommentAuthor;
  String? _targetReplyAuthorId;

  final Map<String, String> _usernameCache = {};

  Widget _buildLiveUsername(String authorId, {TextStyle? style, String prefix = ""}) {
    if (_usernameCache.containsKey(authorId)) {
      return Text("$prefix${_usernameCache[authorId]}", style: style);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
      builder: (context, snapshot) {
        String name = "Anonymous";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['username'] ?? 'Anonymous';
          _usernameCache[authorId] = name;
        }
        return Text("$prefix$name", style: style);
      },
    );
  }

  // --- CREATE ACTIONS ---
  void _handleSubmit() async {
    String text = _inputController.text.trim();
    if (text.isEmpty) return;

    try {
      if (_targetCommentId == null) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .add({
          'text': text,
          'authorId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(_targetCommentId)
            .collection('replies')
            .add({
          'text': text,
          'authorId': currentUser.uid,
          'targetReplyAuthorId': _targetReplyAuthorId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _inputController.clear();
      _cancelReplyMode();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- EDIT ACTIONS ---
  void _showEditDialog({required bool isReply, required String commentId, String? replyId, required String initialText}) {
    final editController = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReply ? "Edit Reply" : "Edit Comment", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Update your message..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              String newText = editController.text.trim();
              if (newText.isEmpty) return;
              Navigator.pop(context);

              try {
                if (!isReply) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .update({'text': newText});
                } else {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .collection('replies')
                      .doc(replyId)
                      .update({'text': newText});
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- DELETE ACTIONS ---
  void _showDeleteDialog({required bool isReply, required String commentId, String? replyId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReply ? "Delete Reply?" : "Delete Comment?"),
        content: Text(isReply ? "This reply will be permanently removed." : "This comment and its nested replies will be permanently removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (!isReply) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .delete();
                } else {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .collection('replies')
                      .doc(replyId)
                      .delete();
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _enterReplyMode(String commentId, String authorId, {bool isSubReply = false}) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(authorId).get();
    String activeName = doc.data()?['username'] ?? 'User';

    setState(() {
      _targetCommentId = commentId;
      _targetCommentAuthor = activeName;
      _targetReplyAuthorId = isSubReply ? authorId : null;
    });
    _inputFocusNode.requestFocus();
  }

  void _cancelReplyMode() {
    setState(() {
      _targetCommentId = null;
      _targetCommentAuthor = null;
      _targetReplyAuthorId = null;
    });
    _inputFocusNode.unfocus();
  }

  void _handleVote(String fieldName) async {
    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    DocumentSnapshot doc = await postRef.get();

    if (!context.mounted) return;

    final data = doc.data() as Map<String, dynamic>?;
    List currentArray = (data != null && data[fieldName] is List) ? data[fieldName] : [];

    if (currentArray.contains(currentUser.uid)) {
      postRef.update({fieldName: FieldValue.arrayRemove([currentUser.uid])});
    } else {
      postRef.update({fieldName: FieldValue.arrayUnion([currentUser.uid])});

      if (fieldName == 'upvotes') {
        postRef.update({'downvotes': FieldValue.arrayRemove([currentUser.uid])});
      } else if (fieldName == 'downvotes') {
        postRef.update({'upvotes': FieldValue.arrayRemove([currentUser.uid])});
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true, // Seamless standard inset adjustments
      appBar: AppBar(
        title: Text(widget.postData['category'] ?? 'Post'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
                    builder: (context, snapshot) {
                      var upvotes = [];
                      var downvotes = [];
                      var hearts = [];

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null) {
                          upvotes = data['upvotes'] is List ? data['upvotes'] : [];
                          downvotes = data['downvotes'] is List ? data['downvotes'] : [];
                          hearts = data['hearts'] is List ? data['hearts'] : [];
                        }
                      }

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLiveUsername(
                                widget.postData['authorId'] ?? '',
                                prefix: "u/",
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text(widget.postData['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Text(widget.postData['text'] ?? '', style: const TextStyle(fontSize: 15, height: 1.4)),
                              const SizedBox(height: 15),
                              const Divider(),

                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_upward, color: upvotes.contains(currentUser.uid) ? Colors.orange : Colors.grey),
                                    onPressed: () => _handleVote('upvotes'),
                                  ),
                                  Text('${upvotes.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: Icon(Icons.arrow_downward, color: downvotes.contains(currentUser.uid) ? Colors.blue : Colors.grey),
                                    onPressed: () => _handleVote('downvotes'),
                                  ),
                                  Text('${downvotes.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.favorite, color: hearts.contains(currentUser.uid) ? Colors.red : Colors.grey),
                                    onPressed: () => _handleVote('hearts'),
                                  ),
                                  Text('${hearts.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const Text("Comments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // PRIMARY STREAM: Post Comments
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
                      var comments = snapshot.data!.docs;

                      if (comments.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Text("No comments yet. Start the conversation!", style: TextStyle(color: Colors.grey)),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var commentDoc = comments[index];
                          var commentData = commentDoc.data() as Map<String, dynamic>;
                          String commentId = commentDoc.id;
                          String commentAuthorId = commentData['authorId'] ?? '';
                          String commentText = commentData['text'] ?? '';

                          bool isMyComment = commentAuthorId == currentUser.uid;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildLiveUsername(
                                            commentAuthorId,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          if (isMyComment)
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_horiz, size: 18, color: Colors.black54),
                                              onSelected: (val) {
                                                if (val == 'edit') _showEditDialog(isReply: false, commentId: commentId, initialText: commentText);
                                                if (val == 'delete') _showDeleteDialog(isReply: false, commentId: commentId);
                                              },
                                              itemBuilder: (c) => [
                                                const PopupMenuItem(value: 'edit', child: Text("Edit Comment")),
                                                const PopupMenuItem(value: 'delete', child: Text("Delete Comment", style: TextStyle(color: Colors.red))),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(commentText, style: const TextStyle(color: Colors.black87, fontSize: 14)),

                                      if (!isMyComment)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            icon: const Icon(Icons.reply, size: 16, color: Colors.blue),
                                            label: const Text("Reply", style: TextStyle(fontSize: 12, color: Colors.blue)),
                                            onPressed: () => _enterReplyMode(commentId, commentAuthorId),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ),

                              // NESTED SECONDARY STREAM BUILDER: Replies
                              Padding(
                                padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .collection('comments')
                                      .doc(commentId)
                                      .collection('replies')
                                      .orderBy('timestamp', descending: false)
                                      .snapshots(),
                                  builder: (context, replySnapshot) {
                                    if (!replySnapshot.hasData) return const SizedBox();
                                    var replies = replySnapshot.data!.docs;

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: replies.length,
                                      itemBuilder: (context, rIndex) {
                                        var replyDoc = replies[rIndex];
                                        var replyData = replyDoc.data() as Map<String, dynamic>;
                                        String replyId = replyDoc.id;
                                        String replyAuthorId = replyData['authorId'] ?? '';
                                        String replyText = replyData['text'] ?? '';
                                        String? targetedUser = replyData['targetReplyAuthorId'];

                                        bool isMyReply = replyAuthorId == currentUser.uid;

                                        return Card(
                                          color: Colors.grey[50],
                                          elevation: 0,
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    _buildLiveUsername(
                                                      replyAuthorId,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                                    ),
                                                    if (isMyReply)
                                                      PopupMenuButton<String>(
                                                        icon: const Icon(Icons.more_horiz, size: 16, color: Colors.black54),
                                                        onSelected: (val) {
                                                          if (val == 'edit') _showEditDialog(isReply: true, commentId: commentId, replyId: replyId, initialText: replyText);
                                                          if (val == 'delete') _showDeleteDialog(isReply: true, commentId: commentId, replyId: replyId);
                                                        },
                                                        itemBuilder: (c) => [
                                                          const PopupMenuItem(value: 'edit', child: Text("Edit Reply")),
                                                          const PopupMenuItem(value: 'delete', child: Text("Delete Reply", style: TextStyle(color: Colors.red))),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),

                                                RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                                    children: [
                                                      if (targetedUser != null) ...[
                                                        WidgetSpan(
                                                          alignment: PlaceholderAlignment.middle,
                                                          child: FutureBuilder<DocumentSnapshot>(
                                                            future: FirebaseFirestore.instance.collection('users').doc(targetedUser).get(),
                                                            builder: (context, userSnap) {
                                                              String name = "...";
                                                              if (userSnap.hasData && userSnap.data!.exists) {
                                                                name = (userSnap.data!.data() as Map<String, dynamic>?)?['username'] ?? 'User';
                                                              }
                                                              return Text(
                                                                "@$name ",
                                                                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                      TextSpan(text: replyText),
                                                    ],
                                                  ),
                                                ),

                                                if (!isMyReply)
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: TextButton.icon(
                                                      icon: const Icon(Icons.reply, size: 14, color: Colors.blue),
                                                      label: const Text("Reply", style: TextStyle(fontSize: 11, color: Colors.blue)),
                                                      onPressed: () => _enterReplyMode(commentId, replyAuthorId, isSubReply: true),
                                                    ),
                                                  )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // STICKY CONTEXT INPUT FOOTER
          Container(
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_targetCommentId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Replying to u/$_targetCommentAuthor...", style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: _cancelReplyMode,
                          child: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                        )
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _inputFocusNode,
                        decoration: InputDecoration(
                          hintText: _targetCommentId == null ? "Add a comment..." : "Write your reply...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _handleSubmit,
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}