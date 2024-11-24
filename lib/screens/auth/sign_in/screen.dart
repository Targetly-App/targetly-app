import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:targetly/app_routes.dart';

import 'controller.dart';

class SignInScreen extends GetView<SignInController> {
  final signInFormKey = GlobalKey<FormBuilderState>(debugLabel: 'SignInForm');

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignInController>(
        init: SignInController(),
        builder: (SignInController controller) {
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
                    if (controller.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
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
                                            'Targetly'.tr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge!
                                                .copyWith(
                                                  color: Colors.white,
                                                ),
                                          ),
                                          Text(
                                            'Your Goals, Our Mission!'.tr,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      buildSignInForm(context)
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                      )
                  ],
                );
              },
            ),
          );
        });
  }

  Widget buildSignInForm(BuildContext context) {
    return FormBuilder(
      key: signInFormKey,
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
            validator: FormBuilderValidators.required(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Forgot your password?'.tr),
              TextButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.resetPassword);
                },
                child: Text('Reset'.tr),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 16),
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () {
              if (signInFormKey.currentState!.saveAndValidate()) {
                controller.signIn(
                  signInFormKey.currentState!.value['email'],
                  signInFormKey.currentState!.value['password'],
                );
              }
            },
            child: Text('Login'.tr),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Don\'t have an account?'.tr),
              TextButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.signUp);
                },
                child: Text('Register'.tr),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(20),
                  icon: const Icon(
                    Iconsax.google_1_bold,
                    color: Colors.white,
                  ),
                  onPressed: () => controller.signInWithGoogle(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(20),
                  icon: const Icon(
                    Iconsax.apple_bold,
                    color: Colors.white,
                  ),
                  onPressed: () => controller.signInWithApple(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
