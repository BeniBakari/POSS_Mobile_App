import 'package:sqflite/sqflite.dart';

import '../sqlite_service.dart';

class SystemUserOps{
    static Future<Map> getSystemUserFetched(String userRole) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM systemUser 
            WHERE '''"$userRole"''' = ?
          ''', ["1"]);
    if (result.isEmpty) {
      return {};
    } else {
      return result[0];
    }
  }
    static void delete() async {
    final Database db = await SqliteService.initializeDB();
    db.delete('systemUser');
  }
}