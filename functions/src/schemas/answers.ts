import {z} from "zod";

const answersInputSchema = z.array(z.object({
  question: z.string(),
  answer: z.string(),
}).optional());

export type AnswersInputSchema = z.infer<typeof answersInputSchema>;
export {answersInputSchema};

