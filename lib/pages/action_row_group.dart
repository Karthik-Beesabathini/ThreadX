import 'package:flutter/material.dart';

class ActionRowGroup extends StatelessWidget {
  final VoidCallback onGithubStar;
  final VoidCallback onLogout;
  final VoidCallback onChangelog;
  final VoidCallback onPrivacyPolicy;

  const ActionRowGroup({
    super.key,
    required this.onGithubStar,
    required this.onLogout,
    required this.onChangelog,
    required this.onPrivacyPolicy,
  });

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
    return Padding(
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
              color: const Color(0xFFF4F7FC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                _buildActionRow(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  iconBgColor: Colors.amber.withValues(alpha: 0.15),
                  title: "Star us on Github",
                  textColor: Colors.black87,
                  onTap: onGithubStar,
                ),
                _buildActionRow(
                  icon: Icons.logout_rounded,
                  iconColor: Colors.redAccent,
                  iconBgColor: Colors.redAccent.withValues(alpha: 0.15),
                  title: "Logout",
                  textColor: Colors.redAccent,
                  onTap: onLogout,
                ),
                _buildActionRow(
                  icon: Icons.article_outlined,
                  iconColor: Colors.teal,
                  iconBgColor: Colors.teal.withValues(alpha: 0.15),
                  title: "Changelog",
                  textColor: Colors.black87,
                  onTap: onChangelog,

                ),
                _buildActionRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.blueAccent,
                  iconBgColor: Colors.blueAccent.withValues(alpha: 0.15),
                  title: "PrivacyPolicy",
                  textColor: Colors.black87,
                  showDivider: false,
                  onTap: onPrivacyPolicy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}