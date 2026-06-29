import 'dart:convert';

import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';

class UserData {
  static Map users = {};

  static Future<Map> getUser(String id) async {
    if (users.containsKey(id)) {
      return users[id.toString()];
    }
    Map user = await UserOps.getUser(id);
    if (user.isEmpty) {
      var link = "users/view/$id";
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        if (body['data'].toString() != "null") {
          Map us = body['data'];
          UserOps.create(us);
          return us;
        }
      }
    }
    if (user.isNotEmpty) {
      users.putIfAbsent(user['id'], () => user);
    }
    return user;
  }

  static void addUser(Map user) {
    if (!users.containsKey(user['id'].toString())) {
      users.putIfAbsent(user['id'].toString(), () => user);
    }
  }

  static Future<List?> getWorkers(String type) async {
    var response = await APIService.api("GET", "users/$type", {});
    if (response['httpCode'] == 200) {
      Map body = json.decode(response['body']);
      if (body['data'].toString() != "null") {
        List workers = body['data'];
        for (Map worker in workers) {
          UserOps.create(worker);
        }
        return workers;
      }
    }
    return [];
  }
}
