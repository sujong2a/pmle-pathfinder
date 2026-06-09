"use client";

import { useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import Link from "next/link";
import { ArrowLeft, CheckCircle2, NotebookPen, RotateCcw, Save, XCircle } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { ConceptMastery, LearningNote, Lesson, QuizOption, QuizWithOptions, UserProgress, WrongNote } from "@/lib/types";

type LessonClientProps = {
  lessonId: string;
};

type ResultByQuiz = Record<string, boolean>;
type SelectionByQuiz = Record<string, string>;

const reviewSteps = [1, 3, 7, 14] as const;

export function LessonClient({ lessonId }: LessonClientProps) {
  const { client, user, loading, error } = useRequiredUser();
  const [lesson, setLesson] = useState<Lesson | null>(null);
  const [quizzes, setQuizzes] = useState<QuizWithOptions[]>([]);
  const [progress, setProgress] = useState<UserProgress | null>(null);
  const [note, setNote] = useState("");
  const [journalContent, setJournalContent] = useState("");
  const [studyMinutes, setStudyMinutes] = useState("30");
  const [understandingScore, setUnderstandingScore] = useState("70");
  const [masteryScore, setMasteryScore] = useState("70");
  const [masteryNote, setMasteryNote] = useState("");
  const [isWeakConcept, setIsWeakConcept] = useState(false);
  const [selections, setSelections] = useState<SelectionByQuiz>({});
  const [results, setResults] = useState<ResultByQuiz>({});
  const [message, setMessage] = useState("");
  const [dataError, setDataError] = useState("");
  const [loadingData, setLoadingData] = useState(false);
  const [savingNote, setSavingNote] = useState(false);
  const [savingJournal, setSavingJournal] = useState(false);
  const [savingMastery, setSavingMastery] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;

    async function loadLesson() {
      setLoadingData(true);
      setDataError("");

      try {
        const lessonResult = await supabase.from("lessons").select("*").eq("id", lessonId).maybeSingle();
        if (lessonResult.error || !lessonResult.data) {
          setDataError(lessonResult.error?.message ?? "단원을 찾을 수 없습니다.");
          return;
        }

        const [quizResult, noteResult, progressResult, masteryResult] = await Promise.all([
          supabase.from("quizzes").select("*").eq("lesson_id", lessonId).order("sort_order", { ascending: true }),
          supabase
            .from("learning_notes")
            .select("*")
            .eq("user_id", currentUser.id)
            .eq("lesson_id", lessonId)
            .order("updated_at", { ascending: false })
            .limit(1),
          supabase
            .from("user_progress")
            .select("*")
            .eq("user_id", currentUser.id)
            .eq("lesson_id", lessonId)
            .order("updated_at", { ascending: false })
            .limit(1),
          supabase
            .from("concept_mastery")
            .select("*")
            .eq("user_id", currentUser.id)
            .eq("lesson_id", lessonId)
            .order("updated_at", { ascending: false })
            .limit(1)
        ]);

        const firstError = quizResult.error || noteResult.error || progressResult.error || masteryResult.error;
        if (firstError) {
          setDataError(firstError.message);
          return;
        }

        const quizRows = quizResult.data ?? [];
        const quizIds = quizRows.map((quiz) => quiz.id);
        let options: QuizOption[] = [];

        if (quizIds.length > 0) {
          const optionResult = await supabase.from("quiz_options").select("*").in("quiz_id", quizIds).order("sort_order", { ascending: true });
          if (optionResult.error) {
            setDataError(optionResult.error.message);
            return;
          }
          options = (optionResult.data ?? []) as QuizOption[];
        }

        const now = new Date().toISOString();
        const existingProgress = firstRow(progressResult.data) as UserProgress | null;
        const savedProgress = await saveProgressRow({
          lessonId,
          userId: currentUser.id,
          existingProgress,
          completed: existingProgress?.completed ?? false,
          now
        });

        if (savedProgress.error) {
          setDataError(savedProgress.error);
          return;
        }

        const mastery = firstRow(masteryResult.data) as ConceptMastery | null;
        if (mastery) {
          setMasteryScore(String(mastery.mastery_score));
          setMasteryNote(mastery.note ?? "");
          setIsWeakConcept(mastery.is_weak);
        }

        setLesson(lessonResult.data as Lesson);
        setQuizzes(
          quizRows.map((quiz) => ({
            ...quiz,
            options: options.filter((option) => option.quiz_id === quiz.id)
          })) as QuizWithOptions[]
        );
        setProgress(savedProgress.row);
        setNote(((firstRow(noteResult.data) as LearningNote | null)?.content ?? ""));
      } catch (loadError) {
        setDataError(loadError instanceof Error ? loadError.message : "학습 페이지를 불러오지 못했습니다.");
      } finally {
        setLoadingData(false);
      }
    }

    async function saveProgressRow({
      lessonId,
      userId,
      existingProgress,
      completed,
      now
    }: {
      lessonId: string;
      userId: string;
      existingProgress: UserProgress | null;
      completed: boolean;
      now: string;
    }): Promise<{ row: UserProgress | null; error: string }> {
      const payload = {
        user_id: userId,
        lesson_id: lessonId,
        status: completed ? "completed" : "in_progress",
        completed,
        started_at: existingProgress?.started_at ?? now,
        completed_at: existingProgress?.completed_at ?? null,
        last_viewed_at: now,
        updated_at: now
      };

      const result = existingProgress
        ? await supabase.from("user_progress").update(payload).eq("id", existingProgress.id).eq("user_id", userId).select("*").limit(1)
        : await supabase.from("user_progress").insert(payload).select("*").limit(1);

      return {
        row: firstRow(result.data) as UserProgress | null,
        error: result.error?.message ?? ""
      };
    }

    loadLesson();
  }, [client, lessonId, user]);

  const allSelected = useMemo(() => quizzes.every((quiz) => Boolean(selections[quiz.id])), [quizzes, selections]);
  const completed = progress?.completed ?? false;

  async function saveNote() {
    if (!client || !user) return;
    setSavingNote(true);
    setMessage("");

    const existingResult = await client
      .from("learning_notes")
      .select("*")
      .eq("user_id", user.id)
      .eq("lesson_id", lessonId)
      .order("updated_at", { ascending: false })
      .limit(1);

    const existing = firstRow(existingResult.data) as LearningNote | null;
    const payload = {
      user_id: user.id,
      lesson_id: lessonId,
      content: note,
      updated_at: new Date().toISOString()
    };

    const result = existingResult.error
      ? existingResult
      : existing
        ? await client.from("learning_notes").update(payload).eq("id", existing.id).eq("user_id", user.id)
        : await client.from("learning_notes").insert(payload);

    setSavingNote(false);
    setMessage(result.error ? result.error.message : "메모를 저장했습니다.");
  }

  async function saveJournal() {
    if (!client || !user) return;
    setSavingJournal(true);
    setMessage("");

    const result = await client.from("learning_journal").insert({
      user_id: user.id,
      lesson_id: lessonId,
      journal_date: toIsoDate(new Date()),
      study_minutes: clampNumber(Number(studyMinutes), 1, 1440),
      understanding_score: clampNumber(Number(understandingScore), 0, 100),
      content: journalContent
    });

    setSavingJournal(false);
    setMessage(result.error ? result.error.message : "학습일지를 저장했습니다.");
    if (!result.error) setJournalContent("");
  }

  async function saveMastery() {
    if (!client || !user || !lesson) return;
    setSavingMastery(true);
    setMessage("");

    const score = clampNumber(Number(masteryScore), 0, 100);
    const result = await upsertMasteryByLesson({
      lessonId: lesson.id,
      userId: user.id,
      conceptName: lesson.title,
      masteryScore: score,
      isWeak: isWeakConcept || score <= 60,
      note: masteryNote
    });

    setSavingMastery(false);
    setMessage(result.error ? result.error : "이해도 평가를 저장했습니다.");
  }

  async function submitQuiz() {
    if (!client || !user || !lesson) return;
    if (!allSelected) {
      setMessage("모든 문제의 답을 선택해 주세요.");
      return;
    }

    setSubmitting(true);
    setMessage("");

    const nextResults: ResultByQuiz = {};

    for (const quiz of quizzes) {
      const selectedOption = quiz.options.find((option) => option.id === selections[quiz.id]);
      const correctOption = quiz.options.find((option) => option.is_correct);
      if (!selectedOption || !correctOption) continue;

      const isCorrect = selectedOption.is_correct;
      nextResults[quiz.id] = isCorrect;

      await client.from("quiz_attempts").insert({
        user_id: user.id,
        quiz_id: quiz.id,
        selected_option_id: selectedOption.id,
        correct_option_id: correctOption.id,
        is_correct: isCorrect
      });

      if (isCorrect) {
        await client
          .from("wrong_notes")
          .update({ resolved: true, resolved_at: new Date().toISOString(), updated_at: new Date().toISOString() })
          .eq("user_id", user.id)
          .eq("quiz_id", quiz.id);
      } else {
        await saveWrongNote(quiz, selectedOption, correctOption);
      }
    }

    const allCorrect = Object.values(nextResults).length === quizzes.length && Object.values(nextResults).every(Boolean);
    const now = new Date().toISOString();
    const progressResult = await client
      .from("user_progress")
      .select("*")
      .eq("user_id", user.id)
      .eq("lesson_id", lesson.id)
      .order("updated_at", { ascending: false })
      .limit(1);

    if (progressResult.error) {
      setMessage(progressResult.error.message);
      setSubmitting(false);
      return;
    }

    const existingProgress = firstRow(progressResult.data) as UserProgress | null;
    const progressPayload = {
      user_id: user.id,
      lesson_id: lesson.id,
      status: allCorrect ? "completed" : "in_progress",
      completed: allCorrect,
      started_at: existingProgress?.started_at ?? now,
      completed_at: allCorrect ? now : null,
      last_viewed_at: now,
      updated_at: now
    };

    const progressSaveResult = existingProgress
      ? await client.from("user_progress").update(progressPayload).eq("id", existingProgress.id).eq("user_id", user.id).select("*").limit(1)
      : await client.from("user_progress").insert(progressPayload).select("*").limit(1);

    if (progressSaveResult.error) {
      setMessage(progressSaveResult.error.message);
      setSubmitting(false);
      return;
    }

    if (allCorrect) {
      await createReviewSchedule(lesson.id);
      await saveCompletionMastery(lesson.id, lesson.title);
    }

    const savedProgress = firstRow(progressSaveResult.data) as UserProgress | null;
    if (savedProgress) setProgress(savedProgress);
    setResults(nextResults);
    setMessage(allCorrect ? "모든 문제를 맞혔습니다. 단원 완료와 복습 일정을 처리했습니다." : "틀린 문제를 오답노트에 저장했습니다.");
    setSubmitting(false);
  }

  async function saveWrongNote(quiz: QuizWithOptions, selectedOption: QuizOption, correctOption: QuizOption) {
    if (!client || !user) return;

    const existingResult = await client
      .from("wrong_notes")
      .select("*")
      .eq("user_id", user.id)
      .eq("quiz_id", quiz.id)
      .order("updated_at", { ascending: false })
      .limit(1);
    const now = new Date().toISOString();
    const payload = {
      user_id: user.id,
      quiz_id: quiz.id,
      selected_option_id: selectedOption.id,
      correct_option_id: correctOption.id,
      question_snapshot: quiz.question,
      explanation_snapshot: quiz.explanation,
      resolved: false,
      resolved_at: null,
      updated_at: now
    };

    const existing = firstRow(existingResult.data) as WrongNote | null;
    if (existing) {
      await client.from("wrong_notes").update({ ...payload, attempt_count: existing.attempt_count + 1 }).eq("id", existing.id).eq("user_id", user.id);
      return;
    }

    await client.from("wrong_notes").insert({ ...payload, attempt_count: 1 });
  }

  async function createReviewSchedule(completedLessonId: string) {
    if (!client || !user) return;

    const today = new Date();
    const rows = reviewSteps.map((step) => {
      const due = new Date(today);
      due.setDate(today.getDate() + step);
      return {
        user_id: user.id,
        lesson_id: completedLessonId,
        review_step: step,
        due_date: toIsoDate(due),
        completed: false,
        completed_at: null
      };
    });

    await client.from("review_schedule").upsert(rows, { onConflict: "user_id,lesson_id,review_step" });
  }

  async function saveCompletionMastery(completedLessonId: string, conceptName: string) {
    if (!client || !user) return;

    const nextScore = Math.max(clampNumber(Number(masteryScore), 0, 100), 100);
    await upsertMasteryByLesson({
      lessonId: completedLessonId,
      userId: user.id,
      conceptName,
      masteryScore: nextScore,
      isWeak: false,
      note: masteryNote
    });

    setMasteryScore(String(nextScore));
    setIsWeakConcept(false);
  }

  async function upsertMasteryByLesson({
    lessonId,
    userId,
    conceptName,
    masteryScore,
    isWeak,
    note
  }: {
    lessonId: string;
    userId: string;
    conceptName: string;
    masteryScore: number;
    isWeak: boolean;
    note: string;
  }): Promise<{ error: string }> {
    if (!client) return { error: "Supabase 클라이언트가 준비되지 않았습니다." };

    const existingResult = await client
      .from("concept_mastery")
      .select("*")
      .eq("user_id", userId)
      .eq("lesson_id", lessonId)
      .order("updated_at", { ascending: false })
      .limit(1);

    if (existingResult.error) return { error: existingResult.error.message };

    const existing = firstRow(existingResult.data) as ConceptMastery | null;
    const payload = {
      user_id: userId,
      lesson_id: lessonId,
      concept_name: conceptName,
      mastery_score: masteryScore,
      is_weak: isWeak,
      note,
      last_reviewed_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const result = existing
      ? await client.from("concept_mastery").update(payload).eq("id", existing.id).eq("user_id", userId)
      : await client.from("concept_mastery").insert(payload);

    return { error: result.error?.message ?? "" };
  }

  function resetQuiz() {
    setSelections({});
    setResults({});
    setMessage("");
  }

  return (
    <AppShell>
      {loading ? (
        <LoadingPanel label="로그인 정보를 확인하는 중입니다..." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : loadingData ? (
        <LoadingPanel label="학습 페이지를 불러오는 중입니다..." />
      ) : lesson ? (
        <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_390px]">
          <section className="grid gap-5">
            <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
              <Link href="/curriculum" className="inline-flex items-center gap-2 text-sm font-bold text-brand">
                <ArrowLeft size={16} /> 커리큘럼
              </Link>
              <div className="mt-4 flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
                <div>
                  <p className="text-sm font-black text-slate-500">학습 단원</p>
                  <h2 className="mt-1 text-3xl font-black">{lesson.title}</h2>
                  <p className="mt-2 text-sm leading-6 text-slate-600">{lesson.objective}</p>
                </div>
                <span className={clsx("inline-flex w-fit items-center gap-2 rounded-full px-3 py-1 text-sm font-black", completed ? "bg-emerald-50 text-emerald-700" : "bg-amber-50 text-amber-700")}>
                  {completed ? <CheckCircle2 size={16} /> : <NotebookPen size={16} />}
                  {completed ? "완료" : "학습 중"}
                </span>
              </div>
            </div>

            <StudyBlock title="개념 설명" body={lesson.concept} />
            <CodeBlock code={lesson.example_code} />
            <StudyBlock title="핵심 요약" body={lesson.summary} />

            <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
              <h3 className="text-lg font-black">객관식 퀴즈</h3>
              <div className="mt-4 grid gap-5">
                {quizzes.map((quiz, index) => (
                  <div key={quiz.id} className="rounded-md border border-line p-4">
                    <p className="whitespace-pre-wrap font-black leading-7">
                      {index + 1}. {quiz.question}
                    </p>
                    <div className="mt-3 grid gap-2">
                      {quiz.options.map((option) => {
                        const selected = selections[quiz.id] === option.id;
                        const result = results[quiz.id];
                        const evaluated = typeof result === "boolean";
                        const correctChoice = evaluated && option.is_correct;
                        const wrongChoice = evaluated && selected && !option.is_correct;

                        return (
                          <button
                            key={option.id}
                            onClick={() => setSelections((current) => ({ ...current, [quiz.id]: option.id }))}
                            className={clsx(
                              "min-h-11 whitespace-pre-wrap rounded-md border px-3 py-2 text-left text-sm font-semibold leading-6 transition",
                              selected && !evaluated && "border-brand bg-blue-50",
                              !selected && !evaluated && "border-line bg-white hover:border-brand",
                              correctChoice && "border-emerald-400 bg-emerald-50 text-emerald-800",
                              wrongChoice && "border-danger bg-red-50 text-danger",
                              evaluated && !correctChoice && !wrongChoice && "border-line bg-slate-50 text-slate-500"
                            )}
                          >
                            {option.option_text}
                          </button>
                        );
                      })}
                    </div>

                    {typeof results[quiz.id] === "boolean" && (
                      <div className="mt-3 rounded-md bg-slate-50 p-3 text-sm leading-6 text-slate-700">
                        <p className="inline-flex items-center gap-2 font-black">
                          {results[quiz.id] ? <CheckCircle2 size={16} className="text-emerald-700" /> : <XCircle size={16} className="text-danger" />}
                          {results[quiz.id] ? "정답" : "오답"}
                        </p>
                        <p className="mt-1 whitespace-pre-wrap">{quiz.explanation}</p>
                      </div>
                    )}
                  </div>
                ))}
              </div>

              <div className="mt-5 flex flex-wrap gap-2">
                <button onClick={submitQuiz} disabled={submitting} className="inline-flex h-10 items-center gap-2 rounded-md bg-brand px-4 text-sm font-black text-white disabled:bg-slate-400">
                  <CheckCircle2 size={16} /> {submitting ? "채점 중..." : "정답 확인"}
                </button>
                <button onClick={resetQuiz} className="inline-flex h-10 items-center gap-2 rounded-md border border-line px-4 text-sm font-black">
                  <RotateCcw size={16} /> 다시 선택
                </button>
              </div>
            </div>
          </section>

          <aside className="grid h-fit gap-5 lg:sticky lg:top-5">
            <SidePanel title="학습 메모">
              <textarea value={note} onChange={(event) => setNote(event.target.value)} rows={7} className="w-full rounded-md border border-line p-3 text-sm leading-6" placeholder="헷갈린 개념, 나만의 예시, 복습할 내용을 적어보세요." />
              <button onClick={saveNote} disabled={savingNote} className="mt-3 inline-flex h-10 w-full items-center justify-center gap-2 rounded-md bg-ink px-4 text-sm font-black text-white disabled:bg-slate-400">
                <Save size={16} /> {savingNote ? "저장 중..." : "메모 저장"}
              </button>
            </SidePanel>

            <SidePanel title="학습일지">
              <div className="grid grid-cols-2 gap-2">
                <Input label="학습시간(분)" value={studyMinutes} onChange={setStudyMinutes} type="number" />
                <Input label="이해도(0-100)" value={understandingScore} onChange={setUnderstandingScore} type="number" />
              </div>
              <textarea value={journalContent} onChange={(event) => setJournalContent(event.target.value)} rows={5} className="mt-3 w-full rounded-md border border-line p-3 text-sm leading-6" placeholder="오늘 배운 내용, 막힌 부분, 다음 복습 계획을 적어보세요." />
              <button onClick={saveJournal} disabled={savingJournal} className="mt-3 inline-flex h-10 w-full items-center justify-center gap-2 rounded-md bg-brand px-4 text-sm font-black text-white disabled:bg-slate-400">
                <Save size={16} /> {savingJournal ? "저장 중..." : "학습일지 저장"}
              </button>
            </SidePanel>

            <SidePanel title="이해도 평가">
              <Input label="개념 이해도(0-100)" value={masteryScore} onChange={setMasteryScore} type="number" />
              <label className="mt-3 flex items-center gap-2 rounded-md border border-line p-3 text-sm font-bold">
                <input type="checkbox" checked={isWeakConcept} onChange={(event) => setIsWeakConcept(event.target.checked)} />
                취약개념으로 표시
              </label>
              <textarea value={masteryNote} onChange={(event) => setMasteryNote(event.target.value)} rows={4} className="mt-3 w-full rounded-md border border-line p-3 text-sm leading-6" placeholder="어떤 부분이 약한지 짧게 적어보세요." />
              <button onClick={saveMastery} disabled={savingMastery} className="mt-3 inline-flex h-10 w-full items-center justify-center gap-2 rounded-md bg-ink px-4 text-sm font-black text-white disabled:bg-slate-400">
                <Save size={16} /> {savingMastery ? "저장 중..." : "이해도 저장"}
              </button>
            </SidePanel>

            {message && <div className="rounded-lg border border-line bg-white p-4 text-sm font-bold text-slate-700 shadow-soft">{message}</div>}
          </aside>
        </div>
      ) : (
        <ErrorPanel message="단원을 찾을 수 없습니다." />
      )}
    </AppShell>
  );
}

