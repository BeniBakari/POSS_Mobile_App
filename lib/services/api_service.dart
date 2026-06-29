import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class APIService {
  //static String baseUrl = "http://10.0.2.6:8000/api/";
  static String baseUrl = "http://192.168.230.198:8000/api/";

  static Map<String, String> headers = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer "
  };

  static Future<Map> api(String httpMethod, String link, Map data) async {
    headers['Authorization'] = "Bearer ${await getToken()}";
    headers['Content-type'] = "application/json";

    var url = Uri.parse(baseUrl + link);
    http.Response response;
    try {
      if (httpMethod == "POST") {
        response =
        await http.post(url, headers: headers, body: json.encode(data));
      } else if (httpMethod == "PUT") {
        response =
        await http.put(url, headers: headers, body: json.encode(data));
      } else if (httpMethod == "PATCH") {
        response =
        await http.patch(url, headers: headers, body: json.encode(data));
      } else if (httpMethod == "DELETE") {
        response =
        await http.delete(url, headers: headers, body: json.encode(data));
      }
      else {
        response = await http.get(url, headers: headers);
      }
      if (response.statusCode == 401) {}
      return {"httpCode": response.statusCode, "body": response.body};
    } catch (e) {
      if (e.toString() == "Connection refused") {
        //toast("Your network is not stable.");
        return {"httpCode": 300, "body": Null};
      }
    }
    return {};
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      String token = prefs.get("poss_token").toString();
      return token;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("poss_token", token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("poss_token");
  }
}
