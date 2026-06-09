export type Module = {
  id: string;
  title: string;
  description: string;
  sort_order: number;
};

export type Lesson = {
  id: string;
  module_id: string;
  slug: string;
  title: string;
  objective: string;
  concept: string;
  example_code: string;
  summary: string;
  sort_order: number;
};

export type Quiz = {
  id: string;
  lesson_id: string;
  question: string;
  explanation: string;
  sort_order: number;
};

export type QuizOption = {
  id: string;
  quiz_id: string;
  option_text: string;
  is_correct: boolean;
  sort_order: number;
};

export type UserProgress = {
  id: string;
  user_id: string;
  lesson_id: string;
  status: "not_started" | "in_progress" | "completed";
  completed: boolean;
  started_at: string | null;
  completed_at: string | null;
  last_viewed_at: string | null;
  updated_at: string;
};

export type LearningJournal = {
  id: string;
  user_id: string;
  lesson_id: string | null;
  journal_date: string;
  study_minutes: number;
  understanding_score: number;
  content: string;
  created_at: string;
  updated_at: string;
};

export type ConceptMastery = {
  id: string;
  user_id: string;
  lesson_id: string;
  concept_name: string;
  mastery_score: number;
  is_weak: boolean;
  note: string;
  last_reviewed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type ReviewSchedule = {
  id: string;
  user_id: string;
  lesson_id: string;
  review_step: 1 | 3 | 7 | 14;
  due_date: string;
  completed: boolean;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type CodingTask = {
  id: string;
  lesson_id: string | null;
  title: string;
  description: string;
  instructions: string;
  starter_code: string;
  expected_output: string;
  required_keywords: string[];
  solution_pattern: string;
  difficulty: "easy" | "medium" | "hard";
  sort_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type CodingSubmission = {
  id: string;
  user_id: string;
  task_id: string;
  code: string;
  user_expected_output: string;
  evaluation_result: CodingEvaluationResult;
  score: number;
  status: "passed" | "needs_retry";
  attempt_number: number;
  created_at: string;
};

export type CodingFeedback = {
  id: string;
  user_id: string;
  task_id: string;
  submission_id: string;
  improvements: string[];
  recommended_study: string[];
  feedback: string;
  ai_feedback: string;
  created_at: string;
};

export type MlConceptMapItem = {
  id: string;
  source_concept: string;
  target_concept: string;
  relation: string;
  description: string;
  sort_order: number;
  created_at: string;
};

export type ExamDomain = {
  id: string;
  title: string;
  description: string;
  weight_percent: number | null;
  exam_points: string[];
  practical_points: string[];
  sort_order: number;
  created_at: string;
};

export type ServiceComparison = {
  id: string;
  service_name: string;
  category: string;
  best_for: string;
  avoid_when: string;
  exam_point: string;
  practical_point: string;
  sort_order: number;
  created_at: string;
};

export type ScenarioQuestion = {
  id: string;
  lesson_id: string | null;
  title: string;
  scenario: string;
  options: string[];
  correct_option_index: number;
  explanation: string;
  exam_point: string;
  practical_point: string;
  difficulty: "easy" | "medium" | "hard";
  sort_order: number;
  created_at: string;
};

export type MockExam = {
  id: string;
  title: string;
  description: string;
  duration_minutes: number;
  question_count: number;
  passing_score: number;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
};

export type MockExamQuestion = {
  id: string;
  mock_exam_id: string;
  exam_domain_id: string | null;
  domain_title: string;
  question: string;
  scenario: string;
  options: string[];
  correct_option_index: number;
  explanation: string;
  difficulty: "easy" | "medium" | "hard";
  sort_order: number;
  created_at: string;
};

export type MockExamAttempt = {
  id: string;
  user_id: string;
  mock_exam_id: string;
  started_at: string;
  submitted_at: string | null;
  duration_seconds: number;
  total_questions: number;
  answered_count: number;
  correct_count: number;
  score_percent: number;
  status: "in_progress" | "completed" | "timed_out";
  created_at: string;
};

export type MockExamAnswer = {
  id: string;
  attempt_id: string;
  user_id: string;
  question_id: string | null;
  domain_title: string;
  question_snapshot: string;
  scenario_snapshot: string;
  options_snapshot: string[];
  explanation_snapshot: string;
  selected_option_index: number | null;
  correct_option_index: number;
  is_correct: boolean;
  answered_at: string | null;
  created_at: string;
};

export type ExamDomainScore = {
  id: string;
  attempt_id: string;
  user_id: string;
  domain_title: string;
  total_questions: number;
  answered_count: number;
  correct_count: number;
  score_percent: number;
  created_at: string;
};

export type MockExamGradedAnswer = {
  question: MockExamQuestion;
  selectedOptionIndex: number | null;
  isCorrect: boolean;
};

export type MockExamDomainResult = {
  domainTitle: string;
  totalQuestions: number;
  answeredCount: number;
  correctCount: number;
  scorePercent: number;
};

export type MockExamGradingResult = {
  totalQuestions: number;
  answeredCount: number;
  correctCount: number;
  incorrectCount: number;
  unansweredCount: number;
  scorePercent: number;
  passed: boolean;
  durationSeconds: number;
  status: "completed" | "timed_out";
  answers: MockExamGradedAnswer[];
  domainScores: MockExamDomainResult[];
};

export type PortfolioProject = {
  id: string;
  user_id: string;
  title: string;
  summary: string;
  role: string;
  target_domain: string;
  tech_stack: string[];
  problem: string;
  solution: string;
  result: string;
  github_url: string;
  demo_url: string;
  readme_content: string;
  status: "planned" | "building" | "completed";
  target_date: string | null;
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type ProjectStep = {
  id: string;
  user_id: string;
  project_id: string;
  title: string;
  description: string;
  status: "todo" | "doing" | "done";
  sort_order: number;
  due_date: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
};

export type ResumeBullet = {
  id: string;
  user_id: string;
  project_id: string | null;
  content: string;
  role_focus: string;
  source: "template" | "gemini";
  created_at: string;
  updated_at: string;
};

export type InterviewQuestion = {
  id: string;
  user_id: string;
  project_id: string | null;
  question: string;
  suggested_answer: string;
  category: "technical" | "project" | "behavioral" | "pmle";
  difficulty: "easy" | "medium" | "hard";
  source: "template" | "gemini";
  created_at: string;
  updated_at: string;
};

export type CareerReadinessMetrics = {
  completedLessons: number;
  totalLessons: number;
  gcpCompletedLessons: number;
  gcpTotalLessons: number;
  bestMockExamScore: number;
  unresolvedWrongNotes: number;
  portfolioProjects: number;
  completedPortfolioProjects: number;
  resumeBullets: number;
  interviewQuestions: number;
  totalStudyMinutes: number;
  weeklyStudyMinutes: number;
  monthlyStudyMinutes: number;
  studyDays: number;
  dDay: number | null;
};

export type CodingEvaluationResult = {
  passed: boolean;
  score: number;
  expectedOutputMatched: boolean;
  requiredKeywords: Array<{
    keyword: string;
    found: boolean;
  }>;
  patternMatched: boolean;
  improvements: string[];
  recommendedStudy: string[];
};

export type LearningNote = {
  id: string;
  user_id: string;
  lesson_id: string;
  content: string;
  created_at: string;
  updated_at: string;
};

export type WrongNote = {
  id: string;
  user_id: string;
  quiz_id: string;
  selected_option_id: string | null;
  correct_option_id: string | null;
  question_snapshot: string;
  explanation_snapshot: string;
  attempt_count: number;
  resolved: boolean;
  resolved_at: string | null;
  created_at: string;
  updated_at: string;
};

export type QuizWithOptions = Quiz & {
  options: QuizOption[];
};

export type LessonStatus = "not_started" | "in_progress" | "completed";
