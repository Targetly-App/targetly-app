import {firestore} from "../firebase";
import {AdditionalQuestionsSchema} from "../schemas/additional-questions";
import {TasksOutputSchema} from "../schemas/tasks";
import {AnswersInputSchema} from "../schemas/answers";
import {ai} from "../ai";

type AdditionalQuestionsRequest = {
  uid: string;
  targetId: string;
};

export const requestAdditionalQuestions = async (
  {uid, targetId}: AdditionalQuestionsRequest
): Promise<ReturnType<typeof AdditionalQuestionsSchema["parse"]>> => {
  // Getting
  const targets = firestore.collection("targets");
  const target = (await targets.doc(targetId).get()).data();

  const additionalQuestionsPrompt = ai.prompt("tasks_additional_questions");

  const result = await additionalQuestionsPrompt({
    targetTitle: target?.title,
    targetDescription: target?.description,
  });
  console.log(result.text);
  return JSON.parse(result.text);
};


type GenerateTasksRequest = {
  uid: string;
  targetId: string;
  answers: AnswersInputSchema;
};
export const generateTasks = async (
  {uid, targetId, answers}: GenerateTasksRequest
): Promise<ReturnType<typeof TasksOutputSchema["parse"]>> => {
  // Getting
  const targets = firestore.collection("targets");
  const target = (await targets.doc(targetId).get()).data();

  const taskGenerationPrompt = ai.prompt("tasks_generation");

  const answersString = answers.map((answer) => (`
    ${answer?.question}: ${answer?.answer}`)).join("\n");

  // Converting Firestore date value to string
  const deadline = target?.deadline.toString();

  const {text} = await taskGenerationPrompt({
    today: new Date().toISOString(),
    targetTitle: target?.title,
    targetDescription: target?.description,
    deadline,
    answers: answersString,
  });

  return JSON.parse(text);
};
