"use client";

import { useEffect, useMemo, useState } from "react";
import { BarChart3, CheckCircle2, Clock3, FileQuestion, History, RotateCcw, Timer, XCircle } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { gradeMockExam, pickRandomQuestions, type MockExamSelectionMap } from "@/lib/mock-exams/grading";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { ExamDomainScore, MockExam, MockExamAnswer, MockExamAttempt, MockExamGradingResult, MockExamQuestion } from "@/lib/types";

type ScreenMode = "overview" | "taking" | "analysis";

type MockExamState = {
  exams: MockExam[];
  questions: MockExamQuestion[];
  attempts: MockExamAttempt[];
  analysisAnswers: MockExamAnswer[];
  analysisDomainScores: ExamDomainScore[];
};

export function MockExamsClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<MockExamState>({
    exams: [],
    questions: [],
    attempts: [],
    analysisAnswers: [],
    analysisDomainScores: []
  });
  const [selectedExamId, setSelectedExamId] = useState("");
  const [selectedAttemptId, setSelectedAttemptId] = useState("");
  const [activeQuestions, setActiveQuestions] = useState<MockExamQuestion[]>([]);
  const [selections, setSelections] = useState<MockExamSelectionMap>({});
  const [currentIndex, setCurrentIndex] = useState(0);
  const [startedAt, setStartedAt] = useState<Date | null>(null);
  const [remainingSeconds, setRemainingSeconds] = useState(0);
  const [screenMode, setScreenMode] = useState<ScreenMode>("overview");
  const [latestResult, setLatestResult] = useState<MockExamGradingResult | null>(null);
  const [loadingData, setLoadingData] = useState(true);
  const [dataError, setDataError] = useState("");
  const [message, setMessage] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;

    async function loadMockExams() {
      setLoadingData(true);
      setDataError("");

      const examsResult = await supabase.from("mock_exams").select("*").eq("is_active", true).order("sort_order", { ascending: true });
      if (examsResult.error) {
        setDataError(examsResult.error.message);
        setLoadingData(false);
        return;
      }

      const exams = (examsResult.data ?? []) as MockExam[];
      const examIds = exams.map((exam) => exam.id);
      const [questionsResult, attemptsResult] = await Promise.all([
        examIds.length ? supabase.from("mock_exam_questions").select("*").in("mock_exam_id", examIds).order("sort_order", { ascending: true }) : Promise.resolve({ data: [], error: null }),
        supabase.from("mock_exam_attempts").select("*").eq("user_id", currentUser.id).order("created_at", { ascending: false })
      ]);

      const firstError = questionsResult.error || attemptsResult.error;
      if (firstError) {
        setDataError(firstError.message);
        setLoadingData(false);
        return;
      }

      const attempts = (attemptsResult.data ?? []) as MockExamAttempt[];
      setState((current) => ({
        ...current,
        exams,
        questions: normalizeQuestions((questionsResult.data ?? []) as MockExamQuestion[]),
        attempts
      }));
      setSelectedExamId((current) => current || exams[0]?.id || "");
      setSelectedAttemptId((current) => current || attempts[0]?.id || "");
      setLoadingData(false);
    }

    loadMockExams();
  }, [client, user]);

  useEffect(() => {
    if (!client || !user || !selectedAttemptId) {
      setState((current) => ({ ...current, analysisAnswers: [], analysisDomainScores: [] }));
      return;
    }

    const supabase = client;
    const currentUser = user;

    async function loadAttemptAnalysis() {
      const [answersResult, scoresResult] = await Promise.all([
        supabase.from("mock_exam_answers").select("*").eq("user_id", currentUser.id).eq("attempt_id", selectedAttemptId).order("created_at", { ascending: true }),
        supabase.from("exam_domain_scores").select("*").eq("user_id", currentUser.id).eq("attempt_id", selectedAttemptId).order("score_percent", { ascending: true })
      ]);

      const firstError = answersResult.error || scoresResult.error;
      if (firstError) {
        setDataError(firstError.message);
        return;
      }

      setState((current) => ({
        ...current,
        analysisAnswers: normalizeStoredAnswers((answersResult.data ?? []) as MockExamAnswer[]),
        analysisDomainScores: (scoresResult.data ?? []) as ExamDomainScore[]
      }));
    }

    loadAttemptAnalysis();
  }, [client, selectedAttemptId, user]);

  useEffect(() => {
    if (screenMode !== "taking" || !startedAt || !selectedExam) return;

    const deadline = startedAt.getTime() + selectedExam.duration_minutes * 60 * 1000;
    const tick = () => {
      const secondsLeft = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
      setRemainingSeconds(secondsLeft);
    };

    tick();
    const intervalId = window.setInterval(tick, 1000);
    return () => window.clearInterval(intervalId);
  }, [screenMode, startedAt]);

  useEffect(() => {
    if (screenMode === "taking" && remainingSeconds === 0 && startedAt && !submitting && activeQuestions.length > 0) {
      submitExam("timed_out");
    }
    // submitExam reads the current exam state and should run only when the timer reaches zero.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [remainingSeconds, screenMode, startedAt, submitting, activeQuestions.length]);

  const selectedExam = useMemo(() => state.exams.find((exam) => exam.id === selectedExamId) ?? null, [selectedExamId, state.exams]);
  const selectedAttempt = useMemo(() => state.attempts.find((attempt) => attempt.id === selectedAttemptId) ?? null, [selectedAttemptId, state.attempts]);
  const selectedExamQuestions = useMemo(() => state.questions.filter((question) => question.mock_exam_id === selectedExamId), [selectedExamId, state.questions]);
  const currentQuestion = activeQuestions[currentIndex];
  const answeredCount = Object.values(selections).filter((value) => typeof value === "number").length;
  const latestAttempt = state.attempts[0];
  const bestScore = state.attempts.reduce((best, attempt) => Math.max(best, Number(attempt.score_percent)), 0);
  const weakDomain = state.analysisDomainScores[0]?.domain_title ?? "데이터 없음";

  function startExam() {
    if (!selectedExam) return;
    const pickedQuestions = pickRandomQuestions(selectedExamQuestions, selectedExam.question_count);
    if (pickedQuestions.length === 0) {
      setMessage("모의고사 문항을 찾지 못했습니다. MVP7 마이그레이션을 먼저 실행해 주세요.");
      return;
    }

    setActiveQuestions(pickedQuestions);
    setSelections({});
    setCurrentIndex(0);
    setStartedAt(new Date());
    setRemainingSeconds(selectedExam.duration_minutes * 60);
    setLatestResult(null);
    setSelectedAttemptId("");
    setMessage("");
    setScreenMode("taking");
  }

  async function submitExam(status: "completed" | "timed_out" = "completed") {
    if (!client || !user || !selectedExam || !startedAt || activeQuestions.length === 0 || submitting) return;
    setSubmitting(true);
    setMessage("");

    const submittedAt = new Date();
    const graded = gradeMockExam({
      questions: activeQuestions,
      selections,
      passingScore: selectedExam.passing_score,
      startedAt,
      submittedAt,
      status
    });

    const attemptResult = await client
      .from("mock_exam_attempts")
      .insert({
        user_id: user.id,
        mock_exam_id: selectedExam.id,
        started_at: startedAt.toISOString(),
        submitted_at: submittedAt.toISOString(),
        duration_seconds: graded.durationSeconds,
        total_questions: graded.totalQuestions,
        answered_count: graded.answeredCount,
        correct_count: graded.correctCount,
        score_percent: graded.scorePercent,
        status: graded.status
      })
      .select("*")
      .single();

    if (attemptResult.error || !attemptResult.data) {
      setMessage(attemptResult.error?.message ?? "모의고사 응시 기록 저장에 실패했습니다.");
      setSubmitting(false);
      return;
    }

    const attempt = attemptResult.data as MockExamAttempt;
    const answerRows = graded.answers.map((answer) => ({
      attempt_id: attempt.id,
      user_id: user.id,
      question_id: answer.question.id,
      domain_title: answer.question.domain_title || "Uncategorized",
      question_snapshot: answer.question.question,
      scenario_snapshot: answer.question.scenario,
      options_snapshot: answer.question.options,
      explanation_snapshot: answer.question.explanation,
      selected_option_index: answer.selectedOptionIndex,
      correct_option_index: answer.question.correct_option_index,
      is_correct: answer.isCorrect,
      answered_at: answer.selectedOptionIndex === null ? null : submittedAt.toISOString()
    }));

    const scoreRows = graded.domainScores.map((score) => ({
      attempt_id: attempt.id,
      user_id: user.id,
      domain_title: score.domainTitle,
      total_questions: score.totalQuestions,
      answered_count: score.answeredCount,
      correct_count: score.correctCount,
      score_percent: score.scorePercent
    }));

    const [answersResult, scoresResult] = await Promise.all([client.from("mock_exam_answers").insert(answerRows), client.from("exam_domain_scores").insert(scoreRows)]);
    const firstError = answersResult.error || scoresResult.error;
    if (firstError) {
      setMessage(firstError.message);
      setSubmitting(false);
      return;
    }

    await reloadAttempts(attempt.id);
    setLatestResult(graded);
    setSelectedAttemptId(attempt.id);
    setScreenMode("analysis");
    setSubmitting(false);
  }

  async function reloadAttempts(nextSelectedAttemptId?: string) {
    if (!client || !user) return;
    const attemptsResult = await client.from("mock_exam_attempts").select("*").eq("user_id", user.id).order("created_at", { ascending: false });
    if (attemptsResult.error) {
      setDataError(attemptsResult.error.message);
      return;
    }
    setState((current) => ({ ...current, attempts: (attemptsResult.data ?? []) as MockExamAttempt[] }));
    if (nextSelectedAttemptId) setSelectedAttemptId(nextSelectedAttemptId);
  }

  function selectAnswer(questionId: string, optionIndex: number) {
    setSelections((current) => ({ ...current, [questionId]: optionIndex }));
  }

  function viewAttempt(attemptId: string) {
    setSelectedAttemptId(attemptId);
    setLatestResult(null);
    setScreenMode("analysis");
  }

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="모의고사를 불러오는 중입니다..." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : state.exams.length === 0 ? (
        <ErrorPanel message="모의고사 데이터를 찾지 못했습니다. MVP7 Supabase 마이그레이션을 먼저 실행해 주세요." />
      ) : (
        <div className="grid gap-5">
          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <div className="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">PMLE 모의고사</p>
                <h1 className="mt-1 text-2xl font-black">시험 모드와 점수 분석</h1>
                <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
                  제한 시간 안에 랜덤 문항을 풀고, 응시 기록과 영역별 취약점을 확인한 뒤 다시 시험을 볼 수 있습니다.
                </p>
              </div>
              <div className="flex flex-wrap gap-2">
                <button onClick={() => setScreenMode("overview")} className={modeButton(screenMode === "overview")}>개요</button>
                <button onClick={startExam} className="inline-flex h-10 items-center gap-2 rounded-md bg-brand px-4 text-sm font-black text-white">
                  <Timer size={16} /> 시험 시작
                </button>
              </div>
            </div>
          </section>

          {screenMode === "taking" && currentQuestion && selectedExam ? (
            <ExamMode
              exam={selectedExam}
              questions={activeQuestions}
              currentQuestion={currentQuestion}
              currentIndex={currentIndex}
              remainingSeconds={remainingSeconds}
              selections={selections}
              answeredCount={answeredCount}
              submitting={submitting}
              onSelectAnswer={selectAnswer}
              onChangeQuestion={setCurrentIndex}
              onSubmit={() => submitExam("completed")}
            />
          ) : screenMode === "analysis" && selectedAttempt ? (
            <AnalysisMode
              attempt={selectedAttempt}
              result={latestResult}
              answers={state.analysisAnswers}
              domainScores={state.analysisDomainScores}
              passingScore={selectedExam?.passing_score ?? 70}
              onRetake={startExam}
            />
          ) : (
            <OverviewMode
              exams={state.exams}
              selectedExamId={selectedExamId}
              questions={selectedExamQuestions}
              attempts={state.attempts}
              latestAttempt={latestAttempt}
              bestScore={bestScore}
              weakDomain={weakDomain}
              message={message}
              onSelectExam={setSelectedExamId}
              onStart={startExam}
              onViewAttempt={viewAttempt}
            />
          )}
        </div>
      )}
    </AppShell>
  );
}

