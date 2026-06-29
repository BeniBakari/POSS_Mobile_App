import 'dart:convert';

import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/employee_ops.dart';
import 'package:poss_mobile_app/services/operations/register_ops.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';

class RegistersData {
  static Map<String, List> registers = {};
  static Future<List?> getRegisters(String shopId) async {
    if (!registers.containsKey(shopId)) {
      EmployeeOps.getShopEmployees(shopId);
      var link = "shops/$shopId/registers";
      var response = await APIService.api("GET", link, {});
      if (response['httpCode'] == 200) {
        Map body = json.decode(response['body']);
        if (body['data'].toString() != "null") {
          List rgs = body['data'];
          List liveRgs = [];
          if (rgs.isNotEmpty) {
            for (Map rg in rgs) {
              UserOps.create(rg['opener']);
              if (rg['closed_by'].toString() != "null") {
                UserOps.create(rg['closer']);
              }
              RegisterOps.create(rg);
              liveRgs.add(rg);
            }

            registers.putIfAbsent(shopId, () => liveRgs);
            return registers[shopId];
          }
          return [];
        }
        return [];
      } else if (response['httpCode'] == 300) {
        await RegisterOps.getShopRegisters(shopId).then((localRegisters) {
          if (localRegisters.isNotEmpty) {
            registers.putIfAbsent(shopId, () => localRegisters);
          }
        });
        toast("offline");
      }
      return [];
    } else {
      return registers[shopId];
    }
  }
}
