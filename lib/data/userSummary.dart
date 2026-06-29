import 'dart:convert';

import 'package:poss_mobile_app/services/api_service.dart';

class UsersSummary {
  static Map usersSummary = {};

  static Future<Map> getSummary() async {
    if (usersSummary.isEmpty) {
      var link = "users/summary";
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        if (body['data'].toString() != "null") {
          Map summary = body['data'];
          usersSummary = summary;
          return summary;
        }
      }
    }

    return usersSummary;
  }
}
