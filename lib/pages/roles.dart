import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/roles.dart'; // RolesData.getRoles()
import 'package:poss_mobile_app/services/api_service.dart'; // APIService.api()
import 'package:poss_mobile_app/pages/permission_management.dart'; // PermissionManagement and SlideRightRoute

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List roles = [];
  List allPermissions = []; // Master list from server
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  // 1. Initial Load: Roles + Master Permission List

  Future<void> _initialLoad() async {
    setState(() => isLoading = true);
    try {
      // 1. Fetch roles
      roles = await RolesData.getRoles(refresh: true);

      // 2. Fetch permissions
      var res = await APIService.api("GET", "permissions", {});

      // Check if the request was successful based on the HTTP code
      if (res['httpCode'] == 200) {
        // Decode the body string into a Map
        Map body = json.decode(res['body']);

        if (body['success'] == true) {
          setState(() {
            allPermissions = body['data'] ?? [];
          });
        }
      }
    } catch (e) {
      toast("Error loading management data");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. Double Tap: View current permissions as Chips
  void _viewPermissions(Map role) {
    List perms = role['permissions'] as List? ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: Column(
          children: [
            TextWidget(
              text: "${role['name']} Permissions",
            ),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: perms
                      .map((p) => Chip(
                            label: Text(p['name'],
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Single Tap: Add/Remove Permissions Dialog
  void _showRoleDialog({Map? role}) {
    final nameController = TextEditingController(text: role?['name'] ?? "");
    final descController =
        TextEditingController(text: role?['description'] ?? "");

    // Initialize selected list with current names from the role
    List<String> selectedPermNames = role != null
        ? (role['permissions'] as List)
            .map((p) => p['name'].toString())
            .toList()
        : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(role == null ? "New Role" : "Sync Permissions"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Role Name")),
                TextField(
                    controller: descController,
                    decoration:
                        const InputDecoration(labelText: "Description")),
                const SizedBox(height: 20),
                const Text("Toggle Permissions",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allPermissions.length,
                    itemBuilder: (context, index) {
                      final pName = allPermissions[index]['name'];
                      final isChecked = selectedPermNames.contains(pName);

                      return CheckboxListTile(
                        title:
                            Text(pName, style: const TextStyle(fontSize: 14)),
                        value: isChecked,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            // Updates the checkbox UI
                            if (value == true) {
                              selectedPermNames.add(pName);
                            } else {
                              selectedPermNames.remove(pName);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Map data = {
                  "name": nameController.text,
                  "description": descController.text,
                  "permissions":
                      selectedPermNames, // Array for syncPermissions()
                };

                var res = (role == null)
                    ? await APIService.api("POST", "roles", data)
                    : await APIService.api('PUT', 'roles/${role['id']}', data);
                res = json.decode(res['body']);
                if (res['success'] == true) {
                  Navigator.pop(context);
                  _initialLoad(); // Refresh
                  toast("Permissions Updated");
                }
              },
              child: const Text("Save Changes"),
            )
          ],
        ),
      ),
    );
  }

  // 4. Long Press: Delete
  void _confirmDelete(Map role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Role"),
        content: Text("Permanently delete '${role['name']}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              var apiRes =
                  await APIService.api('DELETE', 'roles/${role['id']}', {});

              if (apiRes['body'] == null || apiRes['body'].toString().isEmpty) {
                _initialLoad(); // Still refresh if code is 200/204
                return;
              }
              Map res = json.decode(apiRes['body']);
              if (res['success'] == true || apiRes['httpCode'] == 200) {
                toast("Role deleted");
                _initialLoad();
              } else {
                toast(res['message'] ?? "Delete failed");
              }
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
      title: const TextWidget(text: "Role Management", color: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorsWidget().appBarColor,
        onPressed: () => _showRoleDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      actions: [
        PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            color: ColorsWidget().popMenuBackground,
            itemBuilder: (context) => [
                  const PopupMenuItem<int>(
                    value: 0,
                    child: TextWidget(
                      text: "Permissions",
                      color: Colors.white,
                      fontsize: 15,
                    ),
                  ),
                ],
            onSelected: (item) async {
              if (item == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PermissionManagement()),
                );
              }
            }),
      ],
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: ColorsWidget().appBarColor))
          : RefreshIndicator(
              onRefresh: _initialLoad,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  return GestureDetector(
                    onTap: () => _showRoleDialog(role: role),
                    onDoubleTap: () => _viewPermissions(role),
                    onLongPress: () => _confirmDelete(role),
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: ColorsWidget().appBarColor,
                            child: const Icon(Icons.security,
                                color: Colors.white)),
                        title: TextWidget(text: role['name']),
                        subtitle: Text(role['description'] ?? "No description"),
                        trailing: Text(
                          "${(role['permissions'] as List).length} Perms",
                          style: TextStyle(
                              color: ColorsWidget().appBarColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
