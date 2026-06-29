import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poss_mobile_app/components/colors_widget.dart';
import 'package:poss_mobile_app/components/text_widget.dart';
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/components/transitions/page_route_builder.dart';
import 'package:poss_mobile_app/data/profileData.dart';
import 'package:poss_mobile_app/models/profile.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:poss_mobile_app/components/button_widget.dart';
import 'package:poss_mobile_app/services/operations/profile_operations.dart';
import 'package:poss_mobile_app/services/operations/user_ops.dart';
import 'package:poss_mobile_app/wrapper.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ---------- validators ----------

  String? _validateName(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label cannot be empty';
    }
    if (value.trim().length < 2) {
      return '$label must be at least 2 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s'\-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return '$label can only contain letters, spaces, hyphens, or apostrophes';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number cannot be empty';
    }
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(digits)) {
      return 'Enter a valid phone number (7–15 digits, optional + prefix)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ---------- field builder ----------

  Widget _buildUnderlineField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isConfirm = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword
            ? _obscurePassword
            : isConfirm
                ? _obscureConfirm
                : false,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : isConfirm
                  ? IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    )
                  : null,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  // ---------- lifecycle ----------

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsWidget().scaffoldColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centered header
                  const Center(
                    child: TextWidget(
                      text: "Sign Up",
                      fontsize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildUnderlineField(
                    icon: Icons.person,
                    label: "First Name",
                    controller: firstNameController,
                    validator: (v) => _validateName(v, "First Name"),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z\s'\-]")),
                    ],
                  ),

                  _buildUnderlineField(
                    icon: Icons.person_outline,
                    label: "Last Name",
                    controller: lastNameController,
                    validator: (v) => _validateName(v, "Last Name"),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z\s'\-]")),
                    ],
                  ),

                  _buildUnderlineField(
                    icon: Icons.email,
                    label: "Email",
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),

                  _buildUnderlineField(
                    icon: Icons.phone,
                    label: "Phone Number",
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\+\s\-\(\)]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),

                  _buildUnderlineField(
                    icon: Icons.lock,
                    label: "Password",
                    controller: passwordController,
                    isPassword: true,
                    validator: _validatePassword,
                  ),

                  _buildUnderlineField(
                    icon: Icons.lock_outline,
                    label: "Confirm Password",
                    controller: confirmController,
                    isConfirm: true,
                    validator: _validateConfirmPassword,
                  ),

                  const SizedBox(height: 30),

                  // Right-aligned Sign Up button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ButtonWidget(
                      btnText: "Sign Up",
                      onBtnPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        Map data = {
                          "first_name": firstNameController.text.trim(),
                          "last_name": lastNameController.text.trim(),
                          "email": emailController.text.trim(),
                          "phone": phoneController.text.trim(),
                          "password": passwordController.text,
                          "confirm_password": confirmController.text,
                        };

                        Map response =
                            await APIService.api("POST", "register", data);
                        print(response);
                        if (response['httpCode'] == 200 ||
                            response['httpCode'] == 201) {
                          Map body = jsonDecode(response['body']);
                          if (body['success'] == true) {
                            toast(
                                "Success, we emailed you a verification link.");
                            String token = body['data']['token'];
                            APIService.saveToken(token);

                            Map user = body['data']['user'];
                            ProfileOps.create(Profile(
                              id: user['id'].toString(),
                              firstname: user['first_name'],
                              lastname: user['last_name'],
                              email: user['email'],
                              roleId: user['role_id'].toString() == "null"
                                  ? "0"
                                  : user['role_id'].toString(),
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
                          } else {
                            toast(body['message'] ?? "Registration failed.");
                          }
                        } else {
                          toast("Error: ${response['httpCode']}");
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