function OverviewMode({
  exams,
  selectedExamId,
  questions,
  attempts,
  latestAttempt,
  bestScore,
  weakDomain,
  message,
  onSelectExam,
  onStart,
  onViewAttempt
}: {
  exams: MockExam[];
  selectedExamId: string;
  questions: MockExamQuestion[];
  attempts: MockExamAttempt[];
  latestAttempt: MockExamAttempt | undefined;
  bestScore: number;
  weakDomain: string;
  message: string;
  onSelectExam: (examId: string) => void;
  onStart: () => void;
  onViewAttempt: (attemptId: string) => void;
}) {
  const selectedExam = exams.find((exam) => exam.id === selectedExamId) ?? exams[0];
  return (
    <div className="grid gap-5">
      <section className="grid gap-3 md:grid-cols-4">
        <Metric label="최근 점수" value={latestAttempt ? `${Number(latestAttempt.score_percent).toFixed(1)}%` : "데이터 없음"} icon={BarChart3} />
        <Metric label="최고 점수" value={`${bestScore.toFixed(1)}%`} icon={CheckCircle2} />
        <Metric label="응시 횟수" value={`${attempts.length}`} icon={History} />
        <Metric label="가장 약한 영역" value={weakDomain} icon={FileQuestion} compact />
      </section>

      <section className="grid gap-5 lg:grid-cols-[0.95fr_1.05fr]">
        <Panel title="시험 모드">
          <div className="grid gap-3">
            {exams.map((exam) => (
              <button
                key={exam.id}
                onClick={() => onSelectExam(exam.id)}
                className={clsx("rounded-md border p-4 text-left", selectedExamId === exam.id ? "border-brand bg-blue-50" : "border-line bg-white hover:border-brand")}
              >
                <p className="font-black">{exam.title}</p>
                <p className="mt-1 text-sm leading-6 text-slate-600">{exam.description}</p>
                <div className="mt-3 flex flex-wrap gap-2 text-xs font-black text-slate-600">
                  <span className="rounded-full bg-white px-2 py-1">랜덤 {exam.question_count}문항</span>
                  <span className="rounded-full bg-white px-2 py-1">{exam.duration_minutes}분</span>
                  <span className="rounded-full bg-white px-2 py-1">합격 {exam.passing_score}%</span>
                </div>
              </button>
            ))}
          </div>
          <button onClick={onStart} className="mt-4 inline-flex h-10 w-full items-center justify-center gap-2 rounded-md bg-brand px-4 text-sm font-black text-white">
            <Timer size={16} /> 제한시간 시험 시작
          </button>
          {message && <p className="mt-3 rounded-md bg-amber-50 p-3 text-sm font-bold text-amber-800">{message}</p>}
        </Panel>

        <Panel title="시험 이력">
          {attempts.slice(0, 8).map((attempt) => (
            <article key={attempt.id} className="rounded-md border border-line p-4">
              <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div>
                  <p className="font-black">{selectedExam?.title ?? "모의고사"}</p>
                  <p className="mt-1 text-sm text-slate-600">
                    {formatDate(attempt.submitted_at ?? attempt.created_at)} / 정답 {attempt.correct_count}/{attempt.total_questions} / {formatDuration(attempt.duration_seconds)}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={clsx("rounded-full px-3 py-1 text-sm font-black", Number(attempt.score_percent) >= (selectedExam?.passing_score ?? 70) ? "bg-emerald-50 text-emerald-800" : "bg-red-50 text-danger")}>
                    {Number(attempt.score_percent).toFixed(1)}%
                  </span>
                  <button onClick={() => onViewAttempt(attempt.id)} className="h-9 rounded-md border border-line px-3 text-sm font-black">
                    분석 보기
                  </button>
                </div>
              </div>
            </article>
          ))}
          {attempts.length === 0 && <Empty label="아직 응시 기록이 없습니다. 첫 모의고사를 시작해 주세요." />}
          <p className="rounded-md bg-slate-50 p-3 text-sm font-semibold text-slate-600">선택한 모의고사에 {questions.length}개 문항이 준비되어 있습니다.</p>
        </Panel>
      </section>
    </div>
  );
}

