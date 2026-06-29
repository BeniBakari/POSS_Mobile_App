import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/floatingActionButton_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/data/employeeData.dart';
import 'package:poss_mobile_app/pages/employees/find_employee.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

class Employees extends StatefulWidget {
  final Map shop;
  const Employees({required this.shop, super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color _blue900  = Color(0xFF0D2B6E);
  static const Color _blue700  = Color(0xFF1A56DB);
  static const Color _blue500  = Color(0xFF3B82F6);
  static const Color _blue200  = Color(0xFFBFDBFE);
  static const Color _blue50   = Color(0xFFEFF6FF);
  static const Color _indigo   = Color(0xFF4F46E5);
  static const Color _violet   = Color(0xFF7C3AED);
  static const Color _indigo50 = Color(0xFFEEF2FF);
  static const Color _sky50    = Color(0xFFE0F2FE);
  static const Color _violet50 = Color(0xFFEDE9FE);
  static const Color _green    = Color(0xFF00B87C);
  static const Color _greenBg  = Color(0xFFE6FAF4);
  static const Color _amber    = Color(0xFFF59E0B);
  static const Color _amberBg  = Color(0xFFFFFBEB);
  static const Color _red      = Color(0xFFEF4444);
  static const Color _redBg    = Color(0xFFFFEEEE);

  static const List<Color> _bgColors = [_blue50, _indigo50, _sky50, _violet50];
  static const List<Color> _fgColors = [_blue700, _indigo, _blue500, _violet];

  late Future<List?> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture =
        EmployeeData.getEmployees(widget.shop['id'].toString());
  }

  void _reload() {
    setState(() {
      _employeesFuture =
          EmployeeData.getEmployees(widget.shop['id'].toString());
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextWidget(
            text: "Employees",
            color: ColorsWidget().appBarColor,
            fontsize: 13,
          ),
          Text(
            widget.shop['name'],
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: ColorsWidget().appBarColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButtonWidget(
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        onBtnPressed: () => Navigator.push(
          context,
          SlideRightRoute(page: FindEmployee(shop: widget.shop)),
        ).then((_) => _reload()),
      ),
      body: FutureBuilder<List?>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _blue700));
          }

          final String shopId = widget.shop['id'].toString();
          if (!EmployeeData.employees.containsKey(shopId) ||
              EmployeeData.employees[shopId]!.isEmpty) {
            return _buildEmptyState();
          }

          final List employees = EmployeeData.employees[shopId]!;

          return Column(
            children: [
              // Summary strip
              _buildSummaryStrip(employees.length),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 0.7,
                    color: _blue50,
                  ),
                  itemBuilder: (_, i) =>
                      _buildEmployeeItem(employees[i] as Map, i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Summary strip ─────────────────────────────────────────────────────────
  Widget _buildSummaryStrip(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _chip(
            icon: Icons.group_rounded,
            label: "$count employee${count == 1 ? '' : 's'}",
            bg: _blue50,
            fg: _blue700,
            border: _blue200,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _blue50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _blue200, width: 1.5),
            ),
            child: const Icon(Icons.group_outlined,
                size: 38, color: _blue500),
          ),
          const SizedBox(height: 16),
          const Text(
            "No employees yet",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _blue200,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap + to add an employee to this shop",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─── Employee item ─────────────────────────────────────────────────────────
  Widget _buildEmployeeItem(Map employee, int index) {
    final String name =
        "${employee['first_name']} ${employee['last_name']}";
    final String email   = employee['email'] ?? '';
    final String phone   = employee['phone']?.toString() ?? '';
    final String roleId  = employee['role_id'].toString();
    final String role    = _getRoleName(roleId);
    final bool isManager = roleId == "3";

    final Color iconBg = _bgColors[index % _bgColors.length];
    final Color iconFg = _fgColors[index % _fgColors.length];

    // Role badge styling
    final Color roleBg  = isManager ? _amberBg : _greenBg;
    final Color roleFg  = isManager ? _amber    : _green;
    final Color roleBorder =
        isManager ? _amber.withValues(alpha: 0.3) : _green.withValues(alpha: 0.3);

    return GestureDetector(
      onLongPress: () => _confirmRemoveEmployee(employee),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar badge with initials
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  _initials(employee['first_name'], employee['last_name']),
                  style: TextStyle(
                    color: iconFg,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + role badge on same row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: roleBorder),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: roleFg,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Email
                  if (email.isNotEmpty)
                    _metaRow(Icons.email_outlined, email),

                  // Phone
                  if (phone.isNotEmpty)
                    _metaRow(Icons.phone_outlined, phone),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Remove button (long-press hint)
            GestureDetector(
              onTap: () => _confirmRemoveEmployee(employee),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _redBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_remove_rounded,
                    color: _red, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade400),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Remove confirmation ───────────────────────────────────────────────────
  void _confirmRemoveEmployee(Map employee) {
    final String name =
        "${employee['first_name']} ${employee['last_name']}";

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _redBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_remove_rounded,
                    color: _red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                "Remove Employee",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Remove $name from this shop?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(
                            color: _blue200, width: 1.5),
                        foregroundColor: _blue700,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel",
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_red, Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _red.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final Map response = await APIService.api(
                            "DELETE",
                            "shops/remove_employee/${employee['id']}",
                            {},
                          );
                          Navigator.pop(context);
                          if (response['httpCode'].toString() == "200") {
                            toast("Employee removed successfully");
                            _reload();
                          } else {
                            toast("Something went wrong");
                          }
                        },
                        child: const Text(
                          "Remove",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  String _getRoleName(String roleId) {
    if (roleId == "4") return "Worker";
    if (roleId == "3") return "Manager";
    return "Unknown";
  }

  String _initials(String? first, String? last) {
    final f = (first?.isNotEmpty ?? false) ? first![0].toUpperCase() : '';
    final l = (last?.isNotEmpty ?? false) ? last![0].toUpperCase() : '';
    return '$f$l';
  }
}