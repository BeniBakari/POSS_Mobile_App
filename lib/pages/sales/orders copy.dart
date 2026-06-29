// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:poss_mobile_app/components/floatingActionButton_widget.dart';
import 'package:poss_mobile_app/components/scaffoldTab_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/orderData.dart';
import 'package:poss_mobile_app/pages/sales/new_order.dart';
import 'package:poss_mobile_app/time_diference.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

class Orders extends StatefulWidget {
  final Map shop;
  const Orders({super.key, required this.shop});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  // 🔵 Blue palette
  static const Color _blue900 = Color(0xFF0D2B6E);
  static const Color _blue700 = Color(0xFF1A56DB);
  static const Color _blue500 = Color(0xFF3B82F6);
  static const Color _blue200 = Color(0xFFBFDBFE);
  static const Color _blue50 = Color(0xFFEFF6FF);

  static const Color _green = Color(0xFF00B87C);
  static const Color _greenBg = Color(0xFFE6FAF4);

  // SEARCH
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  Timer? _debounce;
  bool isSearching = false;
  List filteredOrders = [];
  List allOrders = [];

  bool _isPrinting = false;

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: ScaffoldTabWidget(
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
        ],
        title: Column(
          children: [
            TextWidget(text: "Sales", color: ColorsWidget().appBarColor),
            Text(
              widget.shop['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ColorsWidget().appBarColor,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButtonWidget(
          onBtnPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NewOrder(shop: widget.shop)),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
        ),
        body: TabBarView(
          children: [
            _buildOrdersList('daily', 0),
            _buildOrdersList('weekly', 1),
            _buildOrdersList('monthly', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(String period, int index) {
    final Future<List?> ordersFuture =
        OrderData.getOrders(widget.shop['id'].toString());

    return FutureBuilder(
      future: ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _blue700));
        }

        if (!OrderData.orders.containsKey(widget.shop['id'].toString())) {
          return _buildEmptyState("No sales data available");
        }

        final List ordersData = OrderData.orders[widget.shop['id'].toString()]!;
        final List? periodOrders = ordersData[index][period];

        if (periodOrders == null || periodOrders.isEmpty) {
          return _buildEmptyState("No $period sales yet");
        }

        allOrders = List.from(periodOrders);

        final double totalSales = periodOrders.fold(0.0, (sum, order) {
          return sum + (double.tryParse(order['total_grand'].toString()) ?? 0);
        });

        final List displayList = isSearching ? filteredOrders : periodOrders;

        return Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 8),
            if (!isSearching)
              _buildSummaryStrip(periodOrders.length, totalSales),
            Expanded(
              child: displayList.isEmpty
                  ? _buildEmptyState(
                      isSearching ? "No results found" : "No $period sales yet")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: displayList.length,
                      itemBuilder: (context, i) =>
                          _buildOrderItem(displayList[i], i),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: _blue500.withValues(alpha: 0.09),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce =
              Timer(const Duration(milliseconds: 300), () => _onSearch(value));
        },
        decoration: InputDecoration(
          hintText: "Search by customer, seller, amount or date...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
          prefixIcon: const Icon(Icons.search, color: _blue500),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey[400], size: 18),
                  onPressed: () {
                    searchController.clear();
                    _onSearch('');
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

  void _onSearch(String query) {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        filteredOrders = [];
      });
      _restoreFocus();
      return;
    }

    final results = allOrders.where((order) {
      final String customer = (order['customer_names'] ?? '').toLowerCase();
      final Map seller = order['added_by'] ?? {};
      final String sellerName =
          "${seller['first_name'] ?? ''} ${seller['last_name'] ?? ''}"
              .toLowerCase();
      final String amount = order['total_grand'].toString().toLowerCase();
      final String date =
          TimeDifference.getDate(order['created_at']).toLowerCase();

      return customer.contains(query) ||
          sellerName.contains(query) ||
          amount.contains(query) ||
          date.contains(query);
    }).toList();

    setState(() {
      isSearching = true;
      filteredOrders = results;
    });
    _restoreFocus();
  }

  void _restoreFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchFocusNode.canRequestFocus) {
        searchFocusNode.requestFocus();
      }
    });
  }

  Widget _buildSummaryStrip(int count, double totalAmount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _summaryChip("$count Orders", _blue50, _blue700),
          const SizedBox(width: 8),
          _summaryChip(
              "${totalAmount.toStringAsFixed(0)} TZS", _greenBg, _green),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 62, color: _blue200),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: _blue200, fontWeight: FontWeight.w500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map order, int index) {
    final String customerName = order['customer_names'] ?? "Walk-in Customer";
    final String totalGrand = order['total_grand'].toString();
    final String discount = order['discount'].toString();
    final String time = TimeDifference.getDate(order['created_at'].toString());

    final Map seller = order['added_by'] ?? {};
    final String sellerName =
        "${seller['first_name'] ?? ''} ${seller['last_name'] ?? ''}".trim();

    final List<Color> bgColors = [
      _blue50,
      const Color(0xFFEEF2FF),
      const Color(0xFFE0F2FE),
    ];
    final List<Color> fgColors = [
      _blue700,
      const Color(0xFF4F46E5),
      _blue500,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColors[index % bgColors.length],
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: fgColors[index % fgColors.length], size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _amountBadge("TZS $totalGrand", _greenBg, _green),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _infoRow(
                        Icons.person_outline_rounded, "Sold by $sellerName"),
                    _infoRow(Icons.access_time_rounded, time),
                    if (discount != "0" && discount != "0.0")
                      _infoRow(
                          Icons.discount_outlined, "Discount $discount TZS"),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showOrderDetailsDialog(order),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _blue50, borderRadius: BorderRadius.circular(20)),
                  child: const Text("More",
                      style: TextStyle(
                          color: _blue700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
       const Padding(
          padding:  EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, thickness: 0.7, color: _blue50),
        ),
      ],
    );
  }

  Widget _amountBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _blue200),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsDialog(Map order) {
    final String customerName = order['customer_names'] ?? "Unknown";
    final String customerPhone = order['customer_phone'] ?? "-";
    final String customerAddress = order['customer_address'] ?? "-";
    final String customerEmail = order['customer_email'] ?? "-";
    final String totalGrand = order['total_grand'].toString();
    final String discount = order['discount'].toString();
    final String time = TimeDifference.getDate(order['created_at'].toString());

    final Map seller = order['added_by'] ?? {};
    final String sellerName =
        "${seller['first_name'] ?? ''} ${seller['last_name'] ?? ''}".trim();

    final List<dynamic> sales = order['sales'] ?? [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: _blue50,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: _blue700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text("Order Receipt",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _dialogRow(Icons.person, "Customer", customerName),
              _dialogRow(Icons.phone, "Phone", customerPhone),
              _dialogRow(Icons.home, "Address", customerAddress),
              _dialogRow(Icons.email, "Email", customerEmail),
              _dialogRow(Icons.person_outline, "Sold By", sellerName),
              _dialogRow(Icons.access_time, "Date & Time", time),
              const SizedBox(height: 20),
              const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
              const Text("Products Sold",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: sales.isEmpty
                    ? const Text("No products found",
                        style: TextStyle(color: Colors.grey))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: sales.length,
                        itemBuilder: (context, i) {
                          final sale = sales[i];
                          final product = sale['product'] ?? {};
                          final String name =
                              product['name'] ?? "Unknown Product";
                          final int qty = sale['quantity'] ?? 1;
                          final double price = double.tryParse(
                                  product['price']?.toString() ?? '0') ??
                              0;
                          final double lineTotal = qty * price;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(name,
                                        style: const TextStyle(fontSize: 15))),
                                Text(
                                  "$qty × ${price.toStringAsFixed(0)} = ${lineTotal.toStringAsFixed(0)} TZS",
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Grand Total",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text("$totalGrand TZS",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _green)),
                  ],
                ),
              ),
              if (discount != "0" && discount != "0.0")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Discount",
                        style: TextStyle(fontSize: 15, color: Colors.grey)),
                    Text("-$discount TZS",
                        style: const TextStyle(
                            fontSize: 15, color: Colors.orange)),
                  ],
                ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: _blue200, width: 1.5),
                        foregroundColor: _blue700,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _gradientButton(
                      label: "Print",
                      gradientColors: [_blue700, _blue900],
                      icon: Icons.print_rounded,
                      isLoading: _isPrinting,
                      onTap: () => _printReceipt(order),
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

  Widget _dialogRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _blue500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── FULL-PAGE WATERMARK BUILDER ───────────────────────────────────────────
  //
  // A4 usable area after 40pt margins on each side:
  //   width  = 595.28 - 80 = 515.28 pt
  //   height = 841.89 - 80 = 761.89 pt
  //
  // Strategy: use pw.CustomPaint to draw text stamps at precise (x, y)
  // coordinates across the full page. Every odd row is offset by half a
  // column width to create a staggered pattern with zero blank strips.
  //
  pw.Widget _buildWatermark(String shopName) {
    // Usable area dimensions (points)
    const double W = 515.0;
    const double H = 762.0;

    // Stamp layout settings
    const double fontSize   = 8.0;   // small text size
    const double colStep    = 95.0;  // horizontal distance between stamp starts
    const double rowStep    = 20.0;  // vertical distance between rows
    const double stampOpacity = 0.07;

    final String label = shopName.toUpperCase();

    final int cols = (W / colStep).ceil() + 2;
    final int rows = (H / rowStep).ceil() + 2;

    final List<pw.Widget> stamps = [];

    for (int row = 0; row < rows; row++) {
      final double y = row * rowStep - rowStep;
      // Stagger odd rows by half a column so vertical gaps don't align
      final double xShift = (row % 2 == 0) ? 0.0 : colStep / 2.0;

      for (int col = 0; col < cols; col++) {
        final double x = col * colStep - colStep + xShift;

        stamps.add(
          pw.Positioned(
            left: x,
            top: y,
            child: pw.Opacity(
              opacity: stampOpacity,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        );
      }
    }

    return pw.SizedBox(
      width: W,
      height: H,
      child: pw.Stack(children: stamps),
    );
  }

  // ─── PRINT RECEIPT ─────────────────────────────────────────────────────────
  Future<void> _printReceipt(Map order) async {
    setState(() => _isPrinting = true);

    final List<dynamic> sales = order['sales'] ?? [];
    final String printDateTime =
        DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());
    final String shopName =
        widget.shop['name']?.toString() ?? "POS SHOP";

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => pw.Stack(
            children: [
              // ── Layer 1: full-page tiled watermark ──
              pw.Positioned(
                left: 0,
                top: 0,
                child: _buildWatermark(shopName),
              ),

              // ── Layer 2: receipt content ──
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      shopName,
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      "RECEIPT",
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800),
                    ),
                  ),
                  pw.Divider(height: 30),

                  _pdfRow("Customer",
                      order['customer_names'] ?? "Walk-in Customer"),
                  _pdfRow("Phone", order['customer_phone'] ?? "-"),
                  _pdfRow(
                    "Sold By",
                    "${(order['added_by']?['first_name'] ?? '')} "
                        "${(order['added_by']?['last_name'] ?? '')}",
                  ),
                  _pdfRow("Order Date",
                      TimeDifference.getDate(order['created_at'])),
                  _pdfRow("Printed On", printDateTime),

                  pw.SizedBox(height: 25),

                  // Products Table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(5),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text("Product",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text("Qty",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text("Price",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text("Total",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...sales.map((sale) {
                        final product = sale['product'] ?? {};
                        final String name = product['name'] ?? "Unknown";
                        final int qty = sale['quantity'] ?? 1;
                        final double price = double.tryParse(
                                product['price']?.toString() ?? '0') ??
                            0;
                        final double lineTotal = qty * price;

                        return pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(name)),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(qty.toString())),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                    "${price.toStringAsFixed(0)} TZS")),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                    "${lineTotal.toStringAsFixed(0)} TZS")),
                          ],
                        );
                      }),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Grand Total",
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        "${order['total_grand'] ?? '0'} TZS",
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green700),
                      ),
                    ],
                  ),

                  if ((order['discount']?.toString() ?? "0") != "0" &&
                      (order['discount']?.toString() ?? "0") != "0.0")
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Discount",
                            style: const pw.TextStyle(
                                fontSize: 15, color: PdfColors.grey700)),
                        pw.Text(
                          "-${order['discount']} TZS",
                          style: const pw.TextStyle(
                              fontSize: 15, color: PdfColors.orange),
                        ),
                      ],
                    ),

                  pw.Spacer(),
                  pw.Center(
                    child: pw.Text(
                      "Thank you for shopping with us!",
                      style: const pw.TextStyle(
                          fontSize: 14, color: PdfColors.grey700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Receipt_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      toast("Receipt generated successfully!");
    } catch (e) {
      toast("Failed to generate receipt");
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Text("$label: ",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  // Gradient Button
  Widget _gradientButton({
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    IconData? icon,
    bool isLoading = false,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8)
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15)),
                ],
              ),
      ),
    );
  }
}