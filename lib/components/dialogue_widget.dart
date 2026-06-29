import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/text_widget.dart';

class DialogueWidget extends StatefulWidget {
  final String title;
  final Widget content; // ✅ changed from Container to Widget
  final List<Widget> actions;

  const DialogueWidget({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  State<DialogueWidget> createState() => _DialogueWidgetState();
}

class _DialogueWidgetState extends State<DialogueWidget> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 30,
      title: TextWidget(
        text: widget.title,
      ),
      content: widget.content, // now accepts Form, Column, etc.
      actions: widget.actions,
    );
  }
}
