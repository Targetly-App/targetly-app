import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:targetly/screens/tutorial/tutorial_controller.dart';

class AnimatedScreenshot extends StatelessWidget {
  final String imagePath;
  final bool isVisible;
  final bool isLandscape;

  const AnimatedScreenshot({
    Key? key,
    required this.imagePath,
    required this.isVisible,
    required this.isLandscape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isVisible ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        transform: Matrix4.translationValues(
          0,
          isVisible ? 0 : 50,
          0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: isLandscape ? Get.width * 0.4 : Get.width * 0.85,
            height: isLandscape ? Get.height * 0.7 : Get.height * 0.5,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.transparent],
                  stops: [0.85, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                imagePath,
                alignment: Alignment.topCenter,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BlurredTextOverlay extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const BlurredTextOverlay({
    Key? key,
    required this.child,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class TutorialScreen extends StatelessWidget {
  final List<TutorialStep> steps;

  TutorialScreen({
    Key? key,
    required this.steps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TutorialController(steps: steps));
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget buildMainContent(TutorialStep step, bool isLandscape) {
      return BlurredTextOverlay(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  step.title,
                  key: ValueKey<String>(step.title),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Description with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  step.description,
                  key: ValueKey<String>(step.description),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildNavigationButtons() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() => AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: controller.currentStep.value > 0 ? 1.0 : 0.0,
                child: TextButton(
                  onPressed: controller.currentStep.value > 0
                      ? controller.previousStep
                      : null,
                  child: Text(
                    'Previous',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              )),
          Obx(() => ElevatedButton(
                onPressed: controller.isLastStep.value
                    ? controller.skipTutorial
                    : controller.nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  controller.isLastStep.value ? 'Get Started' : 'Next',
                ),
              )),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: controller.skipTutorial,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Obx(() {
                final step = steps[controller.currentStep.value];
                if (isLandscape) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (step.imagePath != null)
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: AnimatedScreenshot(
                                key: ValueKey<String>(step.imagePath!),
                                imagePath: step.imagePath!,
                                isVisible: true,
                                isLandscape: true,
                              ),
                            ),
                          ),
                        )
                      else if (step.icon != null)
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Icon(
                              step.icon,
                              size: 120,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: buildMainContent(step, isLandscape),
                              ),
                              const SizedBox(height: 32),
                              // Progress indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  steps.length,
                                  (index) => Obx(() {
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width:
                                          controller.currentStep.value == index
                                              ? 20
                                              : 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: controller.currentStep.value ==
                                                index
                                            ? theme.colorScheme.secondary
                                            : theme.colorScheme.onBackground
                                                .withOpacity(0.2),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 32),
                              buildNavigationButtons(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Portrait mode layout remains the same
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (step.imagePath != null)
                        Flexible(
                          flex: 3,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: AnimatedScreenshot(
                              key: ValueKey<String>(step.imagePath!),
                              imagePath: step.imagePath!,
                              isVisible: true,
                              isLandscape: false,
                            ),
                          ),
                        )
                      else if (step.icon != null)
                        Flexible(
                          flex: 3,
                          child: Icon(
                            step.icon,
                            size: 120,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      Flexible(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: buildMainContent(step, isLandscape),
                        ),
                      ),
                    ],
                  );
                }
              }),
            ),

            // Bottom navigation section (only in portrait mode)
            if (!isLandscape)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        steps.length,
                        (index) => Obx(() {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width:
                                controller.currentStep.value == index ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: controller.currentStep.value == index
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.onBackground
                                      .withOpacity(0.2),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: buildNavigationButtons(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
