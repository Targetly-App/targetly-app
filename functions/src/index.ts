import * as z from "zod";
import {firebaseAuth} from "@genkit-ai/firebase/auth";
import {onFlow} from "@genkit-ai/firebase/functions";
import {chatMessage} from "./controllers/chat";
import {requestAdditionalQuestions, generateTasks} from "./controllers/tasks";
import {additionalQuestionsSchema} from "./schemas/additional-questions";
import {listTasksOutputSchema} from "./schemas/tasks";
import {answersInputSchema} from "./schemas/answers";
import {ai} from "./ai";
import {DecodedIdToken} from "firebase-admin/auth";

const checkAccess = (user: DecodedIdToken, input: DecodedIdToken) => {
  if (process.env.NODE_ENV === "development") {
    return;
  }

  if (!user) {
    throw new Error("Authorization required.");
  }

  if (!user.email_verified) {
    throw new Error("Verified email required to run flow");
  }

  if (input.uid !== user.uid) {
    throw new Error("You may chat only with your assistant.");
  }
};


export const chatMessageFlow = onFlow(
  ai,
  {
    name: "chatMessageFlow",
    inputSchema: z.object({
      uid: z.string(),
      message: z.string(),
      targetId: z.string().nullable().optional(),
      taskId: z.string().nullable().optional(),
    }),
    outputSchema: z.string(),
    authPolicy: firebaseAuth(checkAccess),
  },
  chatMessage
);

export const requestAdditionalQuestionsFlow = onFlow(
  ai,
  {
    name: "requestAdditionalQuestionsFlow",
    inputSchema: z.object({
      uid: z.string(),
      targetId: z.string(),
    }),
    outputSchema: additionalQuestionsSchema,
    authPolicy: firebaseAuth(checkAccess),
  },
  requestAdditionalQuestions
);

export const generateTasksFlow = onFlow(
  ai,
  {
    name: "generateTasksFlow",
    inputSchema: z.object({
      uid: z.string(),
      targetId: z.string(),
      answers: answersInputSchema,
    }),
    outputSchema: listTasksOutputSchema,
    authPolicy: firebaseAuth(checkAccess),
  },
  generateTasks
);

// Purchase verification and restore purchases functions are not included in the final version of the code.
export {verifyPurchase, restorePurchases} from "./controllers/purchases";
