import 'package:poss_mobile_app/data/data.dart';
import 'package:poss_mobile_app/models/profile.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

class ProfileOps {
  static Future<int> create(Profile profile) async {
    final Database db = await SqliteService.initializeDB();
    return await db.insert('profile', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Profile> getProfile() async {
    final Database db = await SqliteService.initializeDB();
    final List<Map<String, Object?>> result = await db.query('profile');
    if (result.isNotEmpty) {
      Data.hasLoggedIn = true;
      return Profile(
          id: result[0]['id'].toString(),
          firstname: result[0]['firstname'].toString(),
          lastname: result[0]['lastname'].toString(),
          email: result[0]['email'].toString(),
          roleId: result[0]['roleId'].toString(),
          token: result[0]['token'].toString());
    }
    
    return Profile(
        firstname: '', lastname: '', email: '', roleId: '', token: '', id: '');
  }

  static void delete() async {
    final Database db = await SqliteService.initializeDB();
    db.delete('profile');
  }

  static Future<int> update(Map user) async {
    final Database db = await SqliteService.initializeDB();
    return await db.rawUpdate('''
                UPDATE profile SET
                firstname = ?,
                lastname = ?,
                email = ?,
                phone = ?,
                gender = ?,
                imagePath = ?,
                roleId = ?,
                address = ?,
                dob = ?
                WHERE id = ?
              ''', [
      user['first_name'],
      user['last_name'],
      user['email'],
      user['phone'],
      user['gender'],
      user['imagePath'],
      user['role_id'],
      user['address'],
      user['dob'],
      user['id']
    ]);
  }
}
