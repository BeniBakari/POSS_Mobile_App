import 'package:poss_mobile_app/data/employeeData.dart';
import 'package:poss_mobile_app/data/productData.dart';
import 'package:poss_mobile_app/data/profileData.dart';
import 'package:poss_mobile_app/data/purchaseData.dart';
import 'package:poss_mobile_app/data/registersData.dart';
import 'package:poss_mobile_app/data/shopData.dart';
import 'package:poss_mobile_app/data/userData.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/services/operations/employee_ops.dart';
import 'package:poss_mobile_app/services/operations/product_ops.dart';
import 'package:poss_mobile_app/services/operations/profile_operations.dart';
import 'package:poss_mobile_app/services/operations/purchase_ops.dart';
import 'package:poss_mobile_app/services/operations/register_ops.dart';
import 'package:poss_mobile_app/services/operations/shop_ops.dart';
import 'package:poss_mobile_app/services/operations/system_user_ops.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';

class Data {
  static String currentPage = "";
  static bool hasLoggedIn = false;

  static void setpageName(String pageName) {
    currentPage = pageName;
  }

  static Future<void> initialData() async {
    await ProfileData.getProfile();
    await UserOps.getUsers();
  }

  static void clearData() async {
    await APIService.removeToken();

    ProfileOps.delete();
    ProfileData.profile.clear();

    ShopOps.delete();
    ShopsData.shops.clear();

    UserOps.delete();
    UserData.users.clear();

    ProductOps.delete();
    ProductsData.products.clear();

    EmployeeOps.delete();
    EmployeeData.employees.clear();

    PurchaseOps.delete();
    PurchaseData.purchases.clear();

    RegisterOps.delete();
    RegistersData.registers.clear();

    SystemUserOps.delete();
    

  }

  static String getRole(String roleId) {
    if (roleId == "1") {
      return "Admin";
    } else if (roleId == "2") {
      return "Technician";
    } else if (roleId == "3") {
      return "Shop Owner";
    } else {
      return "Worker";
    }
  }
}
