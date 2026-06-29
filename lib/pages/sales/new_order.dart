import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/custom_dialogue_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_button_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class NewOrder extends StatefulWidget {
  final Map shop;
  final Map order;

  const NewOrder({super.key, this.order = const {}, required this.shop});

  @override
  State<NewOrder> createState() => _NewOrderState();
}

class _NewOrderState extends State<NewOrder> {
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
  static const Color _red      = Color(0xFFFF6B6B);
  static const Color _redBg    = Color(0xFFFFF0F0);

  static const List<Color> _bgColors = [_blue50, _indigo50, _sky50, _violet50];
  static const List<Color> _fgColors = [_blue700, _indigo, _blue500, _violet];

  // ─── Controllers ──────────────────────────────────────────────────────────
  final _quantityController = TextEditingController();
  final _namesController    = TextEditingController();
  final _emailController    = TextEditingController();
  final _addressController  = TextEditingController();
  final _phoneController    = TextEditingController();
  final _discountController = TextEditingController();

  final _formKey        = GlobalKey<FormState>();
  final _formKeyConfirm = GlobalKey<FormState>();

  List<Map> scannedProducts = [];
  List<Map> shopProducts    = [];
  bool _isSubmitting        = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _namesController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _orderTotal => scannedProducts.fold(0.0, (sum, p) {
        final price = double.tryParse(p['price'].toString()) ?? 0;
        final qty   = (p['scanned_quantity'] as int?) ?? 0;
        return sum + price * qty;
      });

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    shopProducts = List<Map>.from(ProductsData.products[widget.shop['id'].toString()] ?? []);

