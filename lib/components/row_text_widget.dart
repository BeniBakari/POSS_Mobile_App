import 'package:flutter/material.dart';

// ignore: must_be_immutable
class RowTextWidget extends StatelessWidget {
  final String firstColumn;
  final String secondColumn;
  final Text? textWidget;
  final bool hasWidget;
  final Color color;
  final double fontsize;

  // ✅ NEW
  final IconData? icon;
  final Color iconColor;

  const RowTextWidget({
    super.key,
    required this.firstColumn,
    this.secondColumn = "null",
    this.hasWidget = false,
    this.textWidget,
    this.color = Colors.black,
    this.fontsize = 15,

    // ✅ NEW
    this.icon,
    this.iconColor = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= ICON =================
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Icon(
                icon,
                size: fontsize + 2,
                color: iconColor,
              ),
            ),

          // ================= CONTENT =================
          Expanded(
            child: Wrap(
              runSpacing: 2,
              children: [
                Text(
                  firstColumn,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontsize,
                  ),
                ),

                if (hasWidget && textWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: textWidget!,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      secondColumn,
                      style: TextStyle(
                        fontSize: fontsize,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
