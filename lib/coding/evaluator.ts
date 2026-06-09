import type { CodingEvaluationResult, CodingTask } from "@/lib/types";

export type EvaluateCodingSubmissionInput = {
  task: Pick<CodingTask, "expected_output" | "required_keywords" | "solution_pattern" | "title">;
  code: string;
  userExpectedOutput: string;
};

export function evaluateCodingSubmission({ task, code, userExpectedOutput }: EvaluateCodingSubmissionInput): CodingEvaluationResult {
  const expectedOutputMatched = normalizeOutput(userExpectedOutput) === normalizeOutput(task.expected_output);
  const requiredKeywords = (task.required_keywords ?? []).map((keyword) => ({
    keyword,
    found: code.includes(keyword)
  }));
  const keywordMatched = requiredKeywords.every((item) => item.found);
  const patternMatched = matchSolutionPattern(code, task.solution_pattern);

  const score = calculateScore({
    expectedOutputMatched,
    keywordMatched,
    patternMatched,
    hasKeywords: requiredKeywords.length > 0,
    hasPattern: Boolean(task.solution_pattern)
  });
  const improvements = buildImprovements({ expectedOutputMatched, requiredKeywords, patternMatched, hasPattern: Boolean(task.solution_pattern) });
  const recommendedStudy = buildRecommendedStudy({ expectedOutputMatched, keywordMatched, patternMatched, taskTitle: task.title });

  return {
    passed: expectedOutputMatched && keywordMatched && patternMatched,
    score,
    expectedOutputMatched,
    requiredKeywords,
    patternMatched,
    improvements,
    recommendedStudy
  };
}

function normalizeOutput(value: string) {
  return value
    .replace(/\r\n/g, "\n")
    .split("\n")
    .map((line) => line.trimEnd())
    .join("\n")
    .trim();
}

function matchSolutionPattern(code: string, pattern: string) {
  if (!pattern) return true;

  try {
    return new RegExp(pattern, "s").test(code);
  } catch {
    return false;
  }
}

function calculateScore({
  expectedOutputMatched,
  keywordMatched,
  patternMatched,
  hasKeywords,
  hasPattern
}: {
  expectedOutputMatched: boolean;
  keywordMatched: boolean;
  patternMatched: boolean;
  hasKeywords: boolean;
  hasPattern: boolean;
}) {
  let score = 0;
  if (expectedOutputMatched) score += 40;
  if (!hasKeywords || keywordMatched) score += 30;
  if (!hasPattern || patternMatched) score += 30;
  return score;
}

function buildImprovements({
  expectedOutputMatched,
  requiredKeywords,
  patternMatched,
  hasPattern
}: {
  expectedOutputMatched: boolean;
  requiredKeywords: Array<{ keyword: string; found: boolean }>;
  patternMatched: boolean;
  hasPattern: boolean;
}) {
  const improvements: string[] = [];
  if (!expectedOutputMatched) {
    improvements.push("예상 출력이 과제의 기준 출력과 다릅니다. 코드가 화면에 무엇을 출력할지 먼저 손으로 따라가 보세요.");
  }

  const missingKeywords = requiredKeywords.filter((item) => !item.found).map((item) => item.keyword);
  if (missingKeywords.length > 0) {
    improvements.push(`필수 키워드가 빠졌습니다: ${missingKeywords.join(", ")}`);
  }

  if (hasPattern && !patternMatched) {
    improvements.push("정답 패턴과 코드 구조가 맞지 않습니다. 과제에서 요구한 문법이나 작성 흐름을 다시 확인해 주세요.");
  }

  if (improvements.length === 0) {
    improvements.push("제출 조건을 모두 만족했습니다. 변수명과 출력 형식도 읽기 쉽게 유지해 보세요.");
  }

  return improvements;
}

function buildRecommendedStudy({
  expectedOutputMatched,
  keywordMatched,
  patternMatched,
  taskTitle
}: {
  expectedOutputMatched: boolean;
  keywordMatched: boolean;
  patternMatched: boolean;
  taskTitle: string;
}) {
  const recommended = new Set<string>();
  recommended.add(`${taskTitle} 개념 복습`);
  if (!expectedOutputMatched) recommended.add("print 출력 형식 복습");
  if (!keywordMatched) recommended.add("필수 문법과 키워드 복습");
  if (!patternMatched) recommended.add("예제 코드 구조 다시 작성");
  return Array.from(recommended);
}
