import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/drawer.dart';

// ignore: must_be_immutable
class ScaffoldTabWidget extends StatefulWidget {
  Widget body;
  Widget title;
  Widget floatingActionButton;
  List<Widget> actions;
  List<Tab> tabs;

  ScaffoldTabWidget({
    super.key,
    required this.body,
    required this.tabs,
    required this.title,
    this.floatingActionButton = const SizedBox.shrink(),
    this.actions = const [],
  });

  @override
  State<ScaffoldTabWidget> createState() => _ScaffoldTabWidgetState();
}

class _ScaffoldTabWidgetState extends State<ScaffoldTabWidget> {
  @override
  Widget build(BuildContext context) {
    final appBarColor = ColorsWidget().appBarColor;

    // Header height: status bar + top padding (50) + title row (~38) + tab bar (~48) + bottom padding (10)
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = statusBarHeight + 106;

    return DefaultTabController(
      length: widget.tabs.length,
      child: Scaffold(
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
                  height: 150,
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

              /// 👇 GLASS HEADER (title row + tab bar)
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
                        bottom: 0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// ── Title Row ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /// Drawer Button
                              Builder(
                                builder: (context) => IconButton(
                                  icon: Icon(Icons.menu, color: appBarColor),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer(),
                                ),
                              ),

                              /// Title
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

                              /// Actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: widget.actions,
                              ),
                            ],
                          ),

                          /// ── Tab Bar ──
                          TabBar(
                            tabs: widget.tabs,
                            labelColor: appBarColor,
                            unselectedLabelColor:
                                appBarColor.withValues(alpha: 0.45),
                            indicatorColor: appBarColor,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
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
      ),
    );
  }
}