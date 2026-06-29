import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

class ButtonWidget extends StatelessWidget {
  final String btnText;
  final bool enabled;
  final Function onBtnPressed;

  const ButtonWidget(
      {super.key, required this.btnText, this.enabled = false, required this.onBtnPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          onBtnPressed();
        },
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.all<Color>(ColorsWidget().buttonsColor),
        ),
        child: Text(
          btnText,
          style: const TextStyle(color: Colors.white),
        ));
  }
}
