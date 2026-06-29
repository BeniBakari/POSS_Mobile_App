// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/floatingActionButton_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/registersData.dart';
import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/time_diference.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

class Registers extends StatefulWidget {
  final Map shop;
  const Registers({required this.shop, super.key});

  @override
  State<Registers> createState() => _RegistersState();
}

class _RegistersState extends State<Registers> {
  late Map shop;
  final closingController = TextEditingController();
  final openingController = TextEditingController();
  final GlobalKey<FormState> closingFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formKey       = GlobalKey<FormState>();

  // SEARCH
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  Timer? _debounce;
  bool isSearching = false;
  List filteredRegisters = [];
  List allRegisters      = [];

  bool hasUnclosedRegister = false;

  // 🔵 Blue palette — consistent with Products & Purchases
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

  // Status colors
  static const Color _green    = Color(0xFF00B87C);
  static const Color _greenBg  = Color(0xFFE6FAF4);
  static const Color _orange   = Color(0xFFF59E0B);
  static const Color _orangeBg = Color(0xFFFFF8E1);
  static const Color _red      = Color(0xFFEF4444);
  static const Color _redBg    = Color(0xFFFFEEEE);

  @override
  void initState() {
    super.initState();
    shop = widget.shop;
    _checkUnclosedRegister();
  }

