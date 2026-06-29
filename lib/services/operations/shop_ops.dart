import 'package:poss_mobile_app/models/shop.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

class ShopOps {
  static Future<int> create(Shop shop) async {
    final Database db = await SqliteService.initializeDB();
    return await db.insert('shops', shop.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List> getShops() async {
    final Database db = await SqliteService.initializeDB();
    final List<Map<String, Object?>> result = await db.query('shops');
    List shops = [];
    //print(result);
    if (result.isNotEmpty) {
      for (int i = 0; i < result.length; i++) {
        shops.add(
          result[i]
          // Shop(
          //   id: result[i]['id'].toString(),
          //   name: result[i]['name'].toString(),
          //   address: result[i]['address'].toString(),
          //   ownerId: result[i]['owner_id'].toString(),
          //   //managerId: result[i]['managerId'].toString()
          // )
        );
      }
    }
    return shops;
  }

  static Future<int> update(Shop shop) async {
    final Database db = await SqliteService.initializeDB();
    return await db.rawUpdate('''
            UPDATE shops SET
            name = ?,
            owner_id = ?,
            address = ?

            WHERE id = ?
          ''', [shop.name, shop.ownerId, shop.address, shop.id]);
  }

  static void delete() async {
    final Database db = await SqliteService.initializeDB();
    db.delete('shops');
  }
}
