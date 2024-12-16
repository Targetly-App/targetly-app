import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:targetly/screens/targets/add/controller.dart';

import '../../../exceptions.dart';
import '../../../widgets/step_wizard/widget.dart';

class TargetAddScreen extends GetView<TargetAddController> {
  const TargetAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: TargetAddController(),
      builder: (TargetAddController controller) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          bottom: false,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
              elevation: 0,
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text('Create target'.tr),
              ),
              actions: const [],
            ),
            body: StepWizard(
              steps: controller.workflowWizardPages,
              submitCallback: (answers) async {
                try {
                  await controller.createTarget(answers);
                } catch (e) {
                  if (e is NotEnoughTokensException) {
                    return showCupertinoModalBottomSheet(
                      expand: false,
                      context: context,
                      builder: (context) => const Stack(
                        children: <Widget>[
                          // SubscriptionScreen(),
                        ],
                      ),
                    );
                  }

                  throw Exception('Cannot create target');
                }
              },
              isLoading: controller.isLoading,
            ),
          ),
        );
      },
    );
  }
}
