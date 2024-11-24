import {z} from "zod";
import {ai} from "../ai";

export const additionalQuestionsSchema = z.array(
  z.object({
    title: z.string().describe("Title of the knowledge"),
    question: z.string().describe("Clarification question"),
    answerType: z.enum(["text", "select", "multi-select"])
      .describe("Type of the answer"),
    multiline: z.boolean()
      .describe("Is possible that answer will take more then 50 symbols"),
    answerOptions: z.array(z.string())
      .describe("Options for select or multi-select answers"),
  })
)
  .min(0)
  .max(7)
  .describe("Additional questions for understanding current user state");

export const AdditionalQuestionsSchema = ai.defineSchema(
  "AdditionalQuestionsSchema",
  additionalQuestionsSchema
);
