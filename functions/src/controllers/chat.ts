import {firestore} from "../firebase";
import {ai} from "../ai";
import {promptRef} from "@genkit-ai/dotprompt";

// interface ChatSessionState {
//   targetTitle: string | null;
//   targetDescription: string | null;
//   taskTitle: string | null;
//   taskDescription: string | null;
// }

type ChatMessageRequest = {
  message: string,
  uid: string,
  targetId?: string | null,
  taskId?: string | null,
};

export const chatMessage = async (
  {message, uid, targetId, taskId}: ChatMessageRequest
): Promise<string> => {
  // Getting messages from firebase for last 30 minutes
  const chatMessages = firestore.collection("chatMessages");
  const query = chatMessages.where("uid", "==", uid);
  let target = null;
  let task = null;
  if (targetId) {
    target = (await firestore.collection("targets").doc(targetId).get()).data();
    query.where("targetId", "==", targetId);
  }
  if (taskId) {
    task = (await firestore.collection("tasks").doc(taskId).get()).data();
    query.where("taskId", "==", taskId);
  }
  const messages = await query
    .where("createdAt", ">", new Date(Date.now() - 30 * 60 * 1000))
    .orderBy("createdAt", "asc")
    .get();

  const previousConversation = messages.docs.map(
    (doc) => {
      const data = doc.data();
      return {role: data.sender, content: [{text: data.message}]};
    });

  const chatPrompt = promptRef("chat_message");

  const systemPrompt = await chatPrompt.render(ai.registry, {
    input: {
      targetTitle: target?.title,
      targetDescription: target?.description,
      taskTitle: task?.title,
      taskDescription: task?.description,
    },
  });

  const response = await ai.generate({
    messages: [...systemPrompt.messages || [], ...previousConversation],
    prompt: [
      {text: message},
    ],
  });

  const responseMessage = response.message?.content.map((c) => c.text).join("\n") ||
  "We have technical issues. Please try again later.";
  console.log(responseMessage);
  return responseMessage;
};

