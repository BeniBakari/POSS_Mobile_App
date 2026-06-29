import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/drawer.dart';

// ignore: must_be_immutable
class ScaffoldWidget extends StatefulWidget {
  Widget body;
  Widget title;
  List<Widget> actions;
  Widget floatingActionButton;

  ScaffoldWidget({
    super.key,
    required this.body,
    required this.title,
    this.actions = const [],
    this.floatingActionButton = const SizedBox.shrink(),
  });

  @override
  State<ScaffoldWidget> createState() => _ScaffoldWidgetState();
}

class _ScaffoldWidgetState extends State<ScaffoldWidget> {
  @override
  Widget build(BuildContext context) {
    final appBarColor = ColorsWidget().appBarColor;

    // Total header height: status bar + 50 (top padding) + content (~38) + 10 (bottom padding)
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = statusBarHeight + 60;

    return Scaffold(
      backgroundColor: ColorsWidget().scaffoldColor,
      drawer: const DrawerWidget(),

      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            /// 👇 MAIN CONTENT — offset so it starts below the glass header
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: headerHeight),
                child: widget.body,
              ),
            ),

            /// 👇 GRADIENT BACKGROUND (TOP AREA)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      appBarColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            /// 👇 GLASS HEADER
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 50,
                      left: 16,
                      right: 16,
                      bottom: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// 👇 Drawer Button
                        Builder(
                          builder: (context) => IconButton(
                            icon: Icon(Icons.menu, color: appBarColor),
                            onPressed: () =>
                                Scaffold.of(context).openDrawer(),
                          ),
                        ),

                        /// 👇 TITLE
                        Expanded(
                          child: Center(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: appBarColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              child: widget.title,
                            ),
                          ),
                        ),

                        /// 👇 ACTIONS
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.actions,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: widget.floatingActionButton,
    );
  }
}