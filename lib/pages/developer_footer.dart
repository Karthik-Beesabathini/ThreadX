import 'package:flutter/material.dart';

class DeveloperFooter extends StatelessWidget {
  final VoidCallback onTapUnix;
  final VoidCallback onTapDgk;
  final VoidCallback onTapLynx;

  const DeveloperFooter({
    super.key,
    required this.onTapUnix,
    required this.onTapDgk,
    required this.onTapLynx,
  });

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

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              _buildClickableLink("Unix", onTapUnix),
              const Text(" , ", style: TextStyle(color: Colors.grey)),
              _buildClickableLink("DGk", onTapDgk),
              const Text(" , ", style: TextStyle(color: Colors.grey)),
              _buildClickableLink("Lynx", onTapLynx),
            ],
          ),
        ],
      ),
    );
  }
}