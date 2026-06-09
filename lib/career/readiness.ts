import type { CareerReadinessMetrics } from "@/lib/types";

export function calculatePmleReadiness(metrics: CareerReadinessMetrics) {
  const lessonProgress = ratio(metrics.completedLessons, metrics.totalLessons);
  const gcpProgress = ratio(metrics.gcpCompletedLessons, metrics.gcpTotalLessons);
  const mockScore = clamp(metrics.bestMockExamScore / 100, 0, 1);
  const wrongNotePenalty = clamp(metrics.unresolvedWrongNotes / 20, 0, 1);
  const studyConsistency = clamp(metrics.studyDays / 30, 0, 1);

  return Math.round(
    100 *
      (lessonProgress * 0.28 +
        gcpProgress * 0.22 +
        mockScore * 0.32 +
        studyConsistency * 0.1 +
        (1 - wrongNotePenalty) * 0.08)
  );
}

export function calculateCareerReadiness(metrics: CareerReadinessMetrics) {
  const portfolioDepth = clamp(metrics.completedPortfolioProjects / 3, 0, 1);
  const portfolioStarted = clamp(metrics.portfolioProjects / 3, 0, 1);
  const resumeReadiness = clamp(metrics.resumeBullets / 6, 0, 1);
  const interviewReadiness = clamp(metrics.interviewQuestions / 10, 0, 1);
  const studyMomentum = clamp(metrics.weeklyStudyMinutes / 300, 0, 1);
  const pmleAnchor = calculatePmleReadiness(metrics) / 100;

  return Math.round(100 * (portfolioDepth * 0.3 + portfolioStarted * 0.15 + resumeReadiness * 0.2 + interviewReadiness * 0.15 + studyMomentum * 0.1 + pmleAnchor * 0.1));
}

export function getReadinessLabel(score: number) {
  if (score >= 85) return "준비 완료";
  if (score >= 70) return "거의 준비됨";
  if (score >= 50) return "성장 중";
  return "기초 다지는 중";
}

export function buildWeeklyReport(metrics: CareerReadinessMetrics) {
  return [
    `이번 주 학습시간: ${metrics.weeklyStudyMinutes}분.`,
    `완료한 단원: ${metrics.completedLessons}/${metrics.totalLessons}.`,
    `모의고사 최고 점수: ${metrics.bestMockExamScore.toFixed(1)}%.`,
    `미해결 오답: ${metrics.unresolvedWrongNotes}개.`,
    `완료한 포트폴리오: ${metrics.completedPortfolioProjects}/${metrics.portfolioProjects}개.`
  ];
}

export function buildMonthlyReport(metrics: CareerReadinessMetrics) {
  return [
    `이번 달 학습시간: ${metrics.monthlyStudyMinutes}분, 학습일 ${metrics.studyDays}일.`,
    `PMLE 준비도: ${calculatePmleReadiness(metrics)} (${getReadinessLabel(calculatePmleReadiness(metrics))}).`,
    `커리어 전환 준비도: ${calculateCareerReadiness(metrics)} (${getReadinessLabel(calculateCareerReadiness(metrics))}).`,
    `저장한 이력서 문장: ${metrics.resumeBullets}개.`,
    `저장한 면접 질문: ${metrics.interviewQuestions}개.`
  ];
}

function ratio(numerator: number, denominator: number) {
  if (denominator <= 0) return 0;
  return clamp(numerator / denominator, 0, 1);
}

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}
