import 'package:poss_mobile_app/models/product.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

class ProductOps {
  static Future<int> create(Product product) async {
    final Database db = await SqliteService.initializeDB();
    
    return await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

    static void delete() async {
    final Database db = await SqliteService.initializeDB();
    db.delete('products');
  }

  static Future<List> getShopProducts(String shopId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM products 
            WHERE shop_id = ? 
          ''', [shopId]);
    if (result.isEmpty) {
      return [];
    } else {
      return result;
    }
  }

  static Future<Map> getProduct(String productId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM products 
            WHERE id = ?
          ''', [productId]);
    if (result.isEmpty) {
      return {};
    } else {
      return result[0];
    }
  }
}
