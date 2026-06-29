// ignore_for_file: file_names

import 'dart:convert';

import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/profile_operations.dart';

class ProfileData {
  static Map profile = {};
  static Future<Map> getProfile() async {
    await ProfileOps.getProfile();
    if (profile.isEmpty) {
      var link = "users/profile";
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = jsonDecode(response['body']);
        UserData.addUser(body['data']);
        ProfileOps.update(body['data']);

        profile = body['data'];
      }
      // await ProfileOps.getProfile().then((value) {
      //   profile = {
      //     "first_name": value.firstname,
      //     "last_name": value.lastname,
      //     "email": value.email,
      //     "phone": value.phone,
      //     "address": value.address,
      //     "role_id": value.roleId,
      //     "token": value.token
      //   };
      // });
      if (response['httpCode'] == 300) {
        ProfileOps.getProfile().then((value) {
          profile = value as Map;
        });
      }
    }

    return profile;
  }
}
