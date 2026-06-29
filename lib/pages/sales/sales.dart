import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/divider_widget.dart';
import 'package:poss_mobile_app/components/row_text_widget.dart';
import 'package:poss_mobile_app/components/scaffold_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/time_diference.dart';

class Sales extends StatefulWidget {
  final List sales;
  final Map shop;
  const Sales({super.key, required this.sales, required this.shop});

  @override
  State<Sales> createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  // ── ValueNotifiers drive all reactive UI — zero setState() anywhere ────────
  late final ValueNotifier<List> _filteredNotifier;
  late final ValueNotifier<bool> _isSearchingNotifier;

  @override
  void initState() {
    super.initState();
    _filteredNotifier    = ValueNotifier(widget.sales);
    _isSearchingNotifier = ValueNotifier(false);
  }

  @override
  void dispose() {
    _filteredNotifier.dispose();
    _isSearchingNotifier.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredNotifier.value    = widget.sales;
      _isSearchingNotifier.value = false;
      return;
    }
    _filteredNotifier.value = widget.sales.where((sale) {
      final Map product = sale['product'] ?? {};
      return product['name'].toString().toLowerCase().contains(query) ||
          product['unit'].toString().toLowerCase().contains(query) ||
          product['price'].toString().toLowerCase().contains(query) ||
          sale['quantity'].toString().toLowerCase().contains(query);
    }).toList();
    _isSearchingNotifier.value = true;
  }

  @override
  Widget build(BuildContext context) {
    // build() runs exactly ONCE — never again, because we never call setState()
    return ScaffoldWidget(
      title: Column(
        children: [
          TextWidget(
            text: widget.shop['name'],
            color: ColorsWidget().appBarColor,
            fontsize: 15,
          ),
          Text(
            "sold at ${TimeDifference.getDate(widget.sales[0]['updated_at'])}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: ColorsWidget().appBarColor,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            // Search bar is a stable leaf widget — it NEVER rebuilds
            _SalesSearchBar(onChanged: _onSearch),

            // Only the list area reacts to search changes
            Expanded(
              child: ValueListenableBuilder<List>(
                valueListenable: _filteredNotifier,
                builder: (_, filtered, __) {
                  if (filtered.isEmpty) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _isSearchingNotifier,
                      builder: (_, isSearching, __) =>
                          _buildEmptyState(isSearching),
                    );
                  }
                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.7,
                      color: Color(0xFFEFF6FF),
                      indent: 16,
                    ),
                    itemBuilder: (_, i) => _buildSaleItem(filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 52, color: Color(0xFFBFDBFE)),
          const SizedBox(height: 12),
          Text(
            isSearching ? "No results found" : "No sales yet",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFBFDBFE),
            ),
          ),
          const SizedBox(height: 4),
          if (isSearching)
            Text(
              "Try a different search term",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  Widget _buildSaleItem(Map sale) {
    final Map product      = sale['product'];
    final String name      = product['name'];
    final String unitValue = product['unit_value'].toString();
    final String unit      = product['unit'];
    final int? qty         = int.tryParse(sale['quantity'].toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RowTextWidget(
            firstColumn: "Product :",
            secondColumn: "$name $unitValue  $unit",
          ),
          RowTextWidget(
            firstColumn: "Quantity : ",
            secondColumn: qty.toString(),
          ),
          RowTextWidget(
            firstColumn: "Price @ : ",
            secondColumn: product['price'].toString(),
          ),
          RowTextWidget(
            firstColumn: "Total Price : ",
            secondColumn: (qty! * product['price']).toString(),
          ),
          const DividerWidget(),
        ],
      ),
    );
  }
}

// ── Completely isolated search bar ─────────────────────────────────────────
//
// Lives in its own StatefulWidget subtree. The parent (_SalesState) never
// calls setState(), so this widget is NEVER externally rebuilt. Its FocusNode
// and TextEditingController are owned here and survive forever. The keyboard
// physically cannot be dismissed by a parent rebuild because no parent rebuild
// ever happens.
//
class _SalesSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SalesSearchBar({required this.onChanged});

  @override
  State<_SalesSearchBar> createState() => _SalesSearchBarState();
}

class _SalesSearchBarState extends State<_SalesSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode             = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Search by product, unit, price...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF3B82F6), size: 22),
          // ListenableBuilder: only the clear button rebuilds, TextField never does
          suffixIcon: ListenableBuilder(
            listenable: _controller,
            builder: (_, __) {
              if (_controller.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.close_rounded,
                    color: Colors.grey[400], size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  _focusNode.requestFocus();
                },
              );
            },
          ),
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}