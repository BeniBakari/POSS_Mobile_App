import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/button_widget.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/models/product.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/product_ops.dart';

class UpdateProduct extends StatefulWidget {
  final Map product;
  final Map shop;
  const UpdateProduct({required this.product, required this.shop, super.key});

  @override
  State<UpdateProduct> createState() => _UpdateProductState(product, shop);
}

class _UpdateProductState extends State<UpdateProduct>
    with SingleTickerProviderStateMixin {
  final Map product;
  final Map shop;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final unitController = TextEditingController();
  final unitValueController = TextEditingController();
  final priceController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  late AnimationController _animController;
  late List<Animation<double>> _fadeAnims;

  _UpdateProductState(this.product, this.shop);

  @override
  void initState() {
    super.initState();

    if (product.isNotEmpty) {
      nameController.text = product['name'] ?? '';
      descriptionController.text = product['description'] ?? '';
      unitController.text = product['unit'] ?? '';
      unitValueController.text = product['unit_value'].toString();
      priceController.text = product['price'].toString();
    }

    // Staggered entrance animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnims = List.generate(7, (i) {
      final start = i * 0.1;
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start.clamp(0, 1), (start + 0.4).clamp(0, 1),
            curve: Curves.easeOutCubic),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    unitController.dispose();
    unitValueController.dispose();
    priceController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Field definitions ────────────────────────────────────────────────────
  static const List<_FieldDef> _fields = [
    _FieldDef("Name", "Enter product name",
        Icons.drive_file_rename_outline_rounded, TextInputType.text),
    _FieldDef("Description", "Enter product description", Icons.notes_rounded,
        TextInputType.text),
    _FieldDef("Unit", "e.g. Kg, ml, pcs", Icons.straighten_rounded,
        TextInputType.text),
    _FieldDef("Unit Value", "e.g. 350", Icons.format_list_numbered_rounded,
        TextInputType.number),
    _FieldDef(
        "Price", "e.g. 800", Icons.payments_rounded, TextInputType.number),
  ];

  List<TextEditingController> get _controllers => [
        nameController,
        descriptionController,
        unitController,
        unitValueController,
        priceController,
      ];

  @override
  Widget build(BuildContext context) {
    final appBarColor = ColorsWidget().appBarColor;
    final bool isNew = product.isEmpty;

    return ScaffoldWidget(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextWidget(
            text: isNew ? "New Product" : "Update Product",
            color: appBarColor,
            fontsize: 13,
          ),
          if (!isNew)
            Text(
              "${product['name']} (${product['quantity']})",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: appBarColor,
                letterSpacing: 0.2,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section header ──
              _buildAnimated(
                0,
                _sectionHeader(
                  appBarColor,
                  isNew ? "Product Details" : "Edit Details",
                  isNew
                      ? "Fill in the information below to add a new product."
                      : "Update the fields and press save when done.",
                ),
              ),

              const SizedBox(height: 24),

              // ── Fields ──
              ...List.generate(_fields.length, (i) {
                return _buildAnimated(
                  i + 1,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _buildField(
                      appBarColor: appBarColor,
                      def: _fields[i],
                      controller: _controllers[i],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              // ── Save button ──
              _buildAnimated(
                6,
                _buildSaveButton(appBarColor, isNew),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section header ───────────────────────────────────────────────────────
  Widget _sectionHeader(Color accent, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Individual field with label above ───────────────────────────────────
  Widget _buildField({
    required Color appBarColor,
    required _FieldDef def,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(def.icon, size: 15, color: appBarColor.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              def.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: appBarColor.withValues(alpha: 0.75),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        // Input
        TextFieldWidget(
          textEditingController: controller,
          labelText: '',
          hintText: def.hint,
          textInputType: def.inputType,
          prefixIcon:
              Icon(def.icon, color: appBarColor.withValues(alpha: 0.5), size: 20),
          functionValidate: (String value) {
            if (value.isEmpty) return "${def.label} is required";
            return null;
          },
        ),
      ],
    );
  }

  // ─── Save / Update button ─────────────────────────────────────────────────
  Widget _buildSaveButton(Color appBarColor, bool isNew) {
    return SizedBox(
      width: double.infinity,
      child: _isSaving
          ? Center(
              child: CircularProgressIndicator(
                color: appBarColor,
                strokeWidth: 2.5,
              ),
            )
          : Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: appBarColor.withValues(alpha: 0.6), size: 18),
                    label: Text(
                      "Cancel",
                      style: TextStyle(
                        color: appBarColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: appBarColor.withValues(alpha: 0.25), width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Save / Update
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: Icon(
                      isNew ? Icons.add_rounded : Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      isNew ? "Save Product" : "Update Product",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appBarColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Staggered animation wrapper ─────────────────────────────────────────
  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index.clamp(0, _fadeAnims.length - 1)],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_fadeAnims[index.clamp(0, _fadeAnims.length - 1)]),
        child: child,
      ),
    );
  }

  // ─── Save logic ───────────────────────────────────────────────────────────
  Future<void> _saveProduct() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final String method = product.isEmpty ? "POST" : "PUT";
    final String link = product.isEmpty
        ? "shops/${shop['id']}/products/new"
        : "shops/product/update/${product['id']}";

    final Map data = {
      "name": nameController.text,
      "description": descriptionController.text,
      "unit": unitController.text,
      "unit_value": unitValueController.text,
      "price": priceController.text,
    };

    final Map response = await APIService.api(method, link, data);
    print(response);
    setState(() => _isSaving = false);

    if (response['httpCode'] == 200 || response['httpCode'] == 201) {
      final Map body = jsonDecode(response['body']);
      if (body['success'] == true) {
        toast("Saved successfully.");
        final Map productData = body['data'];
        if (product.isEmpty) {
          ProductsData.addProduct(
              productData['shop_id'].toString(), productData);
          ProductOps.create(Product(
            id: productData['id'].toString(),
            name: productData['name'].toString(),
            description: productData['description'].toString(),
            unit: productData['unit'].toString(),
            unitValue: productData['unit_value'].toString(),
            quantity: productData['quantity'].toString(),
            barcode: productData['barcode'].toString(),
            price: productData['price'].toString(),
            shopId: productData['shop_id'].toString(),
            addedBy: productData['added_by'].toString(),
            isActive: productData['is_active'].toString(),
          ));
        }
      }
    }

    Navigator.pop(context);
  }
}

// ─── Field definition model ───────────────────────────────────────────────────
class _FieldDef {
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType inputType;
  const _FieldDef(this.label, this.hint, this.icon, this.inputType);
}
