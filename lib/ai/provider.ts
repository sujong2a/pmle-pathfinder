export type AiRole = "user" | "assistant";

export type AiMessage = {
  role: AiRole;
  content: string;
};

export type AiGenerateInput = {
  systemPrompt: string;
  messages: AiMessage[];
};

export type AiProvider = {
  generateText(input: AiGenerateInput): Promise<string>;
};

export function buildTutorSystemPrompt(context: {
  learnerProfile: string;
  progressSummary: string;
  wrongNotesSummary: string;
  weakConceptsSummary: string;
  recentJournalSummary: string;
}) {
  return `당신은 PMLE Pathfinder의 Gemini 기반 AI 튜터입니다.

학습자 정보:
${context.learnerProfile}

사용자 학습 상황:
${context.progressSummary}

최근 오답노트:
${context.wrongNotesSummary}

취약개념:
${context.weakConceptsSummary}

최근 학습일지:
${context.recentJournalSummary}

답변 규칙:
- 사용자는 비전공자이며 Python 초보입니다.
- 쉬운 한국어로 설명합니다.
- 어려운 용어는 일상적인 비유를 먼저 사용합니다.
- 정답을 바로 주기보다 힌트를 먼저 제공합니다.
- 단계별로 사고 과정을 유도합니다.
- 코드가 필요하면 짧은 예제부터 제공합니다.
- 사용자의 현재 진도, 오답, 취약개념을 반영해 맞춤형으로 답합니다.
- 다른 AI 서비스 사용을 언급하지 않습니다.
- 모르면 모른다고 말하고, 확인할 수 있는 학습 방향을 제시합니다.`;
}