function ExamMode({
  exam,
  questions,
  currentQuestion,
  currentIndex,
  remainingSeconds,
  selections,
  answeredCount,
  submitting,
  onSelectAnswer,
  onChangeQuestion,
  onSubmit
}: {
  exam: MockExam;
  questions: MockExamQuestion[];
  currentQuestion: MockExamQuestion;
  currentIndex: number;
  remainingSeconds: number;
  selections: MockExamSelectionMap;
  answeredCount: number;
  submitting: boolean;
  onSelectAnswer: (questionId: string, optionIndex: number) => void;
  onChangeQuestion: (index: number) => void;
  onSubmit: () => void;
}) {
  return (
    <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_320px]">
      <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
        <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
          <div>
            <p className="text-sm font-black text-brand">{exam.title}</p>
            <h2 className="mt-1 text-xl font-black">
              {questions.length}문항 중 {currentIndex + 1}번
            </h2>
          </div>
          <span className={clsx("inline-flex w-fit items-center gap-2 rounded-full px-3 py-1 text-sm font-black", remainingSeconds <= 60 ? "bg-red-50 text-danger" : "bg-slate-50 text-slate-700")}>
            <Clock3 size={16} /> {formatTimer(remainingSeconds)}
          </span>
        </div>

        <div className="mt-5 rounded-md bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-[0.12em] text-slate-500">{currentQuestion.domain_title}</p>
          <h3 className="mt-2 text-lg font-black">{currentQuestion.question}</h3>
          {currentQuestion.scenario && <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-slate-700">{currentQuestion.scenario}</p>}
        </div>

        <div className="mt-5 grid gap-3">
          {currentQuestion.options.map((option, index) => {
            const selected = selections[currentQuestion.id] === index;
            return (
              <button
                key={option}
                onClick={() => onSelectAnswer(currentQuestion.id, index)}
                className={clsx(
                  "min-h-12 rounded-md border px-4 py-3 text-left text-sm font-semibold transition",
                  selected ? "border-brand bg-blue-50 text-ink" : "border-line bg-white hover:border-brand"
                )}
              >
                {option}
              </button>
            );
          })}
        </div>

        <div className="mt-5 flex flex-wrap justify-between gap-2">
          <button onClick={() => onChangeQuestion(Math.max(0, currentIndex - 1))} disabled={currentIndex === 0} className="h-10 rounded-md border border-line px-4 text-sm font-black disabled:opacity-40">
            이전
          </button>
          <button
            onClick={() => onChangeQuestion(Math.min(questions.length - 1, currentIndex + 1))}
            disabled={currentIndex === questions.length - 1}
            className="h-10 rounded-md border border-line px-4 text-sm font-black disabled:opacity-40"
          >
            다음
          </button>
        </div>
      </section>

      <aside className="grid h-fit gap-5 lg:sticky lg:top-5">
        <Panel title="타이머">
          <p className={clsx("text-4xl font-black", remainingSeconds <= 60 ? "text-danger" : "text-ink")}>{formatTimer(remainingSeconds)}</p>
          <p className="mt-2 text-sm font-semibold text-slate-600">
            답변 완료 {answeredCount}/{questions.length}
          </p>
          <button onClick={onSubmit} disabled={submitting} className="mt-4 inline-flex h-10 w-full items-center justify-center gap-2 rounded-md bg-ink px-4 text-sm font-black text-white disabled:bg-slate-400">
            <CheckCircle2 size={16} /> {submitting ? "제출 중..." : "시험 제출"}
          </button>
        </Panel>

        <Panel title="문항 목록">
          <div className="grid grid-cols-5 gap-2">
            {questions.map((question, index) => (
              <button
                key={question.id}
                onClick={() => onChangeQuestion(index)}
                className={clsx(
                  "h-10 rounded-md border text-sm font-black",
                  index === currentIndex && "border-ink bg-ink text-white",
                  index !== currentIndex && typeof selections[question.id] === "number" && "border-emerald-300 bg-emerald-50 text-emerald-800",
                  index !== currentIndex && typeof selections[question.id] !== "number" && "border-line bg-white text-slate-600"
                )}
              >
                {index + 1}
              </button>
            ))}
          </div>
        </Panel>
      </aside>
    </div>
  );
}

