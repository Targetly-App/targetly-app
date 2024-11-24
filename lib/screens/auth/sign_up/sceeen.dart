import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:targetly/app_routes.dart';

import 'controller.dart';

class SignUpScreen extends GetView<SignUpController> {
  final signUpFormKey = GlobalKey<FormBuilderState>(debugLabel: 'SignUpForm');

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
        init: SignUpController(),
        builder: (SignUpController controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            body: Builder(
              builder: (context) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/splash.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    SafeArea(
                      child: CustomScrollView(
                          physics: const PageScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Get.toNamed(AppRoutes.terms);
                                          },
                                          child: Text('Terms'.tr),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Get.toNamed(AppRoutes.privacy);
                                          },
                                          child: Text('Privacy'.tr),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sign up'.tr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge!
                                              .copyWith(
                                                color: Colors.white,
                                              ),
                                        ),
                                        Text(
                                          'Create an account to get started'.tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    buildSignUpForm(context),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                    ),
                  ],
                );
              },
            ),
          );
        });
  }

  Widget buildSignUpForm(BuildContext context) {
    return FormBuilder(
      key: signUpFormKey,
      child: Column(
        children: [
          FormBuilderTextField(
            name: 'email',
            decoration: InputDecoration(
              label: Text('Email'.tr),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              hintText: 'Please specify the email'.tr,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.email(),
            ]),
          ),
          const SizedBox(height: 32.0),
          FormBuilderTextField(
            name: 'password',
            obscureText: !controller.isPasswordVisible,
            decoration: InputDecoration(
              label: Text('Password'.tr),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              hintText: 'Please specify the password'.tr,
              suffixIcon: IconButton(
                padding: const EdgeInsets.all(16),
                enableFeedback: true,
                icon: Icon(
                  controller.isPasswordVisible
                      ? Iconsax.eye_outline
                      : Iconsax.eye_slash_outline,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(6),
              FormBuilderValidators.maxLength(128),
            ]),
          ),
          const SizedBox(height: 32.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 16),
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () {
              controller.signUp(signUpFormKey);
            },
            child: Text('Sign up'.tr),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account?'.tr),
              TextButton(
                onPressed: () async {
                  Get.close(1);
                },
                child: Text('Login'.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
