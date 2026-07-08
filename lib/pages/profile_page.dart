import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:calc_app/pages/post_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

// Import our modular sub-widgets (Adjust path matching your folder names)
import 'profile_header.dart';
import 'action_row_group.dart';
import 'developer_footer.dart';

class ProfilePage extends StatefulWidget {
  final ScrollController scrollController; // Captured structural scrolling controller

  const ProfilePage({
    super.key,
    required this.scrollController, // Received parameter constructor mapping
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  Future<void> signUserOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  void _editUsername(BuildContext context, String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Username", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter new username",
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({'username': newName});
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username updated successfully!")));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save username: $e")));
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _deletePost(String postId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This will permanently remove this post and all its comments."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post removed successfully.")));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting post: $e")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $urlString')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
    }
  }

  void _showDeveloperSheet(BuildContext context, {required String name, required String githubUrl, required String linkedinUrl}) {
    String lowerName = name.toLowerCase();
    bool isUnix = lowerName == 'karthik';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isUnix ? "👑 " : "⚡ ", style: const TextStyle(fontSize: 20)),
                  Text(isUnix ? "Project Founder" : "Core Developer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isUnix ? Colors.amber[800] : Colors.grey[800])),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isUnix ? Colors.amber[50] : Colors.grey[100], border: Border.all(color: isUnix ? Colors.amber[300]! : Colors.grey[200]!, width: 2)),
                child: ClipOval(child: Icon(isUnix ? Icons.terminal_rounded : Icons.person_rounded, size: 60, color: isUnix ? Colors.amber[600] : Colors.grey[400])),
              ),
              const SizedBox(height: 18),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(isUnix ? "Lead Software Engineer" : "Mobile Application Developer", style: TextStyle(fontSize: 14, color: isUnix ? Colors.amber[700] : Colors.grey[500], fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _launchURL(githubUrl),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: isUnix ? const Color(0xFF1A1A1A) : const Color(0xFF0D253F), borderRadius: BorderRadius.circular(14)),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.code, color: Colors.white, size: 20), SizedBox(width: 8), Text("GitHub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _launchURL(linkedinUrl),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: isUnix ? const Color(0xFF005299) : const Color(0xFF004182), borderRadius: BorderRadius.circular(14)),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.business, color: Colors.white, size: 20), SizedBox(width: 8), Text("LinkedIn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          controller: widget.scrollController, // Tied master controller directly here
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              floating: true,
              title: const Text('Profile Page', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),

            // 1. MODULAR PROFILE HEADER CHIP
            SliverToBoxAdapter(
              child: ProfileHeader(
                currentUser: currentUser,
                onEditUsername: _editUsername,
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  alignment: Alignment.centerLeft,
                  child: const Text("My Contributions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
            ),

            // CONTRIBUTIONS STREAM FEED LIST
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const SliverToBoxAdapter(child: Center(child: Text("Error loading posts")));
                if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Colors.black)));

                var myPosts = snapshot.data!.docs;
                if (myPosts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0), child: Column(children: [Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]), const SizedBox(height: 10), const Text("You haven't posted anything yet!", style: TextStyle(color: Colors.grey))]))),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        var postDoc = myPosts[index];
                        var postData = postDoc.data() as Map<String, dynamic>;
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(postData['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(postData['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) => _deletePost(postDoc.id),
                              itemBuilder: (c) => [const PopupMenuItem(value: 'delete', child: Text('Delete Post', style: TextStyle(color: Colors.red)))],
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PostDetailPage(postId: postDoc.id, postData: postData))),
                          ),
                        );
                      },
                      childCount: myPosts.length,
                    ),
                  ),
                );
              },
            ),

            // 2. MODULAR SETTINGS COMPONENT
            SliverToBoxAdapter(
              child: ActionRowGroup(
                onGithubStar: () => _launchURL("https://github.com/Karthik-Beesabathini/ThreadX"),
                onLogout: signUserOut,
                onChangelog: () {},
                onPrivacyPolicy: () {},
              ),
            ),

            // 3. MODULAR TEAM ATTRIBUTION FOOTER
            SliverToBoxAdapter(
              child: DeveloperFooter(
                onTapUnix: () => _showDeveloperSheet(context, name: "Karthik", githubUrl: "https://github.com/Karthik-Beesabathini", linkedinUrl: "https://www.linkedin.com/in/karthik-beesabathini-2107893b6/"),
                onTapDgk: () => _showDeveloperSheet(context, name: "Karthikeya", githubUrl: "https://github.com/dgk1503", linkedinUrl: "https://www.linkedin.com/in/gnana-karthikeya-490450361/"),
                onTapLynx: () => _showDeveloperSheet(context, name: "Aditya", githubUrl: "https://github.com/Aditya-SSR", linkedinUrl: "https://www.linkedin.com/in/aditya-sunkaranam-4ab3a5374/"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverHeaderDelegate({required this.child});
  @override double get minExtent => 45.0;
  @override double get maxExtent => 45.0;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) => false;
}