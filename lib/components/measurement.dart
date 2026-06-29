import 'package:flutter/cupertino.dart';

class Measurement {
  static double getWidth(context) {
    return MediaQuery.of(context).size.width;
  }

  static double getHeight(context) {
    return MediaQuery.of(context).size.height;
  }

  static double getTextFieldHeight(context) {
    return MediaQuery.of(context).size.height * 0.015;
  }

  static double getTextFieldWidth(context) {
    return MediaQuery.of(context).size.height * 0.2;
  }
}
