import 'package:flutter/material.dart';

void pushRouting(BuildContext context, String routeName, bool pushUntill) {
  if (pushUntill) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  } else {
    Navigator.pushNamed(context, routeName);
  }
}
