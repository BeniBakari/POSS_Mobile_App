import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/floatingActionButton_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/pages/products/barcode_list.dart';
import 'package:poss_mobile_app/pages/products/update_product.dart';

class Products extends StatefulWidget {
  final Map shop;
  const Products(this.shop, {super.key});

  @override
  State<Products> createState() => _ProductsState(shop);
}

class _ProductsState extends State<Products> {
  final Map shop;
  _ProductsState(this.shop);

  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late Future<List> _productsFuture;

  List shopProducts     = [];
  List filteredProducts = [];
  bool isSearching      = false;

  @override
  void initState() {
    super.initState();
    _productsFuture =
        ProductsData.getProducts(shop['id'].toString()).then((list) {
      if (mounted) setState(() => shopProducts = List.from(list));
      return list;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 🔵 Blue palette — same as Purchases
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

  // Cycling icon badge bg + fg — same pattern as Purchases
  static const List<Color> _bgColors = [_blue50, _indigo50, _sky50, _violet50];
  static const List<Color> _fgColors = [_blue700, _indigo, _blue500, _violet];

  @override
  Widget build(BuildContext context) {
    final appBarColor = ColorsWidget().appBarColor;

    return ScaffoldWidget(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextWidget(text: "Products", color: appBarColor, fontsize: 13),
          Text(
            shop['name'],
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: appBarColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: FutureBuilder(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                    color: appBarColor, strokeWidth: 2.5),
              );
            }

            final Map productsMap = ProductsData.products;
            if (!productsMap.containsKey(shop['id'].toString())) {
              return _buildEmptyState(appBarColor);
            }

            final List displayList =
                isSearching ? filteredProducts : shopProducts;

            return Column(
              children: [
                _buildSearchBar(),

                if (displayList.isEmpty)
                  Expanded(child: _buildEmptyState(appBarColor))
                else
                  Expanded(
                    child: ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 0.7,
                        color: _blue50,
                        indent: 70,
                      ),
                      itemBuilder: (context, index) =>
                          _buildProductRow(displayList[index] as Map, index),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButtonWidget(
        onBtnPressed: () {
          Navigator.push(
            context,
            SlideRightRoute(
              page: UpdateProduct(product: const {}, shop: shop),
            ),
          );
        },
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
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
        focusNode: _searchFocusNode,
        onChanged: onSearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Search products...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _blue500, size: 22),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey[400], size: 18),
                  onPressed: () {
                    searchController.clear();
                    onSearch('');
                    _searchFocusNode.requestFocus();
                  },
                )
              : null,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(Color appBarColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 52, color: _blue200),
          const SizedBox(height: 12),
          Text(
            isSearching ? "No results found" : "No products yet",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _blue200,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSearching
                ? "Try a different search term"
                : "Tap + to add your first product",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─── Search logic ─────────────────────────────────────────────────────────
  void onSearch(String query) {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        filteredProducts.clear();
      });
      return;
    }
    final results = shopProducts.where((product) {
      return product['name'].toString().toLowerCase().contains(query) ||
          product['description'].toString().toLowerCase().contains(query) ||
          product['unit'].toString().toLowerCase().contains(query);
    }).toList();

    setState(() {
      isSearching      = true;
      filteredProducts = results;
    });
  }

  // ─── Product row ──────────────────────────────────────────────────────────
  Widget _buildProductRow(Map product, int index) {
    final int quantity = int.tryParse(product['quantity'].toString()) ?? 0;
    final bool inStock = quantity > 0;

    final Color iconBg = _bgColors[index % _bgColors.length];
    final Color iconFg = _fgColors[index % _fgColors.length];

    return InkWell(
      onLongPress: () => Navigator.push(
        context,
        SlideRightRoute(page: BarcodeList(product: product)),
      ),
      onDoubleTap: () => Navigator.push(
        context,
        SlideRightRoute(
            page: UpdateProduct(product: product, shop: shop)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.inventory_2_rounded, color: iconFg, size: 22),
            ),

            const SizedBox(width: 14),

            // Name + unit + stock
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
                  const SizedBox(height: 3),
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
                      Icon(
                        inStock
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 12,
                        color: inStock
                            ? const Color(0xFF00B87C)
                            : const Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        inStock ? "×$quantity" : "Out of stock",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: inStock
                              ? const Color(0xFF00B87C)
                              : const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price badge — deep blue gradient matching purchases cost pill
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
                "${product['price']}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}