function AnalysisMode({
  attempt,
  result,
  answers,
  domainScores,
  passingScore,
  onRetake
}: {
  attempt: MockExamAttempt;
  result: MockExamGradingResult | null;
  answers: MockExamAnswer[];
  domainScores: ExamDomainScore[];
  passingScore: number;
  onRetake: () => void;
}) {
  const scorePercent = result?.scorePercent ?? Number(attempt.score_percent);
  const correctCount = result?.correctCount ?? attempt.correct_count;
  const totalQuestions = result?.totalQuestions ?? attempt.total_questions;
  const answeredCount = result?.answeredCount ?? attempt.answered_count;
  const unansweredCount = result?.unansweredCount ?? Math.max(0, attempt.total_questions - attempt.answered_count);
  const passed = scorePercent >= passingScore;
  const wrongAnswers = answers.filter((answer) => !answer.is_correct);

  return (
    <div className="grid gap-5">
      <section className="grid gap-3 md:grid-cols-4">
        <Metric label="점수" value={`${scorePercent.toFixed(1)}%`} icon={BarChart3} />
        <Metric label="정답" value={`${correctCount}/${totalQuestions}`} icon={CheckCircle2} />
        <Metric label="미답변" value={`${unansweredCount}`} icon={FileQuestion} />
        <Metric label="사용 시간" value={formatDuration(attempt.duration_seconds)} icon={Clock3} />
      </section>

      <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <p className={clsx("inline-flex rounded-full px-3 py-1 text-sm font-black", passed ? "bg-emerald-50 text-emerald-800" : "bg-red-50 text-danger")}>{passed ? "합격권" : "재시험 필요"}</p>
            <h2 className="mt-3 text-xl font-black">점수 분석</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              {totalQuestions}문항 중 {answeredCount}문항에 답했습니다. 합격 기준은 {passingScore}%입니다.
            </p>
          </div>
          <button onClick={onRetake} className="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-brand px-4 text-sm font-black text-white">
            <RotateCcw size={16} /> 다시 응시
          </button>
        </div>
      </section>

      <section className="grid gap-5 lg:grid-cols-[0.8fr_1.2fr]">
        <Panel title="영역별 분석">
          {(domainScores.length > 0 ? domainScores : result?.domainScores ?? []).map((score) => {
            const domainTitle = "domainTitle" in score ? score.domainTitle : score.domain_title;
            const total = "totalQuestions" in score ? score.totalQuestions : score.total_questions;
            const correct = "correctCount" in score ? score.correctCount : score.correct_count;
            const percent = "scorePercent" in score ? score.scorePercent : Number(score.score_percent);
            return (
              <div key={domainTitle} className="rounded-md border border-line p-4">
                <div className="flex items-center justify-between gap-3">
                  <p className="font-black">{domainTitle}</p>
                  <span className={clsx("rounded-full px-2 py-1 text-xs font-black", percent >= passingScore ? "bg-emerald-50 text-emerald-800" : "bg-red-50 text-danger")}>{percent.toFixed(1)}%</span>
                </div>
                <div className="mt-3 h-2 overflow-hidden rounded-full bg-slate-100">
                  <div className={clsx("h-full", percent >= passingScore ? "bg-emerald-500" : "bg-red-500")} style={{ width: `${Math.min(100, Math.max(0, percent))}%` }} />
                </div>
                <p className="mt-2 text-sm text-slate-600">
                  정답 {correct}/{total}
                </p>
              </div>
            );
          })}
        </Panel>

        <Panel title="저장된 오답">
          {wrongAnswers.map((answer) => {
            const selected = answer.selected_option_index === null ? "답변 없음" : answer.options_snapshot[answer.selected_option_index] ?? "알 수 없는 선택지";
            const correct = answer.options_snapshot[answer.correct_option_index] ?? "알 수 없는 선택지";
            return (
              <article key={answer.id} className="rounded-md border border-line p-4">
                <div className="inline-flex items-center gap-2 rounded-full bg-red-50 px-2 py-1 text-xs font-black text-danger">
                  <XCircle size={14} /> {answer.domain_title}
                </div>
                <h3 className="mt-3 font-black">{answer.question_snapshot}</h3>
                {answer.scenario_snapshot && <p className="mt-2 text-sm leading-6 text-slate-600">{answer.scenario_snapshot}</p>}
                <div className="mt-3 grid gap-3 md:grid-cols-2">
                  <AnswerBox label="내 답변" value={selected} tone="wrong" />
                  <AnswerBox label="정답" value={correct} tone="correct" />
                </div>
                <p className="mt-3 rounded-md bg-slate-50 p-3 text-sm leading-6 text-slate-700">{answer.explanation_snapshot}</p>
              </article>
            );
          })}
          {wrongAnswers.length === 0 && <Empty label="이번 응시에서 저장된 오답이 없습니다." />}
        </Panel>
      </section>
    </div>
  );
}

