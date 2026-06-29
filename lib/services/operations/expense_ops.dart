import 'package:poss_mobile_app/models/expense.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';
import 'package:sqflite/sqlite_api.dart';

class ExpenseOps {
  static Future<int> create(Map expense) async {
    final Database db = await SqliteService.initializeDB();
    Map localRegister = await getExpense(expense['id'].toString());
    if (localRegister.isEmpty) {
      Map adder = expense['adder'];
      UserOps.create(adder);
      Expense exp = Expense(
          id: expense['id'].toString(),
          description:expense['description'],
          shopId: expense['shop_id'].toString(),
          amount: expense['amount'].toString(),
          addedBy: expense['added_by'].toString(),
          updatedAt: expense['updated_at'].toString(),
          createdAt: expense['created_at'].toString());
      return await db.insert('expenses', exp.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return 0;
  }

  static Future<Map> getExpense(String exenseId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM expenses 
            WHERE id = ?
          ''', [exenseId]);
    if (result.isEmpty) {
      return {};
    } else {
      return result[0];
    }
  }

  static Future<List> getShopExpenses(String shopId) async {
    final Database db = await SqliteService.initializeDB();
    List result = await db.rawQuery('''
            SELECT *FROM expenses 
            WHERE shop_id = ?
          ''', [shopId]);
    if (result.isEmpty) {
      return [];
    } else {
      return result;
    }
  }

  static void delete() async {
    final Database db = await SqliteService.initializeDB();
    db.delete('expenses');
  }
}
