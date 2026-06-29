import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poss_mobile_app/components/button_widget.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/profileData.dart';
import 'package:poss_mobile_app/services/api_service.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key, required this.profile, required this.title});
  final Map profile;
  final String title;

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final addressController = TextEditingController();
  final dobController = TextEditingController();

  String gender = '';
  bool isGenderEmpty = false;
  DateTime initialDate = DateTime(2008);

  // ── Roles ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> availableRoles = [];
  List<int> selectedRoleIds = [];
  List<String> _pendingRoleNames =
      []; // role_names from profile, resolved to IDs after fetch
  bool isRolesLoading = true;
  bool isRolesError = false;

  @override
  void initState() {
    super.initState();
    firstNameController.text = widget.profile['first_name'] ?? '';
    lastNameController.text = widget.profile['last_name'] ?? '';
    phoneNumberController.text = widget.profile['phone']?.toString() ?? '';
    addressController.text = widget.profile['address']?.toString() ?? '';
    dobController.text = widget.profile['dob']?.toString() ?? '';
    gender = widget.profile['gender'] ?? '';

    // Read role_names (strings) from profile.
    // These are resolved to IDs once availableRoles loads in _fetchRoles().
    final existingRoleNames = widget.profile['role_names'];
    if (existingRoleNames is List && existingRoleNames.isNotEmpty) {
      _pendingRoleNames = List<String>.from(existingRoleNames);
    }

    _fetchRoles();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    dobController.dispose();
    super.dispose();
  }

  // ── Fetch Roles from API ───────────────────────────────────────
  Future<void> _fetchRoles() async {
    setState(() {
      isRolesLoading = true;
      isRolesError = false;
    });
    try {
      final Map response = await APIService.api("GET", "roles", {});
      if (response['httpCode'] == 200 || response['httpCode'] == 201) {
        final Map body = jsonDecode(response['body']);
        if (body['success'] == true) {
          final List data = List.from(body['data']);
          setState(() {
            availableRoles = data
                .map<Map<String, dynamic>>((r) => {
                      'id': r['id'] as int,
                      'name': r['name']?.toString() ?? '',
                    })
                .toList();

            // Resolve pending role_names → IDs for pre-selection
            if (_pendingRoleNames.isNotEmpty) {
              selectedRoleIds = availableRoles
                  .where((r) => _pendingRoleNames.contains(r['name']))
                  .map<int>((r) => r['id'] as int)
                  .toList();
            }

            isRolesLoading = false;
          });
          return;
        }
      }
      setState(() {
        isRolesLoading = false;
        isRolesError = true;
      });
    } catch (_) {
      setState(() {
        isRolesLoading = false;
        isRolesError = true;
      });
    }
  }

  // ── Field Builder ──────────────────────────────────────────────
  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final primaryColor = ColorsWidget().buttonsColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onTap: onTap,
        inputFormatters: inputFormatters,
        validator: validator ??
            (value) => value == null || value.trim().isEmpty
                ? '$label cannot be empty'
                : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Gender Selector ────────────────────────────────────────────
  Widget _buildGenderSelector() {
    final primaryColor = ColorsWidget().buttonsColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("GENDER"),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                label: "Male",
                icon: Icons.male,
                selected: gender == 'M',
                selectedColor: primaryColor,
                onTap: () => setState(() {
                  gender = 'M';
                  isGenderEmpty = false;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderOption(
                label: "Female",
                icon: Icons.female,
                selected: gender == 'F',
                selectedColor: primaryColor,
                onTap: () => setState(() {
                  gender = 'F';
                  isGenderEmpty = false;
                }),
              ),
            ),
          ],
        ),
        if (isGenderEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              "Please select a gender",
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ── Roles Multi-Select ─────────────────────────────────────────
  Widget _buildRolesSelector() {
    final primaryColor = ColorsWidget().buttonsColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionLabel("ROLES"),
        if (isRolesLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Loading roles...",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else if (isRolesError)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Failed to load roles.",
                    style: TextStyle(fontSize: 13, color: Colors.red.shade500),
                  ),
                ),
                GestureDetector(
                  onTap: _fetchRoles,
                  child: Text(
                    "Retry",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (availableRoles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "No roles available.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableRoles.map((role) {
              final int roleId = role['id'] as int;
              final String roleName = role['name']?.toString() ?? '';
              // Pre-selected if user already has this role (resolved from role_names)
              final bool isSelected = selectedRoleIds.contains(roleId);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedRoleIds.remove(roleId);
                    } else {
                      selectedRoleIds.add(roleId);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 15,
                        color: isSelected ? primaryColor : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        roleName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected ? primaryColor : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── Avatar Header ──────────────────────────────────────────────
  Widget _buildAvatarHeader() {
    final primaryColor = ColorsWidget().buttonsColor;
    final String fullName =
        "${widget.profile['first_name'] ?? ''} ${widget.profile['last_name'] ?? ''}"
            .trim();
    final String initials = fullName.isNotEmpty
        ? fullName
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase()
        : '?';

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            child: Text(
              initials,
              style: TextStyle(
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fullName.isEmpty ? 'User' : fullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.profile['email'] ?? '',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Helper: is Admin editing someone else ──────────────────────
  bool get _isAdminEditingOthers =>
      ProfileData.profile['role_names'].contains('Admin') &&
      ProfileData.profile['id'] != widget.profile['id'];

  @override
  Widget build(BuildContext context) {
    final primaryColor = ColorsWidget().buttonsColor;

    return ScaffoldWidget(
      title: Text(
        widget.title,
        style: TextStyle(
            color: ColorsWidget().appBarColor, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatarHeader(),
              const SizedBox(height: 24),

              // Personal Info
              _sectionLabel("PERSONAL INFORMATION"),
              _buildField(
                icon: Icons.person_outline,
                label: "First Name",
                controller: firstNameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-]")),
                ],
              ),
              _buildField(
                icon: Icons.person_outline,
                label: "Last Name",
                controller: lastNameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-]")),
                ],
              ),

              // Contact
              _sectionLabel("CONTACT"),
              _buildField(
                icon: Icons.phone_outlined,
                label: "Phone",
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Phone number is required";
                  }
                  if (value.length != 10) {
                    return "Phone number must be exactly 10 digits";
                  }
                  return null;
                },
              ),
              _buildField(
                icon: Icons.location_on_outlined,
                label: "Address",
                controller: addressController,
              ),

              // Other
              _sectionLabel("OTHER"),
              _buildField(
                icon: Icons.cake_outlined,
                label: "Date of Birth",
                controller: dobController,
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1955),
                    lastDate: DateTime(2008),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: primaryColor),
                      ),
                      child: child!,
                    ),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      dobController.text =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),

              const SizedBox(height: 4),
              _buildGenderSelector(),

              // Roles — only shown when Admin is editing another user
              if (_isAdminEditingOthers) _buildRolesSelector(),

              const SizedBox(height: 28),

              // Save Button
              Align(
                alignment: Alignment.centerRight,
                child: ButtonWidget(
                  btnText: "Save Changes",
                  onBtnPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (gender.isEmpty) {
                      setState(() => isGenderEmpty = true);
                      toast("Please select gender.");
                      return;
                    }

                    // Guard: at least one role must be selected
                    if (_isAdminEditingOthers && selectedRoleIds.isEmpty) {
                      toast("Please select at least one role.");
                      return;
                    }

                    Map profile = Map.from(widget.profile);
                    profile['first_name'] = firstNameController.text.trim();
                    profile['last_name'] = lastNameController.text.trim();
                    profile['phone'] = phoneNumberController.text.trim();
                    profile['address'] = addressController.text.trim();
                    profile['dob'] = dobController.text;
                    profile['gender'] = gender;

                    // Send role_ids (ints) — backend resolves via syncRoles()
                    if (_isAdminEditingOthers) {
                      profile['role_ids'] = selectedRoleIds;
                    }
                    final String link = _isAdminEditingOthers
                        ? "users/update-user-profile/${profile['id']}"
                        : "users/update-profile";

                    final Map response =
                        await APIService.api("PUT", link, profile);
                    if (response['httpCode'] == 200) {
                      toast("Profile updated successfully.");
                      Navigator.pop(context);
                    } else {
                      toast("Failed to update profile.");
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== GENDER OPTION =====================
class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              selected ? selectedColor.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: selected ? selectedColor : Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? selectedColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
