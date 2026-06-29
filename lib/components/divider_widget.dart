import 'package:flutter/material.dart';


class DividerWidget extends StatefulWidget {
  
  const DividerWidget({super.key});

  @override
  State<DividerWidget> createState() => _DividerWidgetState();
}

class _DividerWidgetState extends State<DividerWidget> {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 20,
      thickness: 1,
      color: Colors.blueAccent,
    );
  }
}