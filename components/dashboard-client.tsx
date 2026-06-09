"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, BookOpen, CalendarCheck2, CheckCircle2, Clock3, FileQuestion, Flame, NotebookText, TrendingDown, TrendingUp } from "lucide-react";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { ConceptMastery, LearningJournal, LearningNote, Lesson, ReviewSchedule, UserProgress, WrongNote } from "@/lib/types";

type DashboardState = {
  lessons: Lesson[];
  progress: UserProgress[];
  notes: LearningNote[];
  wrongNotes: WrongNote[];
  journals: LearningJournal[];
  conceptMastery: ConceptMastery[];
  reviews: ReviewSchedule[];
};

export function DashboardClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<DashboardState>({
    lessons: [],
    progress: [],
    notes: [],
    wrongNotes: [],
    journals: [],
    conceptMastery: [],
    reviews: []
  });
  const [dataError, setDataError] = useState("");
  const [loadingData, setLoadingData] = useState(false);

  useEffect(() => {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;

    async function loadDashboard() {
      setLoadingData(true);
      setDataError("");

      try {
        const today = toIsoDate(new Date());
        const [lessonsResult, progressResult, notesResult, wrongNotesResult, journalsResult, masteryResult, reviewsResult] = await Promise.all([
          supabase.from("lessons").select("*").order("sort_order", { ascending: true }),
          supabase.from("user_progress").select("*").eq("user_id", currentUser.id),
          supabase.from("learning_notes").select("*").eq("user_id", currentUser.id).order("updated_at", { ascending: false }).limit(3),
          supabase.from("wrong_notes").select("*").eq("user_id", currentUser.id).order("updated_at", { ascending: false }),
          supabase.from("learning_journal").select("*").eq("user_id", currentUser.id).order("journal_date", { ascending: false }).order("updated_at", { ascending: false }),
          supabase.from("concept_mastery").select("*").eq("user_id", currentUser.id).order("mastery_score", { ascending: true }).limit(10),
          supabase
            .from("review_schedule")
            .select("*")
            .eq("user_id", currentUser.id)
            .eq("completed", false)
            .lte("due_date", today)
            .order("due_date", { ascending: true })
        ]);

        const firstError =
          lessonsResult.error ||
          progressResult.error ||
          notesResult.error ||
          wrongNotesResult.error ||
          journalsResult.error ||
          masteryResult.error ||
          reviewsResult.error;

        if (firstError) {
          setDataError(firstError.message);
          return;
        }

        setState({
          lessons: (lessonsResult.data ?? []) as Lesson[],
          progress: (progressResult.data ?? []) as UserProgress[],
          notes: (notesResult.data ?? []) as LearningNote[],
          wrongNotes: (wrongNotesResult.data ?? []) as WrongNote[],
          journals: (journalsResult.data ?? []) as LearningJournal[],
          conceptMastery: (masteryResult.data ?? []) as ConceptMastery[],
          reviews: (reviewsResult.data ?? []) as ReviewSchedule[]
        });
      } catch (loadError) {
        setDataError(loadError instanceof Error ? loadError.message : "대시보드 데이터를 불러오지 못했습니다.");
      } finally {
        setLoadingData(false);
      }
    }

    loadDashboard();
  }, [client, user]);

  const lessonMap = useMemo(() => new Map(state.lessons.map((lesson) => [lesson.id, lesson])), [state.lessons]);
  const completedCount = state.progress.filter((item) => item.completed).length;
  const totalLessons = state.lessons.length;
  const percent = totalLessons ? Math.round((completedCount / totalLessons) * 100) : 0;
  const recentProgress = [...state.progress]
    .filter((item) => item.last_viewed_at)
    .sort((a, b) => String(b.last_viewed_at).localeCompare(String(a.last_viewed_at)))
    .slice(0, 3);
  const unresolvedWrongCount = state.wrongNotes.filter((item) => !item.resolved).length;
  const weakConcepts = state.conceptMastery.filter((item) => item.is_weak || item.mastery_score <= 60).slice(0, 5);
  const totalStudyMinutes = state.journals.reduce((sum, journal) => sum + journal.study_minutes, 0);
  const streakDays = calculateStreakDays(state.journals.map((journal) => journal.journal_date));

  return (
    <AppShell>
      {loading ? (
        <LoadingPanel label="로그인 정보를 확인하는 중입니다..." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : loadingData ? (
        <LoadingPanel label="대시보드를 불러오는 중입니다..." />
      ) : (
        <div className="grid gap-5">
          <section className="grid gap-3 md:grid-cols-4">
            <Metric label="전체 진행률" value={`${percent}%`} icon={TrendingUp} />
            <Metric label="완료한 단원" value={`${completedCount}/${totalLessons}`} icon={CheckCircle2} />
            <Metric label="오늘 복습" value={`${state.reviews.length}`} icon={CalendarCheck2} />
            <Metric label="누적 오답" value={`${state.wrongNotes.length}`} icon={FileQuestion} />
            <Metric label="연속 학습" value={`${streakDays}일`} icon={Flame} />
            <Metric label="총 학습시간" value={formatMinutes(totalStudyMinutes)} icon={Clock3} />
            <Metric label="최근 메모" value={`${state.notes.length}`} icon={NotebookText} />
            <Metric label="취약개념" value={`${weakConcepts.length}`} icon={TrendingDown} />
          </section>

          <section className="grid gap-5 lg:grid-cols-[1.1fr_0.9fr]">
            <Panel
              title="최근 학습"
              action={
                <Link href="/curriculum" className="inline-flex items-center gap-1 text-sm font-bold text-brand">
                  커리큘럼 <ArrowRight size={15} />
                </Link>
              }
            >
              {recentProgress.map((item) => {
                const lesson = lessonMap.get(item.lesson_id);
                return (
                  <Link key={item.id} href={`/learn/${item.lesson_id}`} className="rounded-md border border-line p-4 hover:border-brand">
                    <p className="font-black">{lesson?.title ?? "알 수 없는 단원"}</p>
                    <p className="mt-1 text-sm text-slate-600">
                      상태: {item.completed ? "완료" : "학습 중"} / 최근 학습 {formatDateTime(item.last_viewed_at)}
                    </p>
                  </Link>
                );
              })}
              {recentProgress.length === 0 && <Empty label="아직 학습 기록이 없습니다. 커리큘럼에서 첫 단원을 시작해 주세요." />}
            </Panel>

            <Panel
              title="오늘 복습"
              action={
                <Link href="/reviews" className="inline-flex items-center gap-1 text-sm font-bold text-brand">
                  복습 <ArrowRight size={15} />
                </Link>
              }
            >
              {state.reviews.slice(0, 4).map((review) => (
                <Link key={review.id} href={`/learn/${review.lesson_id}`} className="rounded-md border border-line p-4 hover:border-brand">
                  <p className="font-black">{lessonMap.get(review.lesson_id)?.title ?? "복습 단원"}</p>
                  <p className="mt-1 text-sm text-slate-600">
                    {review.review_step}일차 복습 / 예정일 {review.due_date}
                  </p>
                </Link>
              ))}
              {state.reviews.length === 0 && <Empty label="오늘 예정된 복습이 없습니다." />}
            </Panel>
          </section>

          <section className="grid gap-5 lg:grid-cols-3">
            <Panel title="취약개념 TOP5">
              {weakConcepts.map((concept) => (
                <Link key={concept.id} href={`/learn/${concept.lesson_id}`} className="rounded-md bg-red-50 p-4">
                  <p className="font-black text-danger">{concept.concept_name}</p>
                  <p className="mt-1 text-sm text-slate-700">
                    이해도 {concept.mastery_score}% / {lessonMap.get(concept.lesson_id)?.title ?? "단원"}
                  </p>
                  {concept.note && <p className="mt-2 text-sm leading-6 text-slate-600">{concept.note}</p>}
                </Link>
              ))}
              {weakConcepts.length === 0 && <Empty label="아직 저장된 취약개념이 없습니다." />}
            </Panel>

            <Panel title="최근 학습일지">
              {state.journals.slice(0, 3).map((journal) => (
                <Link key={journal.id} href={journal.lesson_id ? `/learn/${journal.lesson_id}` : "/curriculum"} className="rounded-md bg-slate-50 p-4">
                  <p className="font-black">{journal.journal_date}</p>
                  <p className="mt-1 text-sm text-slate-600">
                    {formatMinutes(journal.study_minutes)} / 이해도 {journal.understanding_score}%
                  </p>
                  <p className="mt-2 line-clamp-3 text-sm leading-6 text-slate-700">{journal.content || "작성한 내용 없음"}</p>
                </Link>
              ))}
              {state.journals.length === 0 && <Empty label="아직 저장된 학습일지가 없습니다." />}
            </Panel>

            <Panel title="다음 학습">
              {state.lessons
                .filter((lesson) => !state.progress.some((item) => item.lesson_id === lesson.id && item.completed))
                .slice(0, 3)
                .map((lesson) => (
                  <Link key={lesson.id} href={`/learn/${lesson.id}`} className="flex items-center justify-between gap-3 rounded-md border border-line p-4 hover:border-brand">
                    <div>
                      <p className="font-black">{lesson.title}</p>
                      <p className="mt-1 text-sm text-slate-600">{lesson.objective}</p>
                    </div>
                    <BookOpen size={18} className="shrink-0 text-brand" />
                  </Link>
                ))}
              {completedCount === totalLessons && totalLessons > 0 && <Empty label="현재 등록된 모든 단원을 완료했습니다." />}
              {totalLessons === 0 && <Empty label="커리큘럼 데이터가 없습니다. Supabase SQL을 먼저 실행해 주세요." />}
            </Panel>
          </section>

          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 className="text-lg font-black">오답노트 현황</h2>
                <p className="mt-1 text-sm text-slate-600">아직 해결하지 않은 오답이 {unresolvedWrongCount}개 남아 있습니다.</p>
              </div>
              <Link href="/wrong-notes" className="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-danger px-4 text-sm font-black text-white">
                오답 다시 보기 <ArrowRight size={16} />
              </Link>
            </div>
          </section>
        </div>
      )}
    </AppShell>
  );
}

function Panel({ title, action, children }: { title: string; action?: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-lg font-black">{title}</h2>
        {action}
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

function formatDateTime(value: string | null) {
  if (!value) return "-";
  return new Intl.DateTimeFormat("ko-KR", { dateStyle: "short", timeStyle: "short" }).format(new Date(value));
}

function formatMinutes(minutes: number) {
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  if (hours === 0) return `${rest}분`;
  if (rest === 0) return `${hours}시간`;
  return `${hours}시간 ${rest}분`;
}

function calculateStreakDays(dateValues: string[]) {
  const dates = new Set(dateValues.map((value) => value.slice(0, 10)));
  const cursor = new Date(toIsoDate(new Date()));
  let streak = 0;

  while (dates.has(toIsoDate(cursor))) {
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }

  return streak;
}

function toIsoDate(date: Date) {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}
