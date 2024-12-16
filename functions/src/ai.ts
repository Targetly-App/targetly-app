import {genkit} from "genkit";
import {enableFirebaseTelemetry} from "@genkit-ai/firebase";
import {
  claude35SonnetV2,
  vertexAIModelGarden,
} from "@genkit-ai/vertexai/modelgarden";
import vertexAI from "@genkit-ai/vertexai";

enableFirebaseTelemetry({projectId: "targetly"});

// configure a Genkit instance
const ai = genkit({
  plugins: [
    vertexAI({projectId: "targetly", location: "europe-west1"}),
    vertexAIModelGarden({
      location: "europe-west1",
      models: [claude35SonnetV2],
    }),
  ],
  model: claude35SonnetV2,
});

export {ai};
