import type { AiGenerateInput, AiProvider } from "./provider";

type GeminiResponse = {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
  error?: {
    message?: string;
  };
};

export class GeminiProvider implements AiProvider {
  private apiKey: string;
  private model: string;

  constructor({ apiKey, model = "gemini-2.5-flash" }: { apiKey: string; model?: string }) {
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY 환경변수가 설정되지 않았습니다.");
    }

    this.apiKey = apiKey;
    this.model = model;
  }

  async generateText(input: AiGenerateInput) {
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent`;
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": this.apiKey
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: input.systemPrompt }]
        },
        contents: input.messages.map((message) => ({
          role: message.role === "assistant" ? "model" : "user",
          parts: [{ text: message.content }]
        })),
        generationConfig: {
          temperature: 0.5,
          topP: 0.9,
          maxOutputTokens: 1400
        }
      })
    });

    const data = (await response.json()) as GeminiResponse;

    if (!response.ok) {
      throw new Error(data.error?.message ?? "Gemini API 호출에 실패했습니다.");
    }

    const text = data.candidates?.[0]?.content?.parts?.map((part) => part.text ?? "").join("").trim();
    if (!text) {
      throw new Error("Gemini 응답이 비어 있습니다.");
    }

    return text;
  }
}

export function createGeminiProvider() {
  return new GeminiProvider({ apiKey: process.env.GEMINI_API_KEY ?? "" });
}
