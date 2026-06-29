import 'dart:convert';

import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/employee_ops.dart';

class UnEmployeeData {
  static Map<String, List> unemployees = {};
  static Future<List?> getEmployees(String shopId) async {
    if (!unemployees.containsKey(shopId)) {
      var link = "shops/$shopId/unemployees";
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        if (body['data'].toString() != "null") {
          List emps = body['data'];
          List liveEmps = [];
          if (emps.isNotEmpty) {
            for (Map emp in emps) {
              liveEmps.add(emp);
              // await EmployeeOps.create(emp);
            }

            unemployees.putIfAbsent(shopId, () => liveEmps);
            return unemployees[shopId];
          }
          return [];
        }
        return [];
      } else if (response['httpCode'] == 300) {
        toast("offline");
      }
      return [];
    } else {
      return unemployees[shopId];
    }
  }

  static Future<void> findUnEmployee(String employeeId) async {
    EmployeeOps.getEmployee(employeeId).then((localEmployee) async {
      if (localEmployee.isNotEmpty) {
        print(localEmployee);
      } else {
        var response =
            await APIService.api("GET", "shops/employee/$employeeId", {});
        print(response);
      }
    });
  }
}
