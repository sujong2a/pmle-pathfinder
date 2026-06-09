import type { MockExamGradingResult, MockExamQuestion } from "@/lib/types";

export type MockExamSelectionMap = Record<string, number | undefined>;

export function pickRandomQuestions(questions: MockExamQuestion[], count: number) {
  return shuffleArray(questions).slice(0, Math.max(0, Math.min(count, questions.length)));
}

export function gradeMockExam(params: {
  questions: MockExamQuestion[];
  selections: MockExamSelectionMap;
  passingScore: number;
  startedAt: Date;
  submittedAt: Date;
  status: "completed" | "timed_out";
}): MockExamGradingResult {
  const answers = params.questions.map((question) => {
    const selectedOptionIndex = normalizeSelectedIndex(params.selections[question.id], question.options.length);
    return {
      question,
      selectedOptionIndex,
      isCorrect: selectedOptionIndex !== null && selectedOptionIndex === question.correct_option_index
    };
  });

  const totalQuestions = answers.length;
  const answeredCount = answers.filter((answer) => answer.selectedOptionIndex !== null).length;
  const correctCount = answers.filter((answer) => answer.isCorrect).length;
  const scorePercent = percent(correctCount, totalQuestions);
  const durationSeconds = Math.max(0, Math.round((params.submittedAt.getTime() - params.startedAt.getTime()) / 1000));

  return {
    totalQuestions,
    answeredCount,
    correctCount,
    incorrectCount: totalQuestions - correctCount,
    unansweredCount: totalQuestions - answeredCount,
    scorePercent,
    passed: scorePercent >= params.passingScore,
    durationSeconds,
    status: params.status,
    answers,
    domainScores: buildDomainScores(answers)
  };
}

function buildDomainScores(answers: MockExamGradingResult["answers"]) {
  const grouped = new Map<string, { total: number; answered: number; correct: number }>();

  for (const answer of answers) {
    const domainTitle = answer.question.domain_title || "Uncategorized";
    const current = grouped.get(domainTitle) ?? { total: 0, answered: 0, correct: 0 };
    current.total += 1;
    if (answer.selectedOptionIndex !== null) current.answered += 1;
    if (answer.isCorrect) current.correct += 1;
    grouped.set(domainTitle, current);
  }

  return [...grouped.entries()]
    .map(([domainTitle, score]) => ({
      domainTitle,
      totalQuestions: score.total,
      answeredCount: score.answered,
      correctCount: score.correct,
      scorePercent: percent(score.correct, score.total)
    }))
    .sort((left, right) => left.scorePercent - right.scorePercent || left.domainTitle.localeCompare(right.domainTitle));
}

function normalizeSelectedIndex(value: number | undefined, optionCount: number) {
  if (typeof value !== "number") return null;
  if (!Number.isInteger(value)) return null;
  if (value < 0 || value >= optionCount) return null;
  return value;
}

function percent(numerator: number, denominator: number) {
  if (denominator <= 0) return 0;
  return Math.round((numerator / denominator) * 1000) / 10;
}

function shuffleArray<T>(items: T[]) {
  const next = [...items];
  for (let index = next.length - 1; index > 0; index -= 1) {
    const randomIndex = Math.floor(Math.random() * (index + 1));
    [next[index], next[randomIndex]] = [next[randomIndex], next[index]];
  }
  return next;
}
