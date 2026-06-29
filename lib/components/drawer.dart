import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/measurement.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/data/data.dart';
import 'package:poss_mobile_app/data/profileData.dart';
import 'package:poss_mobile_app/pages/home.dart';
import 'package:poss_mobile_app/pages/roles.dart';
import 'package:poss_mobile_app/pages/users/account.dart';
import 'package:poss_mobile_app/pages/users/users.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    String percent = ProfileData.profile['percent'].toString();
    final primaryColor = ColorsWidget().buttonsColor;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ================= PROFILE HEADER =================
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: Measurement.getHeight(context) * 0.06,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            color: primaryColor,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: "${ProfileData.profile['first_name'] ?? ''} "
                            "${ProfileData.profile['last_name'] ?? ''}",
                        fontsize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 2),
                      TextWidget(
                        text: ProfileData.profile['email'] ?? '',
                        fontsize: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: int.tryParse(percent) != null
                              ? int.parse(percent) / 100
                              : 0,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextWidget(
                        text: "$percent% complete",
                        fontsize: 11,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ================= MENU ITEMS =================
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.storefront_outlined,
                  text: "Shops",
                  onTap: () {
                    Navigator.pop(context);
                    if (Data.currentPage != "Home") {
                      Data.setpageName("Home");
                      Navigator.pushReplacement(
                        context,
                        SlideRightRoute(page: const Home()),
                      );
                    }
                  },
                ),
                if (ProfileData.profile['role_names'].contains('Admin'))
                  _buildDrawerItem(
                    icon: Icons.group_outlined,
                    text: "Users",
                    onTap: () {
                      Navigator.pop(context);
                      if (Data.currentPage != "Users") {
                        Data.setpageName("Users");
                        Navigator.push(
                          context,
                          SlideRightRoute(page: const Users()),
                        );
                      }
                    },
                  ),
                if (ProfileData.profile['role_names'].contains('Admin'))
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    text: "Roles",
                    onTap: () {
                      Navigator.pop(context);
                      if (Data.currentPage != "Roles") {
                        Data.setpageName("Roles");
                        Navigator.push(
                          context,
                          SlideRightRoute(page: const RoleManagementScreen()),
                        );
                      }
                    },
                  ),
                _buildDrawerItem(
                  icon: Icons.account_circle_outlined,
                  text: "Account",
                  onTap: () {
                    Navigator.pop(context);
                    if (Data.currentPage != "Account") {
                      Data.setpageName("Account");
                      Navigator.push(
                        context,
                        SlideRightRoute(
                          page: Account(profile: ProfileData.profile),
                        ),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  text: "Help",
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  text: "Settings",
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  text: "About Us",
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ================= FOOTER =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Column(
              children: [
                Text(
                  "Developed and Maintained by Beni John Bakari.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  "Version 1.0.0",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DRAWER ITEM BUILDER =================
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final primaryColor = ColorsWidget().buttonsColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: primaryColor.withValues(alpha: 0.08),
        highlightColor: primaryColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 22),
              const SizedBox(width: 16),
              TextWidget(text: text, fontsize: 15),
            ],
          ),
        ),
      ),
    );
  }
}