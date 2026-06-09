"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { CheckCircle2, Cloud, ClipboardList, Route, Table2 } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { ExamDomain, Lesson, Module, ScenarioQuestion, ServiceComparison, UserProgress } from "@/lib/types";

type GcpState = {
  module: Module | null;
  lessons: Lesson[];
  progress: UserProgress[];
  examDomains: ExamDomain[];
  serviceComparisons: ServiceComparison[];
  scenarioQuestions: ScenarioQuestion[];
};

type ScenarioResult = {
  selectedIndex: number;
  correct: boolean;
};

export function GcpDashboardClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<GcpState>({
    module: null,
    lessons: [],
    progress: [],
    examDomains: [],
    serviceComparisons: [],
    scenarioQuestions: []
  });
  const [scenarioResults, setScenarioResults] = useState<Record<string, ScenarioResult>>({});
  const [loadingData, setLoadingData] = useState(true);
  const [dataError, setDataError] = useState("");

  useEffect(() => {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;

    async function loadGcpDashboard() {
      setLoadingData(true);
      setDataError("");

      const moduleResult = await supabase.from("modules").select("*").eq("title", "GCP + Vertex AI").maybeSingle();
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
      const [progressResult, domainsResult, comparisonsResult, scenariosResult] = await Promise.all([
        lessonIds.length ? supabase.from("user_progress").select("*").eq("user_id", currentUser.id).in("lesson_id", lessonIds) : Promise.resolve({ data: [], error: null }),
        supabase.from("exam_domains").select("*").order("sort_order", { ascending: true }),
        supabase.from("service_comparisons").select("*").order("sort_order", { ascending: true }),
        supabase.from("scenario_questions").select("*").order("sort_order", { ascending: true })
      ]);

      const firstError = progressResult.error || domainsResult.error || comparisonsResult.error || scenariosResult.error;
      if (firstError) {
        setDataError(firstError.message);
        setLoadingData(false);
        return;
      }

      setState({
        module,
        lessons,
        progress: (progressResult.data ?? []) as UserProgress[],
        examDomains: normalizeTextArrayRows((domainsResult.data ?? []) as ExamDomain[]),
        serviceComparisons: (comparisonsResult.data ?? []) as ServiceComparison[],
        scenarioQuestions: normalizeScenarioQuestions((scenariosResult.data ?? []) as ScenarioQuestion[])
      });
      setLoadingData(false);
    }

    loadGcpDashboard();
  }, [client, user]);

  const lessonMap = useMemo(() => new Map(state.lessons.map((lesson) => [lesson.id, lesson])), [state.lessons]);
  const completedLessons = state.progress.filter((item) => item.completed).length;
  const progressPercent = state.lessons.length ? Math.round((completedLessons / state.lessons.length) * 100) : 0;
  const scenarioSolved = Object.values(scenarioResults).length;
  const scenarioCorrect = Object.values(scenarioResults).filter((item) => item.correct).length;

  function answerScenario(question: ScenarioQuestion, selectedIndex: number) {
    setScenarioResults((current) => ({
      ...current,
      [question.id]: {
        selectedIndex,
        correct: selectedIndex === question.correct_option_index
      }
    }));
  }

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="GCP + Vertex AI 과정을 불러오는 중입니다..." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : !state.module ? (
        <ErrorPanel message="GCP + Vertex AI 커리큘럼을 찾지 못했습니다. MVP6 Supabase 마이그레이션을 먼저 실행해 주세요." />
      ) : (
        <div className="grid gap-5">
          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">GCP + Vertex AI</p>
            <h1 className="mt-1 text-2xl font-black">GCP + Vertex AI 학습 대시보드</h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">{state.module.description}</p>
          </section>

          <section className="grid gap-3 md:grid-cols-4">
            <Metric label="과정 진행률" value={`${progressPercent}%`} icon={Cloud} />
            <Metric label="완료한 단원" value={`${completedLessons}/${state.lessons.length}`} icon={CheckCircle2} />
            <Metric label="시험 영역" value={`${state.examDomains.length}`} icon={ClipboardList} />
            <Metric label="시나리오 정답" value={`${scenarioCorrect}/${scenarioSolved || state.scenarioQuestions.length}`} icon={Route} />
          </section>

          <section className="grid gap-5 lg:grid-cols-[1.05fr_0.95fr]">
            <Panel title="커리큘럼">
              {state.lessons.map((lesson) => {
                const progress = state.progress.find((item) => item.lesson_id === lesson.id);
                return (
                  <Link key={lesson.id} href={`/learn/${lesson.id}`} className="rounded-md border border-line p-4 hover:border-brand">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="font-black">{lesson.title}</p>
                        <p className="mt-1 text-sm leading-6 text-slate-600">{lesson.objective}</p>
                      </div>
                      <span className="shrink-0 rounded-full bg-slate-50 px-2 py-1 text-xs font-black text-slate-600">
                        {progress?.completed ? "완료" : progress ? "학습 중" : "새 단원"}
                      </span>
                    </div>
                  </Link>
                );
              })}
            </Panel>

            <Panel title="시험 포인트와 실무 포인트">
              {state.examDomains.map((domain) => (
                <article key={domain.id} className="rounded-md border border-line p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-black">{domain.title}</p>
                      <p className="mt-1 text-sm leading-6 text-slate-600">{domain.description}</p>
                    </div>
                    {domain.weight_percent !== null && <span className="shrink-0 rounded-full bg-blue-50 px-2 py-1 text-xs font-black text-brand">{domain.weight_percent}%</span>}
                  </div>
                  <MiniList title="시험 포인트" items={domain.exam_points} />
                  <MiniList title="실무 포인트" items={domain.practical_points} />
                </article>
              ))}
            </Panel>
          </section>

          <Panel title="서비스 비교표">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] border-collapse text-left text-sm">
                <thead>
                  <tr className="border-b border-line text-slate-500">
                    <th className="px-3 py-2">서비스</th>
                    <th className="px-3 py-2">분류</th>
                    <th className="px-3 py-2">적합한 상황</th>
                    <th className="px-3 py-2">피해야 할 상황</th>
                    <th className="px-3 py-2">시험 / 실무 포인트</th>
                  </tr>
                </thead>
                <tbody>
                  {state.serviceComparisons.map((service) => (
                    <tr key={service.id} className="border-b border-line align-top">
                      <td className="px-3 py-3 font-black">{service.service_name}</td>
                      <td className="px-3 py-3">{service.category}</td>
                      <td className="px-3 py-3">{service.best_for}</td>
                      <td className="px-3 py-3">{service.avoid_when}</td>
                      <td className="px-3 py-3">
                        <p className="font-bold text-brand">{service.exam_point}</p>
                        <p className="mt-1 text-slate-600">{service.practical_point}</p>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Panel>

          <Panel title="시나리오 퀴즈">
            <div className="grid gap-4 lg:grid-cols-2">
              {state.scenarioQuestions.map((question) => {
                const result = scenarioResults[question.id];
                const lesson = question.lesson_id ? lessonMap.get(question.lesson_id) : undefined;
                return (
                  <article key={question.id} className="rounded-md border border-line p-4">
                    <p className="text-xs font-black text-brand">{lesson?.title ?? "GCP 시나리오"}</p>
                    <h3 className="mt-1 font-black">{question.title}</h3>
                    <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-600">{question.scenario}</p>
                    <div className="mt-3 grid gap-2">
                      {question.options.map((option, index) => {
                        const selected = result?.selectedIndex === index;
                        const correct = result && index === question.correct_option_index;
                        const wrong = result && selected && !correct;
                        return (
                          <button
                            key={option}
                            onClick={() => answerScenario(question, index)}
                            className={clsx(
                              "whitespace-pre-wrap rounded-md border px-3 py-2 text-left text-sm font-semibold leading-6",
                              !result && "border-line hover:border-brand",
                              correct && "border-emerald-400 bg-emerald-50 text-emerald-800",
                              wrong && "border-danger bg-red-50 text-danger",
                              result && !correct && !wrong && "border-line bg-slate-50 text-slate-500"
                            )}
                          >
                            {option}
                          </button>
                        );
                      })}
                    </div>
                    {result && (
                      <div className="mt-3 rounded-md bg-slate-50 p-3 text-sm leading-6 text-slate-700">
                        <p className="font-black">{result.correct ? "정답" : "오답"}</p>
                        <p className="mt-1">{question.explanation}</p>
                        <p className="mt-2 font-bold text-brand">Exam point: {question.exam_point}</p>
                        <p className="mt-1 text-slate-600">Practical point: {question.practical_point}</p>
                      </div>
                    )}
                  </article>
                );
              })}
            </div>
          </Panel>
        </div>
      )}
    </AppShell>
  );
}

function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center gap-2">
        <Table2 size={18} className="text-brand" />
        <h2 className="text-lg font-black">{title}</h2>
      </div>
      <div className="mt-4 grid gap-3">{children}</div>
    </section>
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

function MiniList({ title, items }: { title: string; items: string[] }) {
  return (
    <div className="mt-3">
      <p className="text-sm font-black">{title}</p>
      <ul className="mt-1 grid gap-1 text-sm leading-6 text-slate-700">
        {items.map((item) => (
          <li key={item}>- {item}</li>
        ))}
      </ul>
    </div>
  );
}

function normalizeTextArrayRows(rows: ExamDomain[]) {
  return rows.map((row) => ({
    ...row,
    exam_points: Array.isArray(row.exam_points) ? row.exam_points : [],
    practical_points: Array.isArray(row.practical_points) ? row.practical_points : []
  }));
}

function normalizeScenarioQuestions(rows: ScenarioQuestion[]) {
  return rows.map((row) => ({
    ...row,
    options: Array.isArray(row.options) ? row.options : []
  }));
}
