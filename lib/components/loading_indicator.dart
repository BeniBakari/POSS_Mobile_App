import 'package:flutter/material.dart';

// ignore: non_constant_identifier_names
Future LoadingIndicatorWidget(BuildContext context) {
  return showDialog(
      barrierDismissible: false,
      barrierLabel: "Hello",
      context: context,
      builder: (context) {
        return  const Center(
          child: CircularProgressIndicator(),
        );
      });
}
