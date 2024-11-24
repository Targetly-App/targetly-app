import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/snack_bar_service.dart';
import '../button.dart';

class StepWizardQuestion {
  final String id;
  final String title;
  final String question;
  final String hint;
  final String? answer;
  final bool multiline;
  final bool multipleChoice;
  final List<String?> options;
  final int minChars;
  final int maxChars;

  StepWizardQuestion({
    required this.id,
    required this.title,
    required this.question,
    this.answer,
    this.hint = '',
    this.minChars = 1,
    this.maxChars = 500,
    this.multiline = false,
    this.multipleChoice = false,
    this.options = const [],
  });
}

class StepWizard extends StatefulWidget {
  final PageController controller = PageController(initialPage: 0);
  final List<dynamic> steps;
  late final List<StepWizardQuestion> _questions;
  late final List<FocusNode> _focusNodes;
  final Function(String answer)? nextCallback;
  final Function(String answer)? prevCallback;
  final Function(Map<String, String> answers) submitCallback;
  final bool isLoading;

  StepWizard({
    super.key,
    required this.steps,
    this.nextCallback,
    this.prevCallback,
    this.isLoading = false,
    required this.submitCallback,
  }) {
    _questions = steps.whereType<StepWizardQuestion>().toList();
    _focusNodes = List.generate(_questions.length, (index) => FocusNode());
  }

  @override
  _StepWizardState createState() => _StepWizardState();
}

class _StepWizardState extends State<StepWizard> {
  bool inTransition = false;
  bool isFirstPage = true;
  bool isLastPage = false;
  final Map<String, String> _answers = {};
  final Map<String, Set<String>> _multipleChoiceSelections = {};

  @override
  void initState() {
    super.initState();
    for (StepWizardQuestion question in widget._questions) {
      if (question.answer != null) {
        _answers[question.id] = question.answer!;
        if (question.multipleChoice) {
          _multipleChoiceSelections[question.id] =
              question.answer!.split(',').where((e) => e.isNotEmpty).toSet();
        }
      } else {
        _answers[question.id] = '';
        if (question.multipleChoice) {
          _multipleChoiceSelections[question.id] = <String>{};
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(
        children: [
          Flexible(
            flex: 1,
            child: PageView.builder(
              controller: widget.controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.steps.length,
              itemBuilder: (context, index) {
                var step = widget.steps[index];

                Widget stepPage = const SizedBox();
                if (step is Function(Map<String, String> answers)) {
                  stepPage = step(_answers) as Widget;
                } else if (step is StepWizardQuestion) {
                  stepPage = questionPage(step);
                }

                return SingleChildScrollView(child: stepPage);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isFirstPage)
                  Expanded(
                    child: Button(
                      text: 'Previous'.tr,
                      onPressed: inTransition ? null : prevPage,
                    ),
                  ),
                if (!isFirstPage) const SizedBox(width: 24),
                Expanded(
                  child: Button(
                    text: isLastPage ? 'Submit'.tr : 'Next'.tr,
                    onPressed: inTransition
                        ? null
                        : isLastPage
                            ? submit
                            : nextPage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (widget.isLoading)
        Container(
          color: Colors.black.withOpacity(0.5),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ]);
  }

  Widget questionPage(StepWizardQuestion question) {
    int questionIndex = widget._questions.indexOf(question);
    String stepInfo = 'Step ${questionIndex + 1} / ${widget._questions.length}';
    if (question.minChars == 0) {
      stepInfo += ' (optional)';
    }

    // Ensure the Set exists for this question
    _multipleChoiceSelections[question.id] ??= <String>{};

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              stepInfo,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            Text(
              question.question,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (question.options.isNotEmpty)
              Column(
                children: question.options.map((option) {
                  if (option == null) return const SizedBox.shrink();

                  if (question.multipleChoice) {
                    bool isSelected = _multipleChoiceSelections[question.id]
                            ?.contains(option) ??
                        false;
                    return CheckboxListTile(
                      title: Text(option),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _multipleChoiceSelections[question.id]?.add(option);
                          } else {
                            _multipleChoiceSelections[question.id]
                                ?.remove(option);
                          }
                          // Update the answers string
                          _answers[question.id] =
                              _multipleChoiceSelections[question.id]
                                      ?.join(',') ??
                                  '';
                        });
                      },
                    );
                  } else {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: _answers[question.id],
                      onChanged: (value) {
                        setState(() {
                          _answers[question.id] = value!;
                        });
                      },
                    );
                  }
                }).toList(),
              ),
            if (question.options.isEmpty)
              TextField(
                focusNode: widget._focusNodes[questionIndex],
                autofocus: true,
                controller: TextEditingController(
                  text: _answers[question.id],
                ),
                maxLength: question.maxChars,
                maxLines: question.multiline ? 4 : 1,
                enableSuggestions: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: question.hint,
                ),
                onChanged: (value) {
                  _answers[question.id] = value;
                },
              ),
          ],
        ));
  }

  void nextPage() {
    int pageIndex = widget.controller.page!.toInt();
    var currentStep = widget.steps[pageIndex];
    var nextStep = widget.steps[pageIndex + 1];

    if (currentStep is StepWizardQuestion) {
      int questionIndex = widget._questions.indexOf(currentStep);
      widget._focusNodes[questionIndex].unfocus();

      String answer = _answers[currentStep.id] ?? '';

      if (answer.length < currentStep.minChars) {
        SnackBarService.showError(
          'Please provide an answer with at least ${currentStep.minChars} characters',
        );
        return;
      }

      if (widget.nextCallback != null) {
        bool isInputValid = widget.nextCallback!(answer);
        if (!isInputValid) {
          return;
        }
      }
    }

    setState(() {
      inTransition = true;
      isLastPage = pageIndex + 1 == widget.steps.length - 1;
      isFirstPage = false;
    });

    widget.controller.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(milliseconds: 210), () {
      setState(() {
        inTransition = false;
      });

      if (nextStep is StepWizardQuestion) {
        int questionIndex = widget._questions.indexOf(nextStep);
        widget._focusNodes[questionIndex].requestFocus();
      }
    });
  }

  void prevPage() {
    int pageIndex = widget.controller.page!.toInt();
    var currentStep = widget.steps[pageIndex];
    var prevStep = widget.steps[pageIndex - 1];

    if (currentStep is StepWizardQuestion) {
      int questionIndex = widget._questions.indexOf(currentStep);
      widget._focusNodes[questionIndex].unfocus();
    }

    setState(() {
      inTransition = true;
      isFirstPage = pageIndex - 1 == 0;
      isLastPage = false;
    });

    widget.controller.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(milliseconds: 210), () {
      setState(() {
        inTransition = false;
      });

      if (prevStep is StepWizardQuestion) {
        int questionIndex = widget._questions.indexOf(prevStep);
        widget._focusNodes[questionIndex].requestFocus();
      }
    });
  }

  void submit() {
    widget.submitCallback(_answers);
  }

  @override
  void dispose() {
    for (FocusNode node in widget._focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
