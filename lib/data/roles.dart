import 'dart:convert';
import 'package:poss_mobile_app/services/api_service.dart';

class RolesData {
  // Static list to store roles in memory (Global State)
  static List rolesList = [];


  static Future<List> getRoles({bool refresh = false}) async {
    // Only fetch if the list is empty or a refresh is forced
    if (rolesList.isEmpty || refresh) {
      var link = "roles"; // Matches Route::get('roles') in api.php
      
      var response = await APIService.api("GET", link, {});

      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        
        if (body['success'] == true && body['data'] != null) {
          // Update the static list
          rolesList = body['data'];
          return rolesList;
        }
      }
    }

    return rolesList;
  }

 
  static void clear() {
    rolesList = [];
  }
}
