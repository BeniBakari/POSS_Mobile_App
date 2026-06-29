import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/constants.dart';
import 'package:poss_mobile_app/components/measurement.dart';

class CustomDialogBox extends StatefulWidget {
  final String title;
  final List<Widget> content;
  final List<Widget> actions;

  const CustomDialogBox({
    super.key,
    required this.title,
    this.content = const [],
    required this.actions,
  });

  @override
  _CustomDialogBoxState createState() => _CustomDialogBoxState();
}

class _CustomDialogBoxState extends State<CustomDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Measurement.getHeight(context) * 0.033),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  contentBox(context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(
              left: Measurement.getHeight(context) * 0.033,
              top: Measurement.getHeight(context) * 0.05,
              right: Measurement.getHeight(context) * 0.033,
              bottom: Measurement.getHeight(context) * 0.033,
            ),
            margin: EdgeInsets.only(top: Measurement.getHeight(context) * 0.07),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),

                // Content
                if (widget.content.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.content
                        .map((w) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: w,
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: widget.actions,
                ),
              ],
            ),
          ),
          // Optional Avatar on top
          // Positioned(
          //   top: -Constants.avatarRadius,
          //   left: 0,
          //   right: 0,
          //   child: CircleAvatar(
          //     backgroundColor: Colors.transparent,
          //     radius: Constants.avatarRadius,
          //     child: ClipRRect(
          //       borderRadius: const BorderRadius.all(Radius.circular(Constants.avatarRadius)),
          //       child: Image.asset("assets/user_icon.png"),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