  @override
  void dispose() {
    openingController.dispose();
    closingController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkUnclosedRegister() async {
    await RegistersData.getRegisters(shop['id'].toString());
    final List? registers = RegistersData.registers[shop['id'].toString()];
    if (registers != null) {
      setState(() {
        allRegisters = registers;
        hasUnclosedRegister =
            registers.any((r) => r['closing_cash'].toString() == "null");
      });
    }
  }

  // ─── Search logic ──────────────────────────────────────────────────────────
  void onSearch(String query) {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        filteredRegisters = [];
      });
      return;
    }

    final results = allRegisters.where((register) {
      final openedByUser =
          UserData.users[register['opened_by'].toString()] ?? {};
      final openedByName =
          "${openedByUser['first_name'] ?? ''} ${openedByUser['last_name'] ?? ''}"
              .toLowerCase();
      final opening = register['opening_cash'].toString().toLowerCase();
      final closing  = register['closing_cash'].toString().toLowerCase();
      final date =
          TimeDifference.getDate(register['created_at']).toLowerCase();

      return openedByName.contains(query) ||
          opening.contains(query) ||
          closing.contains(query) ||
          date.contains(query);
    }).toList();

    setState(() {
      isSearching       = true;
      filteredRegisters = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Future<List?> registersFuture =
        RegistersData.getRegisters(shop['id'].toString());

    return ScaffoldWidget(
      title: Column(
        children: [
          TextWidget(
              text: "Registers", color: ColorsWidget().appBarColor),
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
          onBtnPressed: _showOpenRegisterDialog),
      body: FutureBuilder(
        future: registersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _blue700));
          }

          if (!RegistersData.registers
              .containsKey(shop['id'].toString())) {
            return _buildEmptyState("No registers available");
          }

          final List registers =
              RegistersData.registers[shop['id'].toString()]!;
          allRegisters = registers;
          final Map last = registers.last;
          final List displayList =
              isSearching ? filteredRegisters : registers;

          return Column(
            children: [
              const SizedBox(height: 14),

              // // 🔍 Search bar
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: _buildSearchBar(),
              // ),

              // const SizedBox(height: 8),

              // Summary strip
              if (!isSearching) _buildSummaryStrip(registers),

              // List
              Expanded(
                child: displayList.isEmpty
                    ? _buildEmptyState(
                        isSearching ? "No results found" : "No registers yet")
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: displayList.length,
                        itemBuilder: (context, index) =>
                            _buildRegisterItem(
                                displayList[index], last, index),
                      ),
              ),
            ],
          );
        },
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
              const Duration(milliseconds: 300), () => onSearch(value));
        },
        decoration: InputDecoration(
          hintText: "Search by name, amount or date...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
          prefixIcon: const Icon(Icons.search, color: _blue500),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey[400], size: 18),
                  onPressed: () {
                    searchController.clear();
                    onSearch('');
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

  // ─── Summary strip ─────────────────────────────────────────────────────────
  Widget _buildSummaryStrip(List registers) {
    final int total  = registers.length;
    final int open   = registers.where((r) => r['closing_cash'].toString() == "null").length;
    final int closed = total - open;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _summaryChip("$total Total", _blue50, _blue700),
          const SizedBox(width: 8),
          _summaryChip("$open Open", _orangeBg, _orange),
          const SizedBox(width: 8),
          _summaryChip("$closed Closed", _greenBg, _green),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg)),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.point_of_sale_outlined,
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

  // ─── Register flat item ────────────────────────────────────────────────────
  Widget _buildRegisterItem(Map register, Map last, int index) {
    final Map openedByUser =
        UserData.users[register['opened_by'].toString()] ?? {};
    final Map closedByUser =
        register['closed_by'].toString() != "null"
            ? UserData.users[register['closed_by'].toString()] ?? {}
            : {};

    final bool isClosed = register['closing_cash'].toString() != "null";
    final String openingCash = register['opening_cash'].toString();
    final String closingCash =
        isClosed ? register['closing_cash'].toString() : "Open";
    final String openedByName =
        "${openedByUser['first_name'] ?? '-'} ${openedByUser['last_name'] ?? '-'}";
    final String closedByName = isClosed
        ? "${closedByUser['first_name'] ?? '-'} ${closedByUser['last_name'] ?? '-'}"
        : "—";

    final bool canEdit =
        TimeDifference.hours(register['created_at'].toString()) <= 12 &&
            !isClosed;
    final bool canReopen =
        isClosed &&
            TimeDifference.hours(register['updated_at']) <= 2 &&
            register == last;

    // Icon badge cycling
    final List<Color> bgColors = [_blue50, _indigo50, _sky50, _violet50];
    final List<Color> fgColors = [_blue700, _indigo, _blue500, _violet];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Icon(Icons.point_of_sale_outlined,
                    color: fgColors[index % fgColors.length], size: 21),
              ),

              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opening / Closing amounts row
                    Row(
                      children: [
                        _amountBadge("Open  $openingCash", _blue50, _blue700),
                        const SizedBox(width: 8),
                        _amountBadge(
                          isClosed ? "Close  $closingCash" : "Open",
                          isClosed ? _greenBg : _orangeBg,
                          isClosed ? _green   : _orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Opened by
                    _infoRow(Icons.person_outline_rounded,
                        "By $openedByName"),

                    if (isClosed)
                      _infoRow(Icons.person_off_outlined,
                          "Closed by $closedByName"),

                    _infoRow(Icons.access_time_rounded,
                        TimeDifference.getDate(register['created_at'])),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action buttons stacked vertically
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (canEdit)
                    _actionButton("Edit", _blue50, _blue700,
                        () => _showEditRegisterDialog(register)),
                  if (!isClosed)
                    _actionButton("Close", _redBg, _red,
                        () => _showCloseRegisterDialog(register)),
                  if (canReopen)
                    _actionButton("Reopen", _orangeBg, _orange,
                        () => _reopenRegister(register)),
                ],
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, thickness: 0.7, color: _blue50),
        ),
      ],
    );
  }

  Widget _amountBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _blue200),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg)),
      ),
    );
  }

  // ─── Open register dialog ──────────────────────────────────────────────────
  void _showOpenRegisterDialog() {
    openingController.clear();
    _showRegisterDialog(
      title: "Open Register",
      icon: Icons.lock_open_rounded,
      iconColor: _blue700,
      formKey: formKey,
      field: _buildOpeningField(),
      confirmLabel: "Open",
      confirmColor: _blue700,
      onConfirm: () async {
        if (!formKey.currentState!.validate()) return;
        final String shopId = shop['id'].toString();
        final Map data = {"opening_cash": openingController.text};
        final Map response = await APIService.api(
            "POST", "shops/$shopId/registers/new", data);

        if (response['httpCode'] == 200 || response['httpCode'] == 201) {
          final Map body = jsonDecode(response['body']);
          if (body['success'] == true) {
            toast("Successfully opened.");
            Navigator.pop(context);
          } else if (body['message'].toString() ==
              "There is unclosed register, please close first.") {
            Navigator.pop(context);
            _showAlertDialog(
                "There is an open register, please close it first.");
          }
        }
        await _checkUnclosedRegister();
      },
    );
  }

  // ─── Edit register dialog ──────────────────────────────────────────────────
  void _showEditRegisterDialog(Map register) {
    openingController.text = register['opening_cash'].toString();
    _showRegisterDialog(
      title: "Edit Register",
      icon: Icons.edit_rounded,
      iconColor: _blue700,
      formKey: formKey,
      field: _buildOpeningField(),
      confirmLabel: "Update",
      confirmColor: _blue700,
      onConfirm: () async {
        if (!formKey.currentState!.validate()) return;
        final Map data = {"opening_cash": openingController.text};
        final String registerId = register['id'].toString();
        final Map response = await APIService.api(
            "PUT", "shops/registers/update/$registerId", data);

        if (response['httpCode'] == 200 || response['httpCode'] == 201) {
          final Map body = jsonDecode(response['body']);
          if (body['success'] == true) {
            toast("Register updated successfully.");
          } else {
            toast(body['message']);
          }
          Navigator.pop(context);
        }
      },
    );
  }

  // ─── Close register dialog ─────────────────────────────────────────────────
  void _showCloseRegisterDialog(Map register) {
    closingController.clear();
    _showRegisterDialog(
      title: "Close Register",
      icon: Icons.lock_rounded,
      iconColor: _red,
      formKey: closingFormKey,
      field: _buildClosingField(),
      confirmLabel: "Close",
      confirmColor: _red,
      onConfirm: () async {
        if (!closingFormKey.currentState!.validate()) return;
        final Map data = {"closing_cash": closingController.text};
        final String registerId = register['id'].toString();
        final Map response = await APIService.api(
            "PATCH", "shops/registers/close/$registerId", data);

        if (response['httpCode'] == 200 || response['httpCode'] == 201) {
          final Map body = jsonDecode(response['body']);
          if (body['success'] == true) {
            toast("Successfully closed.");
            Navigator.pop(context);
          }
        }
        await _checkUnclosedRegister();
      },
    );
  }

  // ─── Reopen register ───────────────────────────────────────────────────────
  void _reopenRegister(Map register) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _orangeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: _orange, size: 28),
              ),
              const SizedBox(height: 16),
              const Text("Reopen Register",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text("Are you sure you want to reopen this register?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: Colors.grey[600])),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(
                            color: _blue200, width: 1.5),
                        foregroundColor: _blue700,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("No",
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _gradientButton(
                      label: "Yes, Reopen",
                      gradientColors: [_orange, const Color(0xFFB45309)],
                      onTap: () async {
                        final String registerId =
                            register['id'].toString();
                        final Map response = await APIService.api(
                            "PATCH",
                            "shops/registers/reopen/$registerId",
                            {});

                        if (response['httpCode'] == 200 ||
                            response['httpCode'] == 201) {
                          final Map body =
                              jsonDecode(response['body']);
                          if (body['success'] == true) {
                            toast("Successfully reopened.");
                            Navigator.pop(context);
                          }
                        }
                        await _checkUnclosedRegister();
                      },
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

  // ─── Generic register dialog ───────────────────────────────────────────────
  void _showRegisterDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required GlobalKey<FormState> formKey,
    required Widget field,
    required String confirmLabel,
    required Color confirmColor,
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
                          gradient: LinearGradient(
                            colors: [
                              iconColor,
                              Color.lerp(iconColor, Colors.black,
                                      0.35) ??
                                  iconColor
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.32),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child:
                            Icon(icon, color: Colors.white, size: 20),
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

                  field,

                  const SizedBox(height: 26),

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
                        child: _gradientButton(
                          label: confirmLabel,
                          gradientColors: [
                            confirmColor,
                            Color.lerp(confirmColor, Colors.black,
                                    0.35) ??
                                confirmColor,
                          ],
                          onTap: onConfirm,
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

  // ─── Alert dialog ──────────────────────────────────────────────────────────
  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _orangeBg,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.warning_amber_rounded,
                    color: _orange, size: 28),
              ),
              const SizedBox(height: 16),
              const Text("Attention",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: Colors.grey[600])),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: _gradientButton(
                  label: "OK",
                  gradientColors: [_blue700, _blue900],
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Gradient button helper ────────────────────────────────────────────────
  Widget _gradientButton({
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 15)),
      ),
    );
  }

  // ─── Text fields ───────────────────────────────────────────────────────────
  Widget _buildOpeningField() {
    return TextFieldWidget(
      textEditingController: openingController,
      hintText: 'Opening cash e.g. 40000',
      textInputType: TextInputType.number,
      labelText: 'Opening cash',
      functionValidate: (String value) {
        if (value.isEmpty) return "Opening cash is required";
        if (double.tryParse(value.trim()) == null) {
          return "Enter a valid number";
        }
        if (double.parse(value.trim()) < 0) {
          return "Amount cannot be negative";
        }
        return null;
      },
    );
  }

  Widget _buildClosingField() {
    return TextFieldWidget(
      textEditingController: closingController,
      hintText: 'Closing cash e.g. 40000',
      textInputType: TextInputType.number,
      labelText: 'Closing cash',
      functionValidate: (String value) {
        if (value.isEmpty) return "Closing cash is required";
        if (double.tryParse(value.trim()) == null) {
          return "Enter a valid number";
        }
        if (double.parse(value.trim()) < 0) {
          return "Amount cannot be negative";
        }
        return null;
      },
    );
  }
}