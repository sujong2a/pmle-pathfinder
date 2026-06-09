"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, CheckCircle2, Code2, FileQuestion, Map as MapIcon, TrendingUp } from "lucide-react";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { CodingSubmission, CodingTask, Lesson, MlConceptMapItem, Module, Quiz, UserProgress, WrongNote } from "@/lib/types";

type MlDashboardState = {
  module: Module | null;
  lessons: Lesson[];
  progress: UserProgress[];
  quizzes: Quiz[];
  wrongNotes: WrongNote[];
  codingTasks: CodingTask[];
  codingSubmissions: CodingSubmission[];
  conceptMap: MlConceptMapItem[];
};

export function MlDashboardClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<MlDashboardState>({
    module: null,
    lessons: [],
    progress: [],
    quizzes: [],
    wrongNotes: [],
    codingTasks: [],
    codingSubmissions: [],
    conceptMap: []
  });
  const [loadingData, setLoadingData] = useState(true);
  const [dataError, setDataError] = useState("");

  useEffect(() => {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;

    async function loadMlDashboard() {
      setLoadingData(true);
      setDataError("");

      const moduleResult = await supabase.from("modules").select("*").eq("title", "Machine Learning").maybeSingle();
      if (moduleResult.error) {
        setDataError(moduleResult.error.message);
        setLoadingData(false);
        return;
      }

      const module = moduleResult.data as Module | null;
      if (!module) {
        setState((current) => ({ ...current, module: null }));
        setLoadingData(false);
        return;
      }

      const lessonsResult = await supabase.from("lessons").select("*").eq("module_id", module.id).order("sort_order", { ascending: true });
      if (lessonsResult.error) {
        setDataError(lessonsResult.error.message);
        setLoadingData(false);
        return;
      }

      const lessons = (lessonsResult.data ?? []) as Lesson[];
      const lessonIds = lessons.map((lesson) => lesson.id);

      const [progressResult, quizResult, tasksResult, conceptMapResult] = await Promise.all([
        lessonIds.length ? supabase.from("user_progress").select("*").eq("user_id", currentUser.id).in("lesson_id", lessonIds) : Promise.resolve({ data: [], error: null }),
        lessonIds.length ? supabase.from("quizzes").select("*").in("lesson_id", lessonIds) : Promise.resolve({ data: [], error: null }),
        lessonIds.length ? supabase.from("coding_tasks").select("*").in("lesson_id", lessonIds).eq("is_active", true).order("sort_order", { ascending: true }) : Promise.resolve({ data: [], error: null }),
        supabase.from("ml_concept_map").select("*").order("sort_order", { ascending: true })
      ]);

      const firstError = progressResult.error || quizResult.error || tasksResult.error || conceptMapResult.error;
      if (firstError) {
        setDataError(firstError.message);
        setLoadingData(false);
        return;
      }

      const quizzes = (quizResult.data ?? []) as Quiz[];
      const quizIds = quizzes.map((quiz) => quiz.id);
      const codingTasks = (tasksResult.data ?? []) as CodingTask[];
      const taskIds = codingTasks.map((task) => task.id);

      const [wrongNotesResult, submissionsResult] = await Promise.all([
        quizIds.length ? supabase.from("wrong_notes").select("*").eq("user_id", currentUser.id).in("quiz_id", quizIds).order("updated_at", { ascending: false }) : Promise.resolve({ data: [], error: null }),
        taskIds.length ? supabase.from("coding_submissions").select("*").eq("user_id", currentUser.id).in("task_id", taskIds).order("created_at", { ascending: false }) : Promise.resolve({ data: [], error: null })
      ]);

      const secondError = wrongNotesResult.error || submissionsResult.error;
      if (secondError) {
        setDataError(secondError.message);
        setLoadingData(false);
        return;
      }

      setState({
        module,
        lessons,
        progress: (progressResult.data ?? []) as UserProgress[],
        quizzes,
        wrongNotes: (wrongNotesResult.data ?? []) as WrongNote[],
        codingTasks,
        codingSubmissions: (submissionsResult.data ?? []) as CodingSubmission[],
        conceptMap: (conceptMapResult.data ?? []) as MlConceptMapItem[]
      });
      setLoadingData(false);
    }

    loadMlDashboard();
  }, [client, user]);

  const lessonMap = useMemo(() => new Map(state.lessons.map((lesson) => [lesson.id, lesson])), [state.lessons]);
  const quizMap = useMemo(() => new Map(state.quizzes.map((quiz) => [quiz.id, quiz])), [state.quizzes]);
  const completedLessons = state.progress.filter((item) => item.completed).length;
  const lessonProgress = state.lessons.length ? Math.round((completedLessons / state.lessons.length) * 100) : 0;
  const passedPracticeTaskIds = new Set(state.codingSubmissions.filter((submission) => submission.status === "passed").map((submission) => submission.task_id));
  const practiceProgress = state.codingTasks.length ? Math.round((passedPracticeTaskIds.size / state.codingTasks.length) * 100) : 0;
  const unresolvedWrongNotes = state.wrongNotes.filter((note) => !note.resolved);

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="ML 학습 대시보드를 불러오는 중입니다." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : !state.module ? (
        <ErrorPanel message="Machine Learning 커리큘럼이 없습니다. MVP5 SQL 마이그레이션을 먼저 실행하세요." />
      ) : (
        <div className="grid gap-5">
          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">Machine Learning</p>
            <h1 className="mt-1 text-2xl font-black">ML 학습 대시보드</h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">{state.module.description}</p>
          </section>

          <section className="grid gap-3 md:grid-cols-4">
            <Metric label="ML 단원 진행률" value={`${lessonProgress}%`} icon={TrendingUp} />
            <Metric label="완료 단원" value={`${completedLessons}/${state.lessons.length}`} icon={CheckCircle2} />
            <Metric label="ML 미해결 오답" value={`${unresolvedWrongNotes.length}개`} icon={FileQuestion} />
            <Metric label="ML 실습 진행률" value={`${practiceProgress}%`} icon={Code2} />
          </section>

          <section className="grid gap-5 lg:grid-cols-[1.1fr_0.9fr]">
            <Panel title="ML 커리큘럼">
              {state.lessons.map((lesson) => {
                const progress = state.progress.find((item) => item.lesson_id === lesson.id);
                return (
                  <Link key={lesson.id} href={`/learn/${lesson.id}`} className="rounded-md border border-line p-4 hover:border-brand">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="font-black">{lesson.title}</p>
                        <p className="mt-1 text-sm leading-6 text-slate-600">{lesson.objective}</p>
                      </div>
                      <span className="shrink-0 rounded-full bg-slate-50 px-2 py-1 text-xs font-black text-slate-600">{progress?.completed ? "완료" : progress ? "학습 중" : "시작 전"}</span>
                    </div>
                  </Link>
                );
              })}
            </Panel>

            <Panel title="ML 오답노트">
              {unresolvedWrongNotes.slice(0, 5).map((note) => {
                const quiz = quizMap.get(note.quiz_id);
                const lesson = quiz ? lessonMap.get(quiz.lesson_id) : undefined;
                return (
                  <Link key={note.id} href={lesson ? `/learn/${lesson.id}` : "/wrong-notes"} className="rounded-md bg-red-50 p-4">
                    <p className="font-black text-danger">{note.question_snapshot}</p>
                    <p className="mt-1 text-sm text-slate-700">{lesson?.title ?? "ML 퀴즈"} · 누적 {note.attempt_count}회</p>
                  </Link>
                );
              })}
              {unresolvedWrongNotes.length === 0 && <Empty label="ML 미해결 오답이 없습니다." />}
            </Panel>
          </section>

          <section className="grid gap-5 lg:grid-cols-[0.9fr_1.1fr]">
            <Panel title="ML 실습">
              {state.codingTasks.map((task) => {
                const passed = passedPracticeTaskIds.has(task.id);
                return (
                  <Link key={task.id} href="/coding-lab" className="rounded-md border border-line p-4 hover:border-brand">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="font-black">{task.title}</p>
                        <p className="mt-1 text-sm leading-6 text-slate-600">{task.description}</p>
                      </div>
                      <span className="shrink-0 rounded-full bg-slate-50 px-2 py-1 text-xs font-black text-slate-600">{passed ? "통과" : "미완료"}</span>
                    </div>
                  </Link>
                );
              })}
              {state.codingTasks.length === 0 && <Empty label="등록된 ML 실습이 없습니다." />}
            </Panel>

            <Panel title="ML 개념맵">
              <div className="grid gap-3">
                {state.conceptMap.map((item) => (
                  <div key={item.id} className="rounded-md border border-line p-4">
                    <div className="flex flex-wrap items-center gap-2 text-sm">
                      <span className="rounded-md bg-blue-50 px-2 py-1 font-black text-brand">{item.source_concept}</span>
                      <span className="font-bold text-slate-500">{item.relation}</span>
                      <span className="rounded-md bg-emerald-50 px-2 py-1 font-black text-emerald-800">{item.target_concept}</span>
                    </div>
                    <p className="mt-2 text-sm leading-6 text-slate-600">{item.description}</p>
                  </div>
                ))}
                {state.conceptMap.length === 0 && <Empty label="ML 개념맵 데이터가 없습니다." />}
              </div>
            </Panel>
          </section>
        </div>
      )}
    </AppShell>
  );
}

function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center gap-2">
        <MapIcon size={18} className="text-brand" />
        <h2 className="text-lg font-black">{title}</h2>
      </div>
      <div className="mt-4 grid gap-3">{children}</div>
    </div>
  );
}

function Metric({ label, value, icon: Icon }: { label: string; value: string; icon: React.ComponentType<{ size?: number; className?: string }> }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm font-bold text-slate-600">{label}</p>
        <Icon size={18} className="text-brand" />
      </div>
      <p className="mt-3 text-3xl font-black">{value}</p>
    </div>
  );
}

function Empty({ label }: { label: string }) {
  return <p className="rounded-md bg-slate-50 p-4 text-sm font-semibold text-slate-500">{label}</p>;
}
