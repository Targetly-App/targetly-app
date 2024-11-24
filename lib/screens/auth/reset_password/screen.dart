import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:targetly/app_routes.dart';
import 'package:targetly/screens/auth/reset_password/controller.dart';

import '../../../widgets/button.dart';

class ResetPasswordScreen extends GetWidget<ResetPasswordController> {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ResetPasswordController>(
        init: ResetPasswordController(),
        builder: (ResetPasswordController controller) {
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
                                          'Reset Password',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium!
                                              .copyWith(
                                                color: Colors.white,
                                              ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Please specify the email to reset the password'
                                              .tr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    buildResetPasswordForm(context, controller)
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

  Widget buildResetPasswordForm(
      BuildContext context, ResetPasswordController controller) {
    return FormBuilder(
      key: controller.authFormKey,
      child: Column(
        children: [
          FormBuilderTextField(
            name: 'email',
            readOnly: controller.isLoading || controller.isEmailSent,
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
          if (controller.isEmailSent)
            Column(
              children: [
                Text('We have sent a link to reset the password to your email'
                    .tr),
                // const SizedBox(height: 16.0),
                // PinInputWidget(key: controller.pinKey, pinLength: 6),
                // const SizedBox(height: 16.0),
                // FormBuilderTextField(
                //   name: 'password',
                //   onChanged: (value) {
                //     controller.canBeSubmitted =
                //         value != null && value.isNotEmpty;
                //     controller.update();
                //   },
                //   decoration: InputDecoration(
                //     label: Text('New password'.tr),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(25.0),
                //     ),
                //     hintText: 'Please specify the password'.tr,
                //     suffixIcon: IconButton(
                //       padding: const EdgeInsets.all(16),
                //       enableFeedback: true,
                //       icon: Icon(
                //         controller.isPasswordVisible
                //             ? Iconsax.eye_outline
                //             : Iconsax.eye_slash_outline,
                //       ),
                //       onPressed: controller.togglePasswordVisibility,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 16.0),
                // Button(
                //   onPressed: controller.canBeSubmitted
                //       ? () {
                //           controller.resetPassword();
                //         }
                //       : null,
                //   isLoading: controller.isLoading,
                //   text: 'Reset Password',
                // ),
              ],
            ),
          if (!controller.isEmailSent)
            Column(
              children: [
                const SizedBox(height: 16.0),
                Button(
                  isLoading: controller.isLoading,
                  onPressed: () {
                    controller.sendRecoveryLink();
                  },
                  text: 'Send link to reset password'.tr,
                ),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Remember your password?'.tr),
              TextButton(
                onPressed: () {
                  Get.offNamedUntil(AppRoutes.signIn, (route) => false);
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
