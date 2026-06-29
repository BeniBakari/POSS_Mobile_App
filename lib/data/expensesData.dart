import 'dart:convert';

import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/employee_ops.dart';
import 'package:poss_mobile_app/services/operations/expense_ops.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';

class ExpensesData {
  static Map<String, List> expenses = {};
  static Future<List?> getExpenses(String shopId) async {
    if (!expenses.containsKey(shopId)) {
      EmployeeOps.getShopEmployees(shopId);
      var link = "shops/$shopId/expenses";
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        if (body['data'].toString() != "null") {
          List exps = body['data'];
          List liveExps = [];
          if (exps.isNotEmpty) {
            for (Map exp in exps) {
              UserOps.create(exp['adder']);
              UserData.addUser(exp['adder']);
              ExpenseOps.create(exp);
              //EmployeeData.findEmployee(exp['added_by']['id'].toString());
              liveExps.add(exp);
            }

            expenses.putIfAbsent(shopId, () => liveExps);
            return expenses[shopId];
          }
          return [];
        }
        return [];
      } else if (response['httpCode'] == 300) {
        await ExpenseOps.getShopExpenses(shopId).then((localExpenses) {
          if (localExpenses.isNotEmpty) {
            expenses.putIfAbsent(shopId, () => localExpenses);
          }
        });
        toast("offline");
      }
      return [];
    } else {
      return expenses[shopId];
    }
  }
}