function StudyBlock({ title, body }: { title: string; body: string }) {
  return (
    <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <h3 className="text-lg font-black">{title}</h3>
      <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-slate-700">{body}</p>
    </section>
  );
}

function CodeBlock({ code }: { code: string }) {
  return (
    <section className="rounded-lg border border-line bg-ink p-5 text-white shadow-soft">
      <h3 className="text-lg font-black">예제</h3>
      <pre className="mt-3 overflow-x-auto whitespace-pre text-sm leading-7">
        <code>{code}</code>
      </pre>
    </section>
  );
}

function SidePanel({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <h3 className="mb-3 text-lg font-black">{title}</h3>
      {children}
    </div>
  );
}

function Input({ label, value, onChange, type = "text" }: { label: string; value: string; onChange: (value: string) => void; type?: string }) {
  return (
    <label className="grid gap-1 text-sm font-bold text-slate-700">
      {label}
      <input type={type} value={value} onChange={(event) => onChange(event.target.value)} className="h-10 rounded-md border border-line px-3 text-ink" />
    </label>
  );
}

function firstRow<T>(rows: T[] | null | undefined) {
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

function clampNumber(value: number, min: number, max: number) {
  if (Number.isNaN(value)) return min;
  return Math.min(max, Math.max(min, Math.round(value)));
}

function toIsoDate(date: Date) {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}
