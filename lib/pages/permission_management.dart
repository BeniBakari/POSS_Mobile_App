import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/services/api_service.dart';

class PermissionManagement extends StatefulWidget {
  const PermissionManagement({super.key});

  @override
  State<PermissionManagement> createState() => _PermissionManagementState();
}

class _PermissionManagementState extends State<PermissionManagement> {
  List allPermissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => isLoading = true);
    try {
      var res = await APIService.api("GET", "permissions", {});
      if (res['httpCode'] == 200) {
        Map body = json.decode(res['body']);
        if (body['success'] == true) {
          setState(() => allPermissions = body['data'] ?? []);
        }
      }
    } catch (e) {
      toast("Failed to load permissions list");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- ACTION: DELETE PERMISSION ---
  Future<void> _deletePermission(int id) async {
    var res = await APIService.api("DELETE", "permissions/$id", {});
    if (res['httpCode'] == 200 || res['httpCode'] == 204) {
      toast("Permission deleted");
      _loadPermissions();
    } else {
      toast("Failed to delete permission");
    }
  }

  // --- DIALOG: ADD NEW PERMISSION ---
  void _showAddDialog() {
    final TextEditingController permController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const TextWidget(text: "New Permission",  fontsize: 18),
        content: TextField(
          controller: permController,
          decoration: const InputDecoration(
            hintText: "e.g., view-reports",
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (permController.text.isEmpty) return;
              var res = await APIService.api("POST", "permissions", {"name": permController.text, "guard_name": "web"});
              if (res['httpCode'] == 201 || res['httpCode'] == 200) {
                Navigator.pop(context);
                toast("Permission created!");
                _loadPermissions();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG: DELETE CONFIRMATION ---
  void _confirmDelete(Map perm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Permission"),
        content: Text("Are you sure you want to delete '${perm['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePermission(perm['id']);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: const TextWidget(text: "System Permissions", color: Colors.white),
      // FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorsWidget().appBarColor,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: ColorsWidget().appBarColor))
          : RefreshIndicator(
              onRefresh: _loadPermissions,
              child: allPermissions.isEmpty
                  ? const Center(child: TextWidget(text: "No permissions found", color: Colors.white54))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allPermissions.length,
                      itemBuilder: (context, index) {
                        final perm = allPermissions[index];
                        return GestureDetector(
                          // LONG PRESS TO DELETE
                          onLongPress: () => _confirmDelete(perm),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: ColorsWidget().appBarColor,
                                child: const Icon(Icons.key, color: Colors.white, size: 18),
                              ),
                              title: TextWidget(text: perm['name']),
                              subtitle: Text("Guard: ${perm['guard_name']}", style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.verified, size: 16, color: Colors.greenAccent),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
