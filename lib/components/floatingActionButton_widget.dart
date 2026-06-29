import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

class FloatingActionButtonWidget extends StatefulWidget {
  final Icon icon;
  final Function onBtnPressed;
  const FloatingActionButtonWidget(
      { this.icon = const Icon(Icons.post_add), required this.onBtnPressed, super.key});

  @override
  State<FloatingActionButtonWidget> createState() =>
      _FloatingActionButtonWIdgetState();
}

class _FloatingActionButtonWIdgetState
    extends State<FloatingActionButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: ColorsWidget().popMenuBackground,
      onPressed: () {
        widget.onBtnPressed();
      },
      child: Icon(
        widget.icon.icon,     // reuse icon type
        color: Colors.white,  
      )
      
    );
  }
}
