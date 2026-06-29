import 'dart:convert';
import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/models/user.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqlite_api.dart';

class UserOps {
  static Future<int> create(Map user) async {
    UserData.addUser(user);
    final Database db = await SqliteService.initializeDB();

    Map localUser = await getUser(user['id'].toString());

    if (localUser.isEmpty) {
      User us = User(
        id: user['id'],
        firstName: user['first_name'] ?? '',
        lastName: user['last_name'] ?? '',
        email: user['email'] ?? '',
        address: user['address'],
        phone: user['phone'],
        gender: user['gender'],
        imagePath: user['imagePath'],
        dob: user['dob'],
        roleNames: List<String>.from(user['role_names'] ?? []),
        permissions: List<String>.from(user['all_permissions'] ?? []),
      );

      return await db.insert(
        'users',
        {
          ...us.toMap(),
          'roleNames': jsonEncode(us.roleNames),
          'permissions': jsonEncode(us.permissions),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return 0;
  }

  static Future<Map<String, dynamic>> getUser(String id) async {
    final Database db = await SqliteService.initializeDB();
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return {};

    Map<String, dynamic> userMap = Map.from(result[0]);
    userMap['roleNames'] = jsonDecode(userMap['roleNames'] ?? '[]');
    userMap['permissions'] = jsonDecode(userMap['permissions'] ?? '[]');

    return userMap;
  }

  static Future<int> update(User user) async {
    final Database db = await SqliteService.initializeDB();
    return await db.update(
      'users',
      {
        ...user.toMap(),
        'roleNames': jsonEncode(user.roleNames),
        'permissions': jsonEncode(user.permissions),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final Database db = await SqliteService.initializeDB();
    final List<Map<String, dynamic>> result = await db.query('users');
    final List<Map<String, dynamic>> users = [];

    for (var row in result) {
      Map<String, dynamic> userMap = Map.from(row);
      userMap['roleNames'] = jsonDecode(userMap['roleNames'] ?? '[]');
      userMap['permissions'] = jsonDecode(userMap['permissions'] ?? '[]');
      UserData.addUser(userMap);
      users.add(userMap);
    }
    return users;
  }

  static Future<void> delete({String? id}) async {
    final Database db = await SqliteService.initializeDB();
    if (id != null) {
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.delete('users');
    }
  }
}