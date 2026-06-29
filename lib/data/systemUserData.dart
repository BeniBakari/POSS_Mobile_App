import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

class SystemUserData {
  static Future<List> getSystemUser() async {
    final Database db = await SqliteService.initializeDB();
    return db.rawQuery('''
                SELECT *FROM systemUser
            ''');
  }
  static Future<void> update(String type, String role) async {
    final Database db = await SqliteService.initializeDB();
     db.rawUpdate('''
                UPDATE  systemUser SET $type = $role WHERE id == 1
            ''');
  }
}
