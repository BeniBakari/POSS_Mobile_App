import 'dart:convert';
import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/purchase_ops.dart';

class OrderData {
  static Map<String, List> orders = {};
  static Future<List?> getOrders(String shopId) async {
    if (!orders.containsKey(shopId)) {
      var link = "shops/$shopId/sales";
      await ProductsData.getProducts(shopId);
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        if (body['data'].toString() != "null") {
          Map data = body['data'];

          List liveSales = [];
          Map daily = {};
          Map weekly = {};
          Map monthly = {};
          if (data['daily'] != null) {
            daily.putIfAbsent("daily", () => data['daily']);
          }
          if (data['weekly'] != null) {
            weekly.putIfAbsent("weekly", () => data['weekly']);
          }

          if (data['monthly'] != null) {
            monthly.putIfAbsent("monthly", () => data['monthly']);
          }
          liveSales.add(daily);
          liveSales.add(weekly);
          liveSales.add(monthly);


          // List sals = body['data']['weekly'];
          // if (data['monthly'] == null) {
          //   liveSales.add({"monthly", null});
          // } else {
          //   for (Map sale in data['monthly']) {
          //     liveSales.add(sale);
          //   }
          // }
          if (liveSales.isNotEmpty) {
            // for (Map pur in sals) {
            //   liveSales.add(pur);
            //   //PurchaseOps.create(pur);
            // }
            orders.putIfAbsent(shopId, () => liveSales);
          }
          return orders[shopId];
        }
        return [];
      } else if (response['httpCode'] == 300) {
        PurchaseOps.getShopPurchase(shopId).then((localPurchases) {
          if (localPurchases.isNotEmpty) {
            orders.putIfAbsent(shopId, () => localPurchases);
          }
        });
      }
    } else {
      if (!orders.containsKey(shopId)) {
        return [];
      }
      return orders[shopId];
    }
    return null;
  }
}
