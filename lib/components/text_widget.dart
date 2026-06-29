import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TextWidget extends StatelessWidget {
  final String text;
  final Color color;
  final double fontsize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextDecoration? decoration;
  final double? letterSpacing;

  const TextWidget({
    super.key,
    required this.text,
    this.color = Colors.black,
    this.fontsize = 20,
    this.fontWeight,
    this.textAlign,
    this.decoration,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.start,
      style: TextStyle(
        fontSize: fontsize,
        color: color,
        fontWeight: fontWeight ?? FontWeight.normal,
        decoration: decoration,
        letterSpacing: letterSpacing,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
