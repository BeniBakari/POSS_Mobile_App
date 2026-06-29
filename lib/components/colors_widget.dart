// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class ColorsWidget extends StatefulWidget {
  ColorsWidget({super.key});
  Color scaffoldColor = Color(int.parse("0xFFe6ffff"));
  //Color scaffoldColor = Color(int.parse("0xffbf00"));
  Color textColor = Colors.black;
  Color buttonsColor = Color(int.parse("0xFF333399"));
  Color appBarColor = Color(int.parse("0xFF333399"));
  Color popMenuBackground = Color(int.parse("0xFF000033")); 
  double textSize = 20;

  @override
  State<ColorsWidget> createState() => _ColorsWidgetState();

  int getColor(String hexToAppend) {
    String color = '0xFF$hexToAppend';

    return int.parse(color);
  }

  void changeAppBarColor() {}
}

class _ColorsWidgetState extends State<ColorsWidget> {


  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
