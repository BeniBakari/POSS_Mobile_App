import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/data/profileData.dart';
import 'package:poss_mobile_app/pages/users/editProfile.dart';
import 'package:poss_mobile_app/services/api_service.dart';

class SystemUsers extends StatefulWidget {
  final String title;
  const SystemUsers({super.key, required this.title});

  @override
  State<SystemUsers> createState() => _SystemUsersState();
}

class _SystemUsersState extends State<SystemUsers> {
  late Future<List<dynamic>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetchUsers() async {
    final response = await APIService.api(
      "POST",
      "users/usersByRole",
      {'role': widget.title},
    );

    if (response['httpCode'] == 200 || response['httpCode'] == 201) {
      final Map body = jsonDecode(response['body']);
      if (body['success'] == true) {
        return List<dynamic>.from(body['data']);
      }
      throw Exception(body['message'] ?? "Failed to load users.");
    }
    throw Exception("Server error: ${response['httpCode']}");
  }

  void _refresh() {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  List<dynamic> _applySearch(List<dynamic> users) {
    if (_searchQuery.isEmpty) return users;
    return users.where((u) {
      final name =
          "${u['first_name'] ?? ''} ${u['last_name'] ?? ''}".toLowerCase();
      final email = (u['email'] ?? '').toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ColorsWidget().buttonsColor;

    return ScaffoldWidget(
      title: Text(
        widget.title,
        style: TextStyle(
            color: ColorsWidget().appBarColor, fontWeight: FontWeight.bold),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      "Something went wrong",
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<dynamic> allUsers = snapshot.data ?? [];
          final List<dynamic> filtered = _applySearch(allUsers);

          return Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by name, email or phone…",
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon:
                        Icon(Icons.search, color: primaryColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.grey.shade400, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ),

              // ── Result count ──
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${filtered.length} result${filtered.length == 1 ? '' : 's'} found",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                ),

              // ── List ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? "No ${widget.title}s found"
                                  : "No results for \"$_searchQuery\"",
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _UserCard(
                            user: filtered[index] as Map,
                            title: widget.title,
                            onDeleted: _refresh,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===================== USER CARD =====================
class _UserCard extends StatelessWidget {
  final Map user;
  final String title;
  final VoidCallback onDeleted;

  const _UserCard({
    required this.user,
    required this.title,
    required this.onDeleted,
  });

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: EditProfile(title: "User Profile", profile: user),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final String fullName =
        "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text("Delete User",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete \"$fullName\"? This action cannot be undone.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final response = await APIService.api(
                "DELETE",
                "users/${user['id']}",
                {},
              );
              if (response['httpCode'] == 200 || response['httpCode'] == 201) {
                onDeleted();
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ColorsWidget().buttonsColor;
    final bool isAdminOrAbove =
        ProfileData.profile['role_names'].contains('Admin');

    final String fullName =
        "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
    final String email = user['email'] ?? 'N/A';
    final String phone = user['phone']?.toString() ?? 'N/A';
    final String address = user['address']?.toString() ?? 'N/A';
    final String initials = _getInitials(fullName);

    return GestureDetector(
      onDoubleTap: isAdminOrAbove ? () => _navigateToEdit(context) : null,
      onLongPress: isAdminOrAbove ? () => _showDeleteDialog(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Unknown User' : fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: email,
                        color: primaryColor),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: phone,
                        color: primaryColor),
                    _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: address,
                        color: primaryColor),
                    if (title == "Worker" || title == "Manager")
                      _InfoRow(
                        icon: Icons.storefront_outlined,
                        label: (user['shop'] != null &&
                                (user['shop'] as List).isNotEmpty)
                            ? user['shop'][0]['name']
                            : 'N/A',
                        color: primaryColor,
                      ),
                  ],
                ),
              ),

              // Subtle gesture hint icons for admins
              if (isAdminOrAbove)
                Column(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 15, color: Colors.grey.shade300),
                    const SizedBox(height: 4),
                    Icon(Icons.delete_outline,
                        size: 15, color: Colors.grey.shade300),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}

// ===================== INFO ROW =====================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoRow(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
