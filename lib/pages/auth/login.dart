import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';

import 'package:poss_mobile_app/data/profileData.dart';
import 'package:poss_mobile_app/models/profile.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/components/button_widget.dart';
import 'package:poss_mobile_app/components/transitions/page_route_builder.dart';
import 'package:poss_mobile_app/components/dialogue_widget.dart';
import 'package:poss_mobile_app/components/loading_indicator.dart';
import 'package:poss_mobile_app/components/regular_expressions.dart';
import 'package:poss_mobile_app/components/text_button_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/textfield_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/services/operations/profile_operations.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final forgotpasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> forgotPasswordformKey = GlobalKey<FormState>();

  bool hasLoginError = false;

  @override
  void initState() {
    super.initState();
    emailController.text = "benijohn@gmail.com";
    passwordController.text = "1234";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsWidget().scaffoldColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle_outlined,
                        size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 15),
                    const TextWidget(
                      text: "Welcome Back!",
                      fontsize: 26,

                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: emailController,
                      label: "Email or Username",
                      hint: "Enter your email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value.isEmpty) return "Email or username required";
                        if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) {
                          return "Invalid email or username.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: passwordController,
                      label: "Password",
                      hint: "Enter your password",
                      icon: Icons.lock_outline,
                      obsecureText: true,
                      validator: (value) => value.isEmpty ? "Password is required" : null,
                    ),
                    const SizedBox(height: 15),
                    if (hasLoginError)
                      const TextWidget(
                        text: "Incorrect email or password.",
                        color: Colors.red,
                        fontsize: 14,
                      ),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 250,
                      ),
                      child: ButtonWidget(
                        btnText: "Login",
                        onBtnPressed: _login,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButtonWidget(
                          textButton: "Sign Up",
                          textColor: Colors.red,
                          onPressed: () {
                            Navigator.pushNamed(context, 'registration');
                          },
                        ),
                        TextButtonWidget(
                          textButton: "Forgot password?",
                          textColor: Colors.blue,
                          onPressed: _forgotPassword,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obsecureText = false,
    String? Function(String)? validator,
  }) {
    return TextFieldWidget(
      textEditingController: controller,
      labelText: label,
      hintText: hint,
      textInputType: keyboardType,
      obsecureText: obsecureText,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      functionValidate: (value) => validator != null ? validator(value) : null,
    );
  }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;

    Map<String, String> data = {
      "email": emailController.text,
      "password": passwordController.text,
    };

    LoadingIndicatorWidget(context);
    Map response = await APIService.api("POST", "login", data);
    Navigator.pop(context);

    if (response['httpCode'] == 401) {
      passwordController.clear();
      setState(() {
        hasLoginError = true;
      });
    } else if (response['httpCode'] == 200) {
      setState(() {
        hasLoginError = false;
      });
      Map body = jsonDecode(response['body']);
      String token = body['data']['token'];
      APIService.saveToken(token);

      Map user = body['data']['user'];
      ProfileOps.create(Profile(
        id: user['id'].toString(),
        firstname: user['first_name'],
        lastname: user['last_name'],
        email: user['email'],
        roleId: user['role_id'].toString() == "null" ? "0" : user['role_id'].toString(),
        dob: user['dob'].toString(),
        phone: user['phone'].toString(),
        gender: user['gender'].toString(),
        address: user['address'].toString(),
        imagePath: user['imagePath'].toString(),
        token: token,
      ));

      UserOps.create(user);

      emailController.clear();
      passwordController.clear();
      await ProfileData.getProfile();

      pushRouting(context, "home", true);
    }
  }

  void _forgotPassword() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return DialogueWidget(
          title: "Enter registered email",
          content: Form(
            key: forgotPasswordformKey,
            child: TextFieldWidget(
              textEditingController: forgotpasswordController,
              textInputType: TextInputType.emailAddress,
              hintText: "Your email address",
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.blueAccent),
              labelText: "Email",
              functionValidate: (String value) {
                if (value.isEmpty) return "Email is required.";
                if (!RegExp(RegularExpression.emailRegEx).hasMatch(value)) return "Invalid email.";
                return null;
              },
            ),
          ),
          actions: [
            TextButtonWidget(
              textButton: "Recover",
              textColor: Colors.blue,
              onPressed: () async {
                if (!forgotPasswordformKey.currentState!.validate()) return;
                Map data = {"email": forgotpasswordController.text};
                LoadingIndicatorWidget(context);
                Map response = await APIService.api("POST", "forgot_password", data);
                Navigator.pop(context);
                if (response['httpCode'] == 200) {
                  toast("Please activate your account first");
                } else if (response['httpCode'] == 400) {
                  toast("Your email doesn't exist, please register.");
                } else if (response['httpCode'] == 201) {
                  Navigator.pop(context);
                  forgotpasswordController.clear();
                  toast("We emailed you a reset password link.");
                }
              },
            ),
            TextButtonWidget(
              textButton: "Close",
              textColor: Colors.red,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
