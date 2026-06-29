import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/models/employee.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqlite_api.dart';

class EmployeeOps {
  static Future<int> create(Map employee) async {
    final Database db = await SqliteService.initializeDB();
    Map localEmployee = await getEmployee(employee['id'].toString());
    if (localEmployee.isEmpty) {
      UserOps.create(employee);
      Employee emp = Employee(
          id: employee['id'].toString(),
          userId: employee['user_id'].toString(),
          shopId: employee['shop_id'].toString(),
          addedBy: employee['added_by'].toString());
      return await db.insert('employees', emp.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return 0;
  }

  static Future<Map> getEmployee(String employeeId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM employees 
            WHERE id = ?
          ''', [employeeId]);
    if (result.isEmpty) {
      return {};
    } else {
      return result[0];
    }
  }

  static void delete() async {
    final Database db = await SqliteService.initializeDB();
    db.delete('employees');
  }

  static Future<List> getShopEmployees(String shopId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM employees 
            WHERE shop_id = ?
          ''', [shopId]);
    if (result.isNotEmpty) {
      List employees = [];
      UserData.getUser(result[0]['user_id'].toString()).then((user) {
        if (user.isNotEmpty) {
          employees.add(user);
        }
        return employees;
      });
    }
    return [];
  }
}
