import 'package:flutter/material.dart';
import 'package:poss_mobile_app/pages/auth/login.dart';
import 'package:poss_mobile_app/pages/home.dart';
import 'package:poss_mobile_app/services/sqlite_service.dart';

import 'components/text_widget.dart';
import 'data/data.dart';
import 'data/profileData.dart';



class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  void initState() {
    super.initState();
    SqliteService.initializeDB();
    ProfileData.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Data.initialData(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return splashScreen();
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          return Data.hasLoggedIn ? const Home() : const Login();
        }
        return const SizedBox();
      },
    );
  }

  Widget splashScreen() {
    return const Scaffold(
      body: Center(
        child: TextWidget(
          text: "Loading....",
          fontsize: 15,
        ),
      ),
    );
  }
}
