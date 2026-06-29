import 'package:poss_mobile_app/models/purchase.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

class PurchaseOps {
  static Future<int> create(Map purchase) async {
    final Database db = await SqliteService.initializeDB();
    Map localPurchase = await getPurchase(purchase['id'].toString());
    if (localPurchase.isEmpty) {
      Map addedBy = purchase['added_by'];
      UserOps.create(addedBy);
      Purchase purchas = Purchase(
          id: purchase['id'].toString(),
          shopId: purchase['shop_id'].toString(),
          quantity: purchase['quantity'].toString(),
          description: purchase['description'].toString(),
          productId: purchase['product_id'].toString(),
          cost: purchase['cost'].toString(),
          addedBy: addedBy['id'].toString());
      return await db.insert('purchases', purchas.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return 0;
  }

  static Future<Map> getPurchase(String id) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM purchases 
            WHERE id = ?
          ''', [id]);
    if (result.isEmpty) {
      return {};
    } else {
      return result[0];
    }
  }

    static Future<List> getShopPurchase(String shopId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM purchases 
            WHERE shop_id = ?
          ''', [shopId]);
    if (result.isEmpty) {
      return [];
    } else {
      return result;
    }
  }

    static void delete() async {
    final Database db = await SqliteService.initializeDB();
    db.delete('purchases');
  }
}
