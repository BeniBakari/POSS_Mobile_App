// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/scaffoldTab_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/transitions/slide_transition.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/data/employeeData.dart';

import 'package:poss_mobile_app/pages/employees/employees.dart';
import 'package:poss_mobile_app/pages/expenses/expenses.dart';
import 'package:poss_mobile_app/pages/products/products.dart';
import 'package:poss_mobile_app/pages/purchases/purchases.dart';
import 'package:poss_mobile_app/pages/registers/registers.dart';
import 'package:poss_mobile_app/pages/sales/orders.dart';

class Shop extends StatefulWidget {
  final Map shop;
  const Shop(this.shop, {super.key});

  @override
  State<Shop> createState() => _ShopState(shop);
}

class _ShopState extends State<Shop> {
  final Map shop;
  _ShopState(this.shop);

  late Future<Map> summaryResponse;

  @override
  void initState() {
    super.initState();
    summaryResponse =
        APIService.api("GET", "summary/" + shop['id'].toString(), {});
  }

  // One color + icon per metric, used only for the icon bubble accent
  static const List<_MetricStyle> _styles = [
    _MetricStyle(Color(0xFF6C63FF), Icons.shopping_cart_rounded),
    _MetricStyle(Color(0xFF00B87C), Icons.point_of_sale_rounded),
    _MetricStyle(Color(0xFFFF6B6B), Icons.receipt_long_rounded),
    _MetricStyle(Color(0xFF0EA5E9), Icons.trending_up_rounded),
    _MetricStyle(Color(0xFFF59E0B), Icons.account_balance_wallet_rounded),
    _MetricStyle(Color(0xFF10B981), Icons.star_rounded),
    _MetricStyle(Color(0xFFEC4899), Icons.arrow_circle_down_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final appBarColor = ColorsWidget().appBarColor;

    return ScaffoldTabWidget(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextWidget(text: "Summary", color: appBarColor, fontsize: 13),
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
      actions: [
        PopupMenuButton(
          icon: Icon(Icons.more_vert_rounded, color: appBarColor),
          color: ColorsWidget().popMenuBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            _menuItem(0, "Sales",     Icons.point_of_sale_rounded),
            _menuItem(1, "Expenses",  Icons.receipt_long_rounded),
            _menuItem(2, "Registers", Icons.app_registration_rounded),
            _menuItem(3, "Employees", Icons.people_alt_rounded),
            _menuItem(4, "Purchases", Icons.shopping_cart_rounded),
            _menuItem(5, "Products",  Icons.inventory_2_rounded),
          ],
          onSelected: (item) async {
            if (item == 0) Navigator.push(context, SlideRightRoute(page: Orders(shop: shop)));
            if (item == 1) Navigator.push(context, SlideRightRoute(page: Expenses(shop: shop)));
            if (item == 2) Navigator.push(context, SlideRightRoute(page: Registers(shop: shop)));
            if (item == 3) {
              EmployeeData.getEmployees(shop['id'].toString());
              Navigator.push(context, SlideRightRoute(page: Employees(shop: shop)));
            }
            if (item == 4) Navigator.push(context, SlideRightRoute(page: Purchases(shop: shop)));
            if (item == 5) Navigator.push(context, SlideRightRoute(page: Products(shop)));
          },
        )
      ],
      tabs: const [
        Tab(text: 'Today'),
        Tab(text: 'Weekly'),
        Tab(text: 'Monthly'),
      ],
      body: FutureBuilder(
        future: summaryResponse,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorsWidget().appBarColor,
                strokeWidth: 2.5,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildStateMessage(
              icon: Icons.wifi_off_rounded,
              message: "Connection error",
              sub: snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == null) {
              return _buildStateMessage(
                icon: Icons.cloud_off_rounded,
                message: "No response from server",
              );
            }

            Map? decoded;
            try {
              decoded = json.decode(snapshot.data!['body']);
            } catch (_) {
              return _buildStateMessage(
                icon: Icons.error_outline_rounded,
                message: "Failed to parse response",
              );
            }

            final Map? data = decoded?['data'] as Map?;
            if (data == null) {
              return _buildStateMessage(
                icon: Icons.inbox_rounded,
                message: "Summary data unavailable",
              );
            }

            return TabBarView(
              children: [
                buildSummary((data['daily']   as Map?) ?? {}),
                buildSummary((data['weekly']  as Map?) ?? {}),
                buildSummary((data['monthly'] as Map?) ?? {}),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  PopupMenuItem<int> _menuItem(int value, String label, IconData icon) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          TextWidget(text: label, color: Colors.white, fontsize: 14),
        ],
      ),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String message,
    String? sub,
  }) {
    final appBarColor = ColorsWidget().appBarColor;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: appBarColor.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: appBarColor.withValues(alpha: 0.7),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                sub,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget buildSummary(Map data) {
    final Map mostSoldProduct = (data['mostSoldProduct'] as Map?) ?? {};

    final String purchases   = (data['purchases_cost'] ?? 0).toString();
    final String expenses    = (data['expenses']       ?? 0).toString();
    final String totalSales  = (data['sales_cost']     ?? 0).toString();
    final String grossProfit = (data['grossProfit']    ?? 0).toString();
    final String netProfit   = (data['netProfit']      ?? 0).toString();

    final String mostProduct      = (mostSoldProduct['product'] as Map?)?['name'] ?? "No sales yet";
    final String mostCountProduct = (mostSoldProduct['count']   ?? 0).toString();

    // TODO: Replace with real "less sold" data from API when available
    const String lessProduct      = "Tambi (Santa Lucia)";
    const String lessCountProduct = "1";

    final List<_MetricItem> metrics = [
      _MetricItem("Purchases",    purchases,    "Total cost"),
      _MetricItem("Total Sales",  totalSales,   "Revenue"),
      _MetricItem("Expenses",     expenses,     "Operational"),
      _MetricItem("Gross Profit", grossProfit,  "Before expenses"),
      _MetricItem("Net Profit",   netProfit,    "After expenses"),
      _MetricItem("Most Sold",    mostProduct,  "×$mostCountProduct units"),
      const _MetricItem("Less Sold",    lessProduct,  "×$lessCountProduct units"),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: metrics.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.8,
        color: Colors.grey.withValues(alpha: 0.15),
        indent: 62,
      ),
      itemBuilder: (context, i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + i * 70),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: _buildMetricRow(metrics[i], _styles[i]),
        );
      },
    );
  }

  Widget _buildMetricRow(_MetricItem item, _MetricStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          // Colored icon bubble — no card, just a small rounded container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.color, size: 20),
          ),

          const SizedBox(width: 14),

          // Label + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Value — colored to match the row accent
          Text(
            item.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: style.color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting data classes ──────────────────────────────────────────────────

class _MetricStyle {
  final Color color;
  final IconData icon;
  const _MetricStyle(this.color, this.icon);
}

class _MetricItem {
  final String label;
  final String value;
  final String sub;
  const _MetricItem(this.label, this.value, this.sub);
}