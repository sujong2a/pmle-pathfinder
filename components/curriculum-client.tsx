"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, CheckCircle2, Circle, Clock3 } from "lucide-react";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { Lesson, LessonStatus, Module, UserProgress } from "@/lib/types";

type CurriculumState = {
  modules: Module[];
  lessons: Lesson[];
  progress: UserProgress[];
};

const statusLabel: Record<LessonStatus, string> = {
  not_started: "시작 전",
  in_progress: "학습 중",
  completed: "완료"
};

export function CurriculumClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<CurriculumState>({ modules: [], lessons: [], progress: [] });
  const [loadingData, setLoadingData] = useState(false);
  const [dataError, setDataError] = useState("");

  useEffect(() => {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;

    async function loadCurriculum() {
      setLoadingData(true);
      setDataError("");

      try {
        const [modulesResult, lessonsResult, progressResult] = await Promise.all([
          supabase.from("modules").select("*").order("sort_order", { ascending: true }),
          supabase.from("lessons").select("*").order("sort_order", { ascending: true }),
          supabase.from("user_progress").select("*").eq("user_id", currentUser.id)
        ]);

        const firstError = modulesResult.error || lessonsResult.error || progressResult.error;
        if (firstError) {
          setDataError(firstError.message);
          return;
        }

        setState({
          modules: (modulesResult.data ?? []) as Module[],
          lessons: (lessonsResult.data ?? []) as Lesson[],
          progress: (progressResult.data ?? []) as UserProgress[]
        });
      } catch (loadError) {
        setDataError(loadError instanceof Error ? loadError.message : "커리큘럼을 불러오지 못했습니다.");
      } finally {
        setLoadingData(false);
      }
    }

    loadCurriculum();
  }, [client, user]);

  const progressMap = useMemo(() => new Map(state.progress.map((item) => [item.lesson_id, item])), [state.progress]);

  return (
    <AppShell>
      {loading ? (
        <LoadingPanel label="로그인 정보를 확인하는 중입니다..." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : loadingData ? (
        <LoadingPanel label="커리큘럼을 불러오는 중입니다..." />
      ) : (
        <div className="grid gap-5">
          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <h2 className="text-xl font-black">커리큘럼</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Python 기초부터 데이터 분석, 머신러닝, GCP, Vertex AI, PMLE 준비까지 순서대로 학습합니다. 코드와 서비스 이름은 영어 그대로 익히고,
              설명은 한국어로 따라갈 수 있게 구성합니다.
            </p>
          </section>

          {state.modules.map((module) => {
            const lessons = state.lessons.filter((lesson) => lesson.module_id === module.id);
            const completedCount = lessons.filter((lesson) => progressMap.get(lesson.id)?.completed).length;
            const percent = lessons.length ? Math.round((completedCount / lessons.length) * 100) : 0;

            return (
              <section key={module.id} className="rounded-lg border border-line bg-white p-5 shadow-soft">
                <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
                  <div>
                    <h3 className="text-lg font-black">{module.title}</h3>
                    <p className="mt-1 text-sm leading-6 text-slate-600">{module.description}</p>
                  </div>
                  <div className="min-w-40">
                    <div className="flex items-center justify-between text-sm font-bold text-slate-600">
                      <span>진행률</span>
                      <span>{percent}%</span>
                    </div>
                    <div className="mt-2 h-2 overflow-hidden rounded-full bg-slate-100">
                      <div className="h-full bg-brand" style={{ width: `${percent}%` }} />
                    </div>
                  </div>
                </div>

                <div className="mt-5 grid gap-3 md:grid-cols-2">
                  {lessons.map((lesson) => {
                    const status = getLessonStatus(progressMap.get(lesson.id));
                    const Icon = status === "completed" ? CheckCircle2 : status === "in_progress" ? Clock3 : Circle;

                    return (
                      <Link key={lesson.id} href={`/learn/${lesson.id}`} className="rounded-md border border-line p-4 hover:border-brand">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <div className="inline-flex items-center gap-2 rounded-full bg-slate-50 px-2 py-1 text-xs font-black text-slate-600">
                              <Icon size={14} />
                              {statusLabel[status]}
                            </div>
                            <h4 className="mt-3 text-lg font-black">{lesson.title}</h4>
                            <p className="mt-1 text-sm leading-6 text-slate-600">{lesson.objective}</p>
                          </div>
                          <ArrowRight size={18} className="mt-1 shrink-0 text-brand" />
                        </div>
                      </Link>
                    );
                  })}
                </div>
              </section>
            );
          })}

          {state.modules.length === 0 && (
            <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
              <p className="text-sm font-semibold text-slate-600">커리큘럼 데이터가 없습니다. Supabase SQL을 먼저 실행해 주세요.</p>
            </section>
          )}
        </div>
      )}
    </AppShell>
  );
}

function getLessonStatus(progress?: UserProgress): LessonStatus {
  if (!progress) return "not_started";
  if (progress.completed) return "completed";
  return "in_progress";
}
