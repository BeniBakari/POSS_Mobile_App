// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/floatingActionButton_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/expensesData.dart';
import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/time_diference.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

class Expenses extends StatefulWidget {
  final Map shop;
  const Expenses({required this.shop, super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  late Map shop;

  final descriptionController = TextEditingController();
  final amountController      = TextEditingController();
  final GlobalKey<FormState> formKey     = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyEdit = GlobalKey<FormState>();

  // SEARCH
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  Timer? _debounce;
  List<Map<dynamic, dynamic>> filteredExpenses = [];
  bool isSearching = false;

  // 🔵 Blue palette — consistent across all screens
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
  static const Color _red      = Color(0xFFEF4444);
  static const Color _redBg    = Color(0xFFFFEEEE);

  @override
  void initState() {
    super.initState();
    shop = widget.shop;
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── Search logic ──────────────────────────────────────────────────────────
  void _onSearch(String query) {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        filteredExpenses.clear();
      });
      return;
    }

    final expensesList = List<Map<dynamic, dynamic>>.from(
        ExpensesData.expenses[shop['id'].toString()] ?? []);

    final results = expensesList.where((expense) {
      final desc   = expense['description'].toString().toLowerCase();
      final amount = expense['amount'].toString().toLowerCase();
      final user   = UserData.users[expense['added_by'].toString()] ?? {};
      final name   =
          "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".toLowerCase();
      return desc.contains(query) ||
          amount.contains(query) ||
          name.contains(query);
    }).toList();

    setState(() {
      isSearching      = true;
      filteredExpenses = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Future<List?> expensesFuture =
        ExpensesData.getExpenses(shop['id'].toString());

    return ScaffoldWidget(
      title: Column(
        children: [
          TextWidget(
              text: "Expenses", color: ColorsWidget().appBarColor),
          Text(
            shop['name'],
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ColorsWidget().appBarColor),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButtonWidget(
          onBtnPressed: _showAddExpenseDialog),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: FutureBuilder<List?>(
          future: expensesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _blue700));
            }

            if (!ExpensesData.expenses
                .containsKey(shop['id'].toString())) {
              return _buildEmptyState("No expenses for this shop");
            }

            final List<Map<dynamic, dynamic>> expensesList =
                List<Map<dynamic, dynamic>>.from(
                    ExpensesData.expenses[shop['id'].toString()]!);

            final displayList =
                isSearching ? filteredExpenses : expensesList;

            return Column(
              children: [
                const SizedBox(height: 14),

                // 🔍 Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchBar(),
                ),

                const SizedBox(height: 8),

                // List
                Expanded(
                  child: displayList.isEmpty
                      ? _buildEmptyState(isSearching
                          ? "No expenses found"
                          : "No expenses yet")
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: displayList.length,
                          itemBuilder: (context, index) =>
                              _buildExpenseItem(
                                  displayList[index], index),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _blue500.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(
              const Duration(milliseconds: 300), () => _onSearch(value));
        },
        decoration: InputDecoration(
          hintText: "Search by description, amount or name...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
          prefixIcon: const Icon(Icons.search, color: _blue500),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey[400], size: 18),
                  onPressed: () {
                    searchController.clear();
                    _onSearch('');
                    searchFocusNode.requestFocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 52, color: _blue200),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: _blue200,
                  fontWeight: FontWeight.w500,
                  fontSize: 15)),
        ],
      ),
    );
  }

  // ─── Flat expense item ─────────────────────────────────────────────────────
  Widget _buildExpenseItem(Map expense, int index) {
    final String description = expense['description'];
    final String amount      = expense['amount'].toString();
    final Map user = UserData.users[expense['added_by'].toString()] ?? {};
    final String userName =
        "${user['first_name'] ?? '-'} ${user['last_name'] ?? '-'}";
    final bool editable =
        TimeDifference.hours(expense['created_at']) < 12;

    final List<Color> bgColors = [_blue50, _indigo50, _sky50, _violet50];
    final List<Color> fgColors = [_blue700, _indigo, _blue500, _violet];

    return GestureDetector(
      onDoubleTap:
          editable ? () => _showEditExpenseDialog(expense) : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Icon badge
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bgColors[index % bgColors.length],
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      color: fgColors[index % fgColors.length],
                      size: 21),
                ),

                const SizedBox(width: 14),

                // Description + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 13, color: _blue200),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              userName,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: _blue200),
                          const SizedBox(width: 4),
                          Text(
                            TimeDifference.getDate(
                                expense['created_at']),
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[500]),
                          ),
                          if (editable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _blue50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text("Double-tap to edit",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _blue500,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Amount pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_green, Color(0xFF007A50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    amount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 0.7, color: _blue50),
          ),
        ],
      ),
    );
  }

  // ─── Add dialog ────────────────────────────────────────────────────────────
  void _showAddExpenseDialog() {
    descriptionController.clear();
    amountController.clear();
    _showExpenseDialog(
      title: "New Expense",
      icon: Icons.receipt_long_outlined,
      formKey: formKey,
      confirmLabel: "Add",
      onConfirm: () async {
        if (!formKey.currentState!.validate()) return;
        final data = {
          "amount": amountController.text.trim(),
          "description": descriptionController.text.trim(),
        };
        final response = await APIService.api(
            "POST", "shops/${shop['id']}/expenses/new", data);
        if (response['httpCode'] == 200 ||
            response['httpCode'] == 201) {
          toast("Expense added successfully");
          setState(() {});
          Navigator.pop(context);
        } else {
          toast("Failed to add expense");
        }
      },
    );
  }

  // ─── Edit dialog ───────────────────────────────────────────────────────────
  void _showEditExpenseDialog(Map expense) {
    descriptionController.text = expense['description'];
    amountController.text      = expense['amount'].toString();
    _showExpenseDialog(
      title: "Edit Expense",
      icon: Icons.edit_rounded,
      formKey: formKeyEdit,
      confirmLabel: "Update",
      onConfirm: () async {
        if (!formKeyEdit.currentState!.validate()) return;
        final data = {
          "amount": amountController.text.trim(),
          "description": descriptionController.text.trim(),
        };
        final response = await APIService.api(
            "PUT", "shops/expenses/update/${expense['id']}", data);
        if (response['httpCode'] == 200 ||
            response['httpCode'] == 201) {
          toast("Expense updated successfully");
          setState(() {});
          Navigator.pop(context);
        } else {
          toast("Failed to update expense");
        }
      },
    );
  }

  // ─── Generic expense dialog ────────────────────────────────────────────────
  void _showExpenseDialog({
    required String title,
    required IconData icon,
    required GlobalKey<FormState> formKey,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_blue700, _blue900],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: _blue700.withValues(alpha: 0.32),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Description field
                  TextFieldWidget(
                    textEditingController: descriptionController,
                    labelText: "Description",
                    hintText: "Expense description",
                    textInputType: TextInputType.text,
                    functionValidate: (value) {
                      if (value.trim().isEmpty) {
                        return "Description is required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Amount field
                  TextFieldWidget(
                    textEditingController: amountController,
                    labelText: "Amount",
                    hintText: "Expense amount",
                    textInputType: const TextInputType.numberWithOptions(
                        decimal: true),
                    functionValidate: (value) {
                      if (value.trim().isEmpty) {
                        return "Amount is required";
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return "Enter a valid number";
                      }
                      if (double.parse(value.trim()) <= 0) {
                        return "Amount must be greater than 0";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 26),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            side: const BorderSide(
                                color: _blue200, width: 1.5),
                            foregroundColor: _blue700,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_blue700, _blue900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _blue700.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                            onPressed: onConfirm,
                            child: Text(confirmLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}