function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <h2 className="text-lg font-black">{title}</h2>
      <div className="mt-4 grid gap-3">{children}</div>
    </section>
  );
}

function Metric({ label, value, icon: Icon, compact = false }: { label: string; value: string; icon: React.ComponentType<{ size?: number; className?: string }>; compact?: boolean }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm font-bold text-slate-600">{label}</p>
        <Icon size={18} className="text-brand" />
      </div>
      <p className={clsx("mt-3 font-black", compact ? "text-lg leading-6" : "text-3xl")}>{value}</p>
    </div>
  );
}

function AnswerBox({ label, value, tone }: { label: string; value: string; tone: "wrong" | "correct" }) {
  return (
    <div className={clsx("rounded-md border p-4", tone === "wrong" ? "border-red-200 bg-red-50" : "border-emerald-200 bg-emerald-50")}>
      <p className="text-xs font-black text-slate-600">{label}</p>
      <p className={clsx("mt-2 text-sm font-bold leading-6", tone === "wrong" ? "text-danger" : "text-emerald-800")}>{value}</p>
    </div>
  );
}

function Empty({ label }: { label: string }) {
  return <p className="rounded-md bg-slate-50 p-4 text-sm font-semibold text-slate-500">{label}</p>;
}

function modeButton(active: boolean) {
  return clsx("inline-flex h-10 items-center rounded-md border px-4 text-sm font-black", active ? "border-ink bg-ink text-white" : "border-line bg-white text-slate-700");
}

function normalizeQuestions(rows: MockExamQuestion[]) {
  return rows.map((row) => ({
    ...row,
    options: Array.isArray(row.options) ? row.options : []
  }));
}

function normalizeStoredAnswers(rows: MockExamAnswer[]) {
  return rows.map((row) => ({
    ...row,
    options_snapshot: Array.isArray(row.options_snapshot) ? row.options_snapshot : []
  }));
}

function formatTimer(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

function formatDuration(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  if (minutes === 0) return `${seconds}초`;
  return `${minutes}분 ${seconds}초`;
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("ko-KR", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  }).format(new Date(value));
}
