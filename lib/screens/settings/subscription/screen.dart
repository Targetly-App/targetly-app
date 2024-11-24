import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../widgets/button.dart';
import 'components/feature_tile.dart';
import 'controller.dart';

class SubscriptionScreen extends GetView<SubscriptionController> {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: SubscriptionController(),
        builder: (SubscriptionController controller) {
          return SafeArea(
            top: false,
            bottom: false,
            child: Scaffold(
              body: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/splash.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Content

                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Obx(() {
                        if (controller.loading()) {
                          return Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading...'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        } else if (!controller.isAvailable()) {
                          return Column(
                            children: [
                              const Text(
                                'In-app purchases are not available',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Button(
                                text: 'Okay, I will try later',
                                onPressed: () {
                                  Get.back();
                                },
                                variant: ButtonVariant.primary,
                              ),
                              const SizedBox(height: 30),
                            ],
                          );
                        } else if (controller.error.value.isNotEmpty) {
                          return Text(controller.error.value,
                              style: const TextStyle(color: Colors.white));
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _subscriptionDetails(),
                              const SizedBox(height: 24),
                              ...controller.products.map((product) {
                                bool isPurchased = controller
                                        .account?.subscription?.productId ==
                                    product.id;
                                return Card(
                                  color:
                                      const Color.fromARGB(255, 208, 208, 208)
                                          .withOpacity(isPurchased ? 0.5 : 1.0),
                                  shadowColor: Colors.purple.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    side: BorderSide(
                                      color: !isPurchased
                                          ? const Color.fromARGB(
                                                  255, 208, 208, 208)
                                              .withOpacity(0.8)
                                          : const Color.fromARGB(
                                              0, 255, 255, 255),
                                      width: 2.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(product.title,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        )),
                                    subtitle: isPurchased
                                        ? const Text('Your current plan',
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 68, 68, 68)))
                                        : null,
                                    trailing: Text(product.price,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        )),
                                    onTap: product.id !=
                                            controller.account?.subscription
                                                ?.productId
                                        ? () {
                                            controller.buySubscription(product);
                                          }
                                        : null,
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              Button(
                                text: 'Restore purchases',
                                onPressed: () => controller.restorePurchases(),
                                variant: ButtonVariant.secondary,
                              ),
                              const SizedBox(height: 16),
                              Button(
                                text: 'Maybe later',
                                onPressed: () => Get.close(1),
                                variant: ButtonVariant.primary,
                              ),
                              const SizedBox(height: 30),
                            ],
                          );
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _subscriptionDetails() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Unlock Unlimited Access',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'Get unlimited access with our subscription plans.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13, color: Color.fromARGB(255, 224, 224, 224)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FeatureTile(
                icon: Iconsax.cpu_charge_bold,
                title: 'Unlimited AI Features',
                description:
                    'No limits, no restrictions. Tasks generation, chat with the AI assistant, and more.',
              ),
              FeatureTile(
                icon: Iconsax.message_question_bold,
                title: 'Priority Support',
                description: 'Get help faster with priority customer support.',
              ),
              FeatureTile(
                icon: Iconsax.ranking_bold,
                title: 'Exclusive Features',
                description: 'Access to upcoming features before anyone else.',
              ),
              FeatureTile(
                icon: Iconsax.emoji_normal_bold,
                title: 'Ad-Free Experience',
                description: 'Enjoy the app without any interruptions.',
              ),
            ],
          ),
        )
      ],
    );
  }
}
