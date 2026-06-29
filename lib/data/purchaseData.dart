import 'dart:convert';
import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/purchase_ops.dart';

class PurchaseData {
  static Map<String, List> purchases = {};
  static Future<List?> getPurchases(String shopId) async {
    if (!purchases.containsKey(shopId)) {
      var link = "shops/$shopId/purchases";
      await ProductsData.getProducts(shopId);
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        if (body['data'].toString() != "null") {
          List purch = body['data'];
          List livePurchase = [];
          if (purch.isNotEmpty) {
            for (Map pur in purch) {
              livePurchase.add(pur);
              PurchaseOps.create(pur);
            }
            purchases.putIfAbsent(shopId, () => purch);
          }
          return purchases[shopId];
        }
        return [];
      } else if (response['httpCode'] == 300) {
        PurchaseOps.getShopPurchase(shopId).then((localPurchases) {
          if (localPurchases.isNotEmpty) {
            purchases.putIfAbsent(shopId, () => localPurchases);
          }
        });
      }
    } else {
      if (!purchases.containsKey(shopId)) {
        return [];
      }
      return purchases[shopId];
    }
    return null;
  }
}
