// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/data/purchaseData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

class Purchases extends StatefulWidget {
  final Map shop;
  const Purchases({required this.shop, super.key});

  @override
  State<Purchases> createState() => _PurchasesState();
}

class _PurchasesState extends State<Purchases> {
  late Map shop;
  late Future<List?> purchasesFuture;

  // SEARCH
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  Timer? _debounce;

  bool isSearching = false;
  List filteredPurchases = [];
  List allPurchases = [];

  // ADD PURCHASE
  Map? selectedProduct;
  List products = [];
  final costController     = TextEditingController();
  final quantityController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // 🔵 Blue palette
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

  @override
  void initState() {
    super.initState();
    shop = widget.shop;
    purchasesFuture = PurchaseData.getPurchases(shop['id'].toString());
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    costController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: Column(
        children: [
          Text("Purchases",
              style: TextStyle(color: ColorsWidget().appBarColor)),
          Text(shop['name'],
              style: TextStyle(fontSize: 12, color: ColorsWidget().appBarColor)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _blue700,
        elevation: 6,
        onPressed: _showAddPurchaseDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder(
        future: purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _blue700));
          }

          allPurchases = PurchaseData.purchases[shop['id'].toString()] ?? [];
          final displayList = isSearching ? filteredPurchases : allPurchases;

          return Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: displayList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 52, color: _blue200),
                            SizedBox(height: 12),
                            Text(
                              "No purchases yet",
                              style: TextStyle(
                                  color: _blue200,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: displayList.length,
                        itemBuilder: (context, index) =>
                            _buildPurchaseItem(displayList[index], index),
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
          hintText: "Search purchases...",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: _blue500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void onSearch(String query) {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        filteredPurchases = [];
      });
      return;
    }
    final results = allPurchases.where((purchase) {
      final product = purchase.containsKey("product")
          ? purchase['product']
          : ProductsData.getProduct(
              shop['id'].toString(), purchase['product_id']) as Map;
      return product['name'].toString().toLowerCase().contains(query);
    }).toList();

    setState(() {
      isSearching = true;
      filteredPurchases = results;
    });
  }

  // ─── Flat list item ────────────────────────────────────────────────────────
  Widget _buildPurchaseItem(Map purchase, int index) {
    final product = purchase.containsKey("product")
        ? purchase['product']
        : ProductsData.getProduct(
            shop['id'].toString(), purchase['product_id']) as Map;

    final List<Color> bgColors = [_blue50, _indigo50, _sky50, _violet50];
    final List<Color> fgColors = [_blue700, _indigo, _blue500, _violet];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bgColors[index % bgColors.length],
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    color: fgColors[index % fgColors.length], size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined,
                            size: 13, color: _blue200),
                        const SizedBox(width: 4),
                        Text(
                          "Qty  ${purchase['quantity']}",
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_blue700, _blue900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _blue700.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  "${purchase['cost']}",
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
    );
  }

  // ─── Add dialog ────────────────────────────────────────────────────────────
  void _showAddPurchaseDialog() {
    products = ProductsData.products[shop['id'].toString()] ?? [];

    if (products.isEmpty) {
      toast("No products available.");
      return;
    }

    // ✅ Full reset — no pre-selection
    selectedProduct = null;
    costController.clear();
    quantityController.clear();

    // Local state for the dropdown inside the dialog
    String? localDropValue;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Header ──
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
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          "Add Purchase",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── Product dropdown ──
                    // value is strictly localDropValue (starts null)
                    // items list does NOT include a null/placeholder item
                    // Flutter will show hint when value == null
                    DropdownButtonFormField<String>(
                      initialValue: localDropValue,
                      isExpanded: true,
                      hint: const Text(
                        "Select a product",
                        style: TextStyle(
                            color: Colors.grey, fontSize: 14),
                      ),
                      decoration: InputDecoration(
                        labelText: "Product",
                        labelStyle: const TextStyle(color: _blue500),
                        prefixIcon: const Icon(
                            Icons.inventory_2_outlined,
                            color: _blue500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _blue200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: _blue200, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: _blue700, width: 1.8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Colors.red, width: 1.2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Colors.red, width: 1.8),
                        ),
                      ),
                      validator: (val) =>
                          (val == null || val.isEmpty)
                              ? "Please select a product"
                              : null,
                      items: products
                          .map<DropdownMenuItem<String>>((p) =>
                              DropdownMenuItem<String>(
                                value: p['id'].toString(),
                                child: Text(p['name'],
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => localDropValue = val);
                          selectedProduct = products.firstWhere(
                              (e) => e['id'].toString() == val);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Unit cost ──
                    TextFieldWidget(
                      textInputType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      hintText: "Enter unit cost",
                      labelText: "Unit Cost",
                      textEditingController: costController,
                      functionValidate: (v) {
                        if (v.trim().isEmpty) {
                          return "Cost is required";
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return "Enter a valid number";
                        }
                        if (double.parse(v.trim()) <= 0) {
                          return "Cost must be greater than 0";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Quantity ──
                    TextFieldWidget(
                      textInputType: TextInputType.number,
                      hintText: "Enter quantity",
                      labelText: "Quantity",
                      textEditingController: quantityController,
                      functionValidate: (v) {
                        if (v.trim().isEmpty) {
                          return "Quantity is required";
                        }
                        if (int.tryParse(v.trim()) == null) {
                          return "Enter a whole number";
                        }
                        if (int.parse(v.trim()) <= 0) {
                          return "Quantity must be greater than 0";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 26),

                    // ── Buttons ──
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
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final data = {
                                  "product_id":
                                      selectedProduct!['id'].toString(),
                                  "cost": costController.text.trim(),
                                  "quantity":
                                      quantityController.text.trim(),
                                };

                                final res = await APIService.api(
                                  "POST",
                                  "shops/${shop['id']}/purchases/new",
                                  data,
                                );

                                if (res['httpCode'] == 201) {
                                  toast("Purchase added!");
                                  setState(() {});
                                  Navigator.pop(context);
                                } else {
                                  toast("Failed to add purchase");
                                }
                              },
                              child: const Text(
                                "Save",
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
          ),
        ),
      ),
    );
  }
}