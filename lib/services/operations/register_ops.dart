import 'package:poss_mobile_app/models/registers.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqlite_api.dart';

class RegisterOps {
  static Future<int> create(Map register) async {
    final Database db = await SqliteService.initializeDB();
    Map localRegister = await getRegister(register['id'].toString());
    if (localRegister.isEmpty) {
      Map openedBy = register['opener'];
      String closedById = "null";
      UserOps.create(openedBy);
      if (register['closed_by'].toString() != "null") {
        Map closedBy = register['closer'];
        UserOps.create(closedBy);
        closedById = closedBy['id'].toString();
      }
      Register reg = Register(
          id: register['id'].toString(),
          openingCash: register['opening_cash'].toString(),
          closingCash: register['closing_cash'].toString(),
          openedBy: openedBy['id'].toString(),
          closedBy: closedById,
          shopId: register['shop_id'].toString(),
          updatedAt: register['updated_at'].toString(),
          createdAt: register['created_at'].toString());
      return await db.insert('registers', reg.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return 0;
  }

  static Future<Map> getRegister(String registerId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM registers 
            WHERE id = ?
          ''', [registerId]);
    if (result.isEmpty) {
      return {};
    } else {
      return result[0];
    }
  }

  static Future<List> getShopRegisters(String shopId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM registers 
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
    db.delete('registers');
  }
}
