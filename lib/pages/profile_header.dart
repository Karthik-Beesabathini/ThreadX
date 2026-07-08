import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final User currentUser;
  final Function(BuildContext, String) onEditUsername;

  const ProfileHeader({
    super.key,
    required this.currentUser,
    required this.onEditUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    onPressed: () => onEditUsername(context, displayUsername),
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
    );
  }
}