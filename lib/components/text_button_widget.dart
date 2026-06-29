import 'package:flutter/material.dart';

class TextButtonWidget extends StatefulWidget {
  final String textButton;
  final Color textColor;
  final Function onPressed;
  const TextButtonWidget(
      {super.key,
      required this.textButton,
      this.textColor = Colors.black,
      required this.onPressed});

  @override
  State<TextButtonWidget> createState() => _TextButtonWidgetState();
}

class _TextButtonWidgetState extends State<TextButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
        widget.textButton,
        style: TextStyle(color: widget.textColor),
      ),
      onPressed: () {
        widget.onPressed();
      },
    );
  }
}