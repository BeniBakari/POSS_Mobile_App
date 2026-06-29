import 'dart:convert';

import 'package:poss_mobile_app/models/product.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/product_ops.dart';

class ProductsData {
  static Map products = {};

  static Future<List> getProducts(String shopId) async {
    if (products.containsKey(shopId)) {
      return products[shopId] as List;
    }

    final String link = "shops/$shopId/products";
    final Map response = await APIService.api("GET", link, {});
    if (response['httpCode'] == 200) {
      final Map body = json.decode(response['body']);

      if (body['data'] == null) return [];

      final List prdts = body['data'] as List;
      if (prdts.isEmpty) return [];

      // Local list per call — avoids cross-shop data contamination
      final List<Map> shopProducts = [];

      for (final dynamic item in prdts) {
        final Map pr = item as Map;
        shopProducts.add(pr);
        ProductOps.getProduct(pr['id'].toString()).then((existing) {
          if (existing.isEmpty) {
            ProductOps.create(Product(
              id: pr['id'].toString(),
              name: pr['name'].toString(),
              description: pr['description'].toString(),
              unit: pr['unit'].toString(),
              unitValue: pr['unit_value'].toString(),
              quantity: pr['quantity'].toString(),
              barcode: pr['barcode'].toString(),
              price: pr['price'].toString(),
              shopId: pr['shop_id'].toString(),
              addedBy: pr['added_by'] is Map
                  ? pr['added_by']['id'].toString()
                  : pr['added_by'].toString(),
              isActive: pr['is_active'].toString(),
            ));
          }
        });
      }

      products[shopId] = shopProducts;
      return shopProducts;
    }

    if (response['httpCode'] == 300) {
      final List offline = await ProductOps.getShopProducts(shopId)
          .timeout(const Duration(seconds: 5));
      products[shopId] = offline;
      return offline;
    }

    return [];
  }

  /// Safely adds a product to the in-memory cache.
  /// Creates the shop list if it doesn't exist yet.
  static void addProduct(String shopId, Map product) {
    if (products.containsKey(shopId)) {
      (products[shopId] as List).add(product);
    } else {
      products[shopId] = [product];
    }
  }

  static Future<Map> getProduct(String shopId, String productId) async {
    if (products.containsKey(shopId)) {
      final List prs = products[shopId] as List;
      for (int i = 0; i < prs.length; i++) {
        if (prs[i]['id'].toString() == productId) {
          return prs[i] as Map;
        }
      }
    }
    // Not in cache — fetch then search again
    await getProducts(shopId);
    if (products.containsKey(shopId)) {
      final List prs = products[shopId] as List;
      for (int i = 0; i < prs.length; i++) {
        if (prs[i]['id'].toString() == productId) {
          return prs[i] as Map;
        }
      }
    }
    return {};
  }
}
