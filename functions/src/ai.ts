import {genkit} from "genkit";
import {enableFirebaseTelemetry} from "@genkit-ai/firebase";
import {
  vertexAI,
  gemini15Flash,
} from "@genkit-ai/vertexai";

enableFirebaseTelemetry({projectId: "targetly"});

// configure a Genkit instance
const ai = genkit({
  plugins: [
    vertexAI({projectId: "targetly", location: "us-central1"}),
  ],
  model: gemini15Flash,
});

export {ai};
