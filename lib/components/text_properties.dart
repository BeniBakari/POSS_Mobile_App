// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class TextProperties extends StatefulWidget {
  TextProperties({super.key});
  String textColor = "";
  double textSize = 20;

  get getTextColor => textColor;
  get getTextSize => textSize;
  @override
  State<TextProperties> createState() => _TextPropertiesState();
}

class _TextPropertiesState extends State<TextProperties> {
  void changeFonts() {
    setState(() {
      widget.textColor = "";
      widget.textSize = 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
