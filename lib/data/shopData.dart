import 'dart:convert';

import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/models/shop.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/shop_ops.dart';

class ShopsData {
  static List shops = [];

  static Future<List> getShops() async {
    List localShops;
    if (shops.isEmpty) {
      var link = "shops";
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        shops = body['data'];
        localShops = await ShopOps.getShops();
        if (localShops.isEmpty) {
          for (var shop in shops) {
            await ProductsData.getProducts(shop['id'].toString());
            ShopOps.create(Shop(
                id: shop['id'].toString(),
                name: shop['name'],
                address: shop['address'],
                ownerId: shop['owner_id'].toString()));
          }
        } else {
          for (var shop in shops) {
            ShopOps.update(Shop(
                id: shop['id'].toString(),
                name: shop['name'],
                address: shop['address'],
                ownerId: shop['owner_id'].toString()));
          }
        }
      }
      if (response['httpCode'] == 300) {
        await ShopOps.getShops().then((value) {
          shops = value.toList();
        });
        for (Map shop in shops) {
          await UserData.getUser(shop['owner_id'].toString());
        }
      }
    }
    return shops;
  }
}