    return ScaffoldWidget(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextWidget(
            text: "New Order",
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
      body: scannedProducts.isEmpty ? _buildEmptyState() : _buildCartBody(),
      floatingActionButton: _buildScanFAB(),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _blue50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _blue200, width: 1.5),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  size: 50, color: _blue500),
            ),
            const SizedBox(height: 24),
            const Text(
              "Cart is empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the scan button below to scan a product barcode and add it to the order",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Hint arrow pointing down toward FAB
            Column(
              children: [
               const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 28, color: _blue200),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 28, color: _blue200.withValues(alpha: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Cart body ─────────────────────────────────────────────────────────────
  Widget _buildCartBody() {
    return Column(
      children: [
        _buildSummaryStrip(),
        const SizedBox(height: 4),
        _buildSwipeHint(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: scannedProducts.length,
            separatorBuilder: (_, __) =>
               const Divider(height: 1, thickness: 0.7, color: _blue50),
            itemBuilder: (_, i) => _buildCartItem(scannedProducts[i], i),
          ),
        ),
        _buildConfirmButton(),
      ],
    );
  }

  // Small one-time hint
  Widget _buildSwipeHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.swipe_left_alt_rounded, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            "Swipe left to remove  ·  Tap qty to edit",
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─── Summary strip ─────────────────────────────────────────────────────────
  Widget _buildSummaryStrip() {
    final double discount =
        double.tryParse(_discountController.text) ?? 0;
    final double grandTotal = (_orderTotal - discount).clamp(0, double.infinity);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _blue50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue200, width: 1),
      ),
      child: Row(
        children: [
          // Items count
          _summaryChip(
            icon: Icons.shopping_bag_outlined,
            label: "${scannedProducts.length} item${scannedProducts.length == 1 ? '' : 's'}",
            bg: Colors.white,
            fg: _blue700,
            border: _blue200,
          ),
          const SizedBox(width: 8),
          // Total
          _summaryChip(
            icon: Icons.receipt_long_rounded,
            label: "${grandTotal.toStringAsFixed(0)} TZS",
            bg: _greenBg,
            fg: _green,
            border: _green.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
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

  // ─── Cart item (swipe to dismiss + tap qty to edit) ────────────────────────
  Widget _buildCartItem(Map product, int index) {
    final Color iconBg = _bgColors[index % _bgColors.length];
    final Color iconFg = _fgColors[index % _fgColors.length];
    final int qty      = (product['scanned_quantity'] as int?) ?? 0;
    final double price = double.tryParse(product['price'].toString()) ?? 0;
    final double total = qty * price;

    return Dismissible(
      key: ValueKey(product['id'] ?? index),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _redBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Remove",
                style: TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
             SizedBox(width: 8),
             Icon(Icons.delete_outline_rounded, color: _red, size: 20),
          ],
        ),
      ),
      onDismissed: (_) {
        setState(() => scannedProducts.removeAt(index));
        HapticFeedback.lightImpact();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child:
                  Icon(Icons.inventory_2_rounded, color: iconFg, size: 22),
            ),
            const SizedBox(width: 14),

            // Name + unit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten_rounded,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        "${product['unit_value']} ${product['unit']}",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 10),
                      // Tappable qty badge
                      GestureDetector(
                        onTap: () => _editQuantity(index, product),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _blue50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _blue200),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "×$qty",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _blue700,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.edit_rounded,
                                  size: 10, color: _blue500),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Price per unit + line total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_blue700, _blue900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _blue700.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    "${total.toStringAsFixed(0)} TZS",
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "@${price.toStringAsFixed(0)}/unit",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Edit quantity inline dialog ───────────────────────────────────────────
  void _editQuantity(int index, Map product) {
    _quantityController.text =
        (product['scanned_quantity'] as int? ?? 1).toString();

    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        title: "Edit Quantity",
        content: [
          // Product card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue200),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    color: _blue700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    product['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Form(
            key: _formKey,
            child: TextFieldWidget(
              textInputType: TextInputType.number,
              hintText: "New quantity",
              labelText: "Quantity",
              textEditingController: _quantityController,
              functionValidate: (value) {
                if (value.toString().isEmpty) {
                  return "Quantity is required";
                }
                if (int.tryParse(value.toString()) == null ||
                    int.parse(value.toString()) <= 0) {
                  return "Invalid quantity";
                }
                return null;
              },
            ),
          ),
        ],
        actions: [
          TextButtonWidget(
            textButton: "Cancel",
            textColor: Colors.red,
            onPressed: () => Navigator.pop(context),
          ),
          TextButtonWidget(
            textButton: "Update",
            textColor: _blue700,
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              setState(() {
                scannedProducts[index]['scanned_quantity'] =
                    int.parse(_quantityController.text);
              });
              _quantityController.clear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ─── Scan FAB ──────────────────────────────────────────────────────────────
  Widget _buildScanFAB() {
    return FloatingActionButton.extended(
      backgroundColor: _blue700,
      elevation: 4,
      onPressed: _openScanner,
      icon: const Icon(Icons.qr_code_scanner_rounded,
          color: Colors.white, size: 22),
      label: const Text(
        "Scan",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SimpleBarcodeScannerPage(
          lineColor: "#1A56DB",
          isShowFlashIcon: true,
          appBarTitle: "Scan Barcode",
          centerTitle: true,
        ),
      ),
    ).then((barcode) {
      if (barcode != null && barcode != "-1") {
        addProduct(barcode.toString());
      }
    });
  }

  // ─── Add product ───────────────────────────────────────────────────────────
  void addProduct(String barcode) {
    _quantityController.clear();

    Map? product;
    for (Map p in shopProducts) {
      if (p['barcode'].toString() == barcode) {
        product = Map.from(p);
        break;
      }
    }

    if (product == null) {
      toast("Product not found");
      return;
    }

    final alreadyAdded =
        scannedProducts.any((p) => p['barcode'].toString() == barcode);
    if (alreadyAdded) {
      toast("Product already in cart");
      return;
    }

    _showAddToCartDialog(product);
  }

  // ─── Add-to-cart dialog ────────────────────────────────────────────────────
  Future _showAddToCartDialog(Map product) {
    final double price =
        double.tryParse(product['price'].toString()) ?? 0;

    return showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        title: "Add to cart",
        content: [
          // Product preview card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue200),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _blue200),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: _blue700, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        "${product['unit_value']} ${product['unit']}",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_blue700, _blue900]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${price.toStringAsFixed(0)} TZS",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Form(
            key: _formKey,
            child: TextFieldWidget(
              textInputType: TextInputType.number,
              hintText: "Enter quantity",
              labelText: "Quantity",
              textEditingController: _quantityController,
              functionValidate: (value) {
                if (value.toString().isEmpty) {
                  return "Quantity is required";
                }
                if (int.tryParse(value.toString()) == null ||
                    int.parse(value.toString()) <= 0) {
                  return "Invalid quantity";
                }
                return null;
              },
            ),
          ),
        ],
        actions: [
          TextButtonWidget(
            textButton: "Cancel",
            textColor: Colors.red,
            onPressed: () => Navigator.pop(context),
          ),
          TextButtonWidget(
            textButton: "Add to Cart",
            textColor: _blue700,
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              setState(() {
                product['scanned_quantity'] =
                    int.parse(_quantityController.text);
                scannedProducts.insert(0, product);
              });
              _quantityController.clear();
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  // ─── Confirm order dialog ──────────────────────────────────────────────────
  void openConfirmDialog() {
    _discountController.text = "0";

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => CustomDialogBox(
          title: "Confirm Order",
          content: [
            // Order summary card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _blue50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _blue200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined,
                              size: 14, color: _blue700),
                          const SizedBox(width: 6),
                          Text(
                            "${scannedProducts.length} item${scannedProducts.length == 1 ? '' : 's'}",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _blue700),
                          ),
                        ],
                      ),
                      Text(
                        "${_orderTotal.toStringAsFixed(0)} TZS",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _green),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Form(
              key: _formKeyConfirm,
              child: Column(
                children: [
                  TextFieldWidget(
                    textInputType: TextInputType.text,
                    hintText: "Customer names (optional)",
                    labelText: "Names",
                    textEditingController: _namesController,
                    functionValidate: (value) {
                      return null;
                    },
                  ),
                  TextFieldWidget(
                    textInputType: TextInputType.emailAddress,
                    hintText: "Customer email (optional)",
                    labelText: "Email",
                    textEditingController: _emailController,
                    functionValidate: (value) {
                      return null;
                    },
                  ),
                  TextFieldWidget(
                    textInputType: TextInputType.phone,
                    hintText: "Customer phone (optional)",
                    labelText: "Phone",
                    textEditingController: _phoneController,
                    functionValidate: (value) {
                      return null;
                    },
                  ),
                  TextFieldWidget(
                    textInputType: TextInputType.text,
                    hintText: "Customer address (optional)",
                    labelText: "Address",
                    textEditingController: _addressController,
                    functionValidate: (value) {
                      return null;
                    },
                  ),
                  TextFieldWidget(
                    textInputType: TextInputType.number,
                    hintText: "0",
                    labelText: "Discount (TZS)",
                    textEditingController: _discountController,
                    functionValidate: (value) {
                      if (value.toString().isEmpty) {
                        return "Enter 0 if no discount";
                      }
                      if (int.tryParse(value.toString()) == null ||
                          int.parse(value.toString()) < 0) {
                        return "Must be 0 or greater";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
          actions: [
            TextButtonWidget(
              textButton: "Cancel",
              textColor: _red,
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButtonWidget(
              textButton: _isSubmitting ? "Placing…" : "Place Order",
              textColor: _green,
              onPressed: _isSubmitting ? () {} : submitOrder,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirm button ────────────────────────────────────────────────────────
  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_green, Color(0xFF00966A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: openConfirmDialog,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Confirm Order",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 15.5,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_orderTotal.toStringAsFixed(0)} TZS",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Submit ────────────────────────────────────────────────────────────────
  Future<void> submitOrder() async {
    if (!_formKeyConfirm.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final Map data = {"products": _getProductsPayload()};

    if (_discountController.text.isNotEmpty &&
        _discountController.text != "0") {
      data["discount"] = _discountController.text;
    }
    if (_namesController.text.isNotEmpty) {
      data["customer_names"] = _namesController.text;
    }
    if (_emailController.text.isNotEmpty) {
      data["customer_email"] = _emailController.text;
    }
    if (_phoneController.text.isNotEmpty) {
      data["customer_phone"] = _phoneController.text;
    }
    if (_addressController.text.isNotEmpty) {
      data["customer_address"] = _addressController.text;
    }

    final String shopId = widget.shop['id'].toString();
    final Map response =
        await APIService.api("POST", "shops/$shopId/sales/new", data);

    setState(() => _isSubmitting = false);

    if (response['httpCode'] == 201) {
      toast("Order placed successfully!");
      Navigator.pop(context); // close dialog
      Navigator.pop(context); // back to orders
    } else {
      toast("Failed to place order. Please try again.");
    }
  }

  List _getProductsPayload() {
    return scannedProducts
        .map((p) => {
              "product_id": p['id'].toString(),
              "quantity": p['scanned_quantity'].toString(),
            })
        .toList();
  }
}