import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/pages/users/workers.dart';

class Users extends StatefulWidget {
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  late Future<List<dynamic>> summaryFuture;

  @override
  void initState() {
    super.initState();
    summaryFuture = _getSummary();
  }

  /// Fetches roles with user counts from the API and extracts the `data` list.
  Future<List<dynamic>> _getSummary() async {
    final response = await APIService.api("GET", "users/summary", {});
    if (response['httpCode'] == 200 || response['httpCode'] == 201) {
      final Map body = jsonDecode(response['body']);
      if (body['success'] == true) {
        return List<dynamic>.from(body['data']);
      }
      throw Exception(body['message'] ?? "Failed to load summary.");
    }
    throw Exception("Server error: ${response['httpCode']}");
  }

  IconData _getIcon(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'technician':
        return Icons.build_outlined;
      case 'shop owner':
        return Icons.storefront_outlined;
      case 'manager':
        return Icons.manage_accounts_outlined;
      case 'worker':
        return Icons.person_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: Text(
        "Users",
        style: TextStyle(
            color: ColorsWidget().appBarColor, fontWeight: FontWeight.bold),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No user data found."));
          }

          final List<dynamic> roles = snapshot.data!;

          final int totalUsers = roles.fold(
            0,
            (sum, item) => sum + ((item['users_count'] as int?) ?? 0),
          );

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: roles.length + 1,
            itemBuilder: (context, index) {
              if (index == roles.length) {
                return _AnimatedCard(
                  title: "Total Users",
                  icon: Icons.people_outline,
                  count: totalUsers,
                  onTap: () {},
                );
              }

              final Map role = roles[index];
              final String name = role['name'] ?? '';
              final int count = (role['users_count'] as int?) ?? 0;

              return _AnimatedCard(
                title: name,
                icon: _getIcon(name),
                count: count,
                onTap: () {
                  Navigator.push(
                    context,
                    SlideRightRoute(
                      page: SystemUsers(title: name),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ===================== ANIMATED CARD WIDGET =====================
class _AnimatedCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _AnimatedCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = ColorsWidget().buttonsColor;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isPressed ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.04),
              blurRadius: _isPressed ? 10 : 6,
              offset: Offset(0, _isPressed ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 34, color: primaryColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.count.toString(),
              style: TextStyle(
                color: primaryColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
