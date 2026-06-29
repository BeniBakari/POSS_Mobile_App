import 'package:fluttertoast/fluttertoast.dart';

Future<bool?> toast(String msg) {
   return Fluttertoast.showToast(msg: msg);
}
