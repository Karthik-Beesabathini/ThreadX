import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:calc_app/pages/post_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: "Enter new username",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .update({'username': newName});

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Username updated successfully!")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to save username: $e")),
                    );
                  }
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
        content: const Text("This will permanently remove this post and all its comments. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post removed successfully.")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting post: $e")),
                  );
                }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  Widget _buildClickableLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _showDeveloperSheet(
      BuildContext context, {
        required String name,
        required String githubUrl,
        required String linkedinUrl,
      }) {
    String lowerName = name.toLowerCase();
    bool isUnix = lowerName == 'karthik';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isUnix ? "👑 " : "⚡ ",
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    isUnix ? "Project Founder" : "Core Developer",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnix ? Colors.amber[800] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnix ? Colors.amber[50] : Colors.grey[100],
                      border: Border.all(
                        color: isUnix ? Colors.amber[300]! : Colors.grey[200]!,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Icon(
                        isUnix ? Icons.terminal_rounded : Icons.person_rounded,
                        size: 60,
                        color: isUnix ? Colors.amber[600] : Colors.grey[400],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(isUnix ? "🏆" : "👋", style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                isUnix ? "Lead Software Engineer" : "Mobile Application Developer",
                style: TextStyle(
                  fontSize: 14,
                  color: isUnix ? Colors.amber[700] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),
              Container(width: 24, height: 1.5, color: Colors.grey[300]),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _launchURL(githubUrl),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isUnix ? const Color(0xFF1A1A1A) : const Color(0xFF0D253F),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/github.png",
                              height: 20,
                              color: Colors.white,
                              errorBuilder: (c, e, s) => const Icon(Icons.code, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "GitHub",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
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
                        decoration: BoxDecoration(
                          color: isUnix ? const Color(0xFF005299) : const Color(0xFF004182),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/linkedin.png",
                              height: 20,
                              color: Colors.white,
                              errorBuilder: (c, e, s) => const Icon(Icons.business, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "LinkedIn",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Helper inside actions card box
  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 60.0),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. TOP APP BAR
            SliverAppBar(
              backgroundColor: Colors.white,
              floating: true,
              pinned: false,
              elevation: 0,
              title: const Text(
                'Profile Page',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),

            // 2. PROFILE CONTAINER CARD
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String displayUsername = "Loading...";
                    String displayEmail = currentUser.email ?? '';

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        displayUsername = data['username'] ?? 'No Username Set';
                      }
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.grey[200],
                          child: const Icon(Icons.person, size: 50, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 32),
                            Text(
                              "u/$displayUsername",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
                              onPressed: () => _editUsername(context, displayUsername),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayEmail,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // 3. CONTRIBUTIONS HEADER
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "My Contributions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ),

            // 4. USERS STREAM POST LIST
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('authorId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${snapshot.error}"))),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.black))),
                  );
                }

                var myPosts = snapshot.data!.docs;

                if (myPosts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            const Text("You haven't posted anything yet!", style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        var postDoc = myPosts[index];
                        var postData = postDoc.data() as Map<String, dynamic>;
                        String postId = postDoc.id;

                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    postData['category'] ?? 'General',
                                    style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    postData['title'] ?? 'Untitled',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                postData['text'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.black54),
                              onSelected: (value) {
                                if (value == 'delete') _deletePost(postId);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete Post', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailPage(
                                    postId: postId,
                                    postData: postData,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: myPosts.length,
                    ),
                  ),
                );
              },
            ),

            // 5. ✅ NEW ACTIONS SECTION BLOCK (Matches Drawing Frame)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0, bottom: 10.0),
                      child: Text(
                        "Actions",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF006699)),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FC), // Soft container hue blueprint matching sketch panel
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Column(
                        children: [
                          _buildActionRow(
                            icon: Icons.star_rounded,
                            iconColor: Colors.amber,
                            iconBgColor: Colors.amber.withOpacity(0.15),
                            title: "Star us on Github",
                            textColor: Colors.black87,
                            onTap: () => _launchURL("https://github.com/Karthik-Beesabathini/ThreadX"),
                          ),
                          _buildActionRow(
                            icon: Icons.logout_rounded,
                            iconColor: Colors.redAccent,
                            iconBgColor: Colors.redAccent.withOpacity(0.15),
                            title: "Logout",
                            textColor: Colors.redAccent,
                            onTap: signUserOut,
                          ),
                          _buildActionRow(
                            icon: Icons.article_outlined,
                            iconColor: Colors.teal,
                            iconBgColor: Colors.teal.withOpacity(0.15),
                            title: "Changelog",
                            textColor: Colors.black87,
                            onTap: () {
                              // Optional: Route or show URL here
                            },
                          ),
                          _buildActionRow(
                            icon: Icons.info_outline_rounded,
                            iconColor: Colors.blueAccent,
                            iconBgColor: Colors.blueAccent.withOpacity(0.15),
                            title: "PrivacyPolicy",
                            textColor: Colors.black87,
                            showDivider: false,
                            onTap: () {
                              // Optional: Route or show privacy policy here
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. BOTTOM ATTRIBUTION FOOTER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 40.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Crafted with ", style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text("❤️ ", style: TextStyle(fontSize: 12)),
                        Text("by", style: TextStyle(color: Colors.black54, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildClickableLink("Unix", () {
                          _showDeveloperSheet(
                            context,
                            name: "Karthik",
                            githubUrl: "https://github.com/Karthik-Beesabathini",
                            linkedinUrl: "https://www.linkedin.com/in/karthik-beesabathini-2107893b6/",
                          );
                        }),
                        const Text(" , ", style: TextStyle(color: Colors.grey)),
                        _buildClickableLink("DGk", () {
                          _showDeveloperSheet(
                            context,
                            name: "Karthikeya",
                            githubUrl: "https://github.com/dgk1503",
                            linkedinUrl: "https://www.linkedin.com/in/gnana-karthikeya-490450361/",
                          );
                        }),
                        const Text(" , ", style: TextStyle(color: Colors.grey)),
                        _buildClickableLink("Lynx", () {
                          _showDeveloperSheet(
                            context,
                            name: "Aditya",
                            githubUrl: "https://github.com/Aditya-SSR",
                            linkedinUrl: "https://www.linkedin.com/in/aditya-sunkaranam-4ab3a5374/",
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
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

  @override
  double get minExtent => 45.0;
  @override
  double get maxExtent => 45.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) => false;
}