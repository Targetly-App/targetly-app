import {z} from "zod";
import {ai} from "../ai";

// Enum definitions
const TaskRepeatEnum = z.enum([
  "once",
  "hourly",
  "daily",
  "weekly",
  "monthly",
  "yearly",
]);

// Duration pattern validation
const durationPattern = /^([0-9]+[hm]\s?){1,3}$/;

// Main Task schema
const TaskSchema = z.object({
  title: z.string().describe("Short title of the task."),

  description: z
    .string()
    .describe(`Summary and details of the task. 
Should not include another tasks`),

  isImportant: z.boolean().describe("Is task important to reach target?"),
  impact: z.number().int().min(1).max(10).describe("Task impact on target"),
  effort: z.number().int().min(1).max(10).describe("Task effort to complete"),

  duration: z
    .string()
    .regex(durationPattern)
    .describe("Duration of the task."),

  repeats: TaskRepeatEnum
    .describe("Types of repeats for task"),

  iterations: z
    .number()
    .int()
    .describe("Amount of iteration that required to reach target"),

  dependencies: z.array(z.number().int())
    .describe("List of task steps that should be completed before this task"),

  step: z
    .number()
    .int()
    .min(1)
    .describe(`Task step index in list of tasks.
Some tasks can have same index because they not depend on each other`),
});


export const listTasksOutputSchema = z.array(TaskSchema).min(1)
  .describe("List of tasks for target");


export const TasksOutputSchema = ai.defineSchema(
  "ListTasksOutputSchema",
  listTasksOutputSchema
);
