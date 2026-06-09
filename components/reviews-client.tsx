"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, CheckCircle2, Clock3, TrendingDown } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { ConceptMastery, Lesson, ReviewSchedule } from "@/lib/types";

type ReviewState = {
  lessons: Lesson[];
  reviews: ReviewSchedule[];
  concepts: ConceptMastery[];
};

export function ReviewsClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<ReviewState>({ lessons: [], reviews: [], concepts: [] });
  const [dataError, setDataError] = useState("");
  const [loadingData, setLoadingData] = useState(true);

  async function loadReviews() {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;

    setLoadingData(true);
    setDataError("");

    const [lessonsResult, reviewsResult, conceptsResult] = await Promise.all([
      supabase.from("lessons").select("*").order("sort_order", { ascending: true }),
      supabase.from("review_schedule").select("*").eq("user_id", currentUser.id).order("due_date", { ascending: true }),
      supabase.from("concept_mastery").select("*").eq("user_id", currentUser.id).order("mastery_score", { ascending: true })
    ]);

    const firstError = lessonsResult.error || reviewsResult.error || conceptsResult.error;
    if (firstError) {
      setDataError(firstError.message);
      setLoadingData(false);
      return;
    }

    setState({
      lessons: (lessonsResult.data ?? []) as Lesson[],
      reviews: (reviewsResult.data ?? []) as ReviewSchedule[],
      concepts: (conceptsResult.data ?? []) as ConceptMastery[]
    });
    setLoadingData(false);
  }

  useEffect(() => {
    loadReviews();
    // loadReviews depends on auth state and is intentionally refreshed when it changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [client, user]);

  const lessonMap = useMemo(() => new Map(state.lessons.map((lesson) => [lesson.id, lesson])), [state.lessons]);
  const today = toIsoDate(new Date());
  const dueReviews = state.reviews.filter((review) => !review.completed && review.due_date <= today);
  const upcomingReviews = state.reviews.filter((review) => !review.completed && review.due_date > today).slice(0, 8);
  const completedReviews = state.reviews.filter((review) => review.completed).slice(0, 6);
  const weakConcepts = state.concepts.filter((concept) => concept.is_weak || concept.mastery_score <= 60).slice(0, 8);

  async function completeReview(review: ReviewSchedule) {
    if (!client || !user) return;
    const now = new Date().toISOString();

    await client
      .from("review_schedule")
      .update({ completed: true, completed_at: now, updated_at: now })
      .eq("id", review.id)
      .eq("user_id", user.id);

    await client
      .from("concept_mastery")
      .update({ last_reviewed_at: now, updated_at: now })
      .eq("user_id", user.id)
      .eq("lesson_id", review.lesson_id);

    await loadReviews();
  }

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="복습 일정을 불러오는 중입니다." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : (
        <div className="grid gap-5">
          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <h2 className="text-xl font-black">복습관리</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">단원을 완료하면 1일, 3일, 7일, 14일 복습 일정이 자동 생성됩니다.</p>
          </section>

          <section className="grid gap-5 lg:grid-cols-[1.1fr_0.9fr]">
            <Panel title={`오늘 복습 ${dueReviews.length}개`}>
              {dueReviews.map((review) => (
                <ReviewCard key={review.id} review={review} lesson={lessonMap.get(review.lesson_id)} overdue={review.due_date < today} onComplete={() => completeReview(review)} />
              ))}
              {dueReviews.length === 0 && <Empty label="오늘 처리할 복습이 없습니다." />}
            </Panel>

            <Panel title="취약개념">
              {weakConcepts.map((concept) => (
                <Link key={concept.id} href={`/learn/${concept.lesson_id}`} className="rounded-md bg-red-50 p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-black text-danger">{concept.concept_name}</p>
                      <p className="mt-1 text-sm text-slate-700">
                        이해도 {concept.mastery_score}점 · {lessonMap.get(concept.lesson_id)?.title ?? "단원"}
                      </p>
                    </div>
                    <TrendingDown size={18} className="shrink-0 text-danger" />
                  </div>
                  {concept.note && <p className="mt-2 text-sm leading-6 text-slate-600">{concept.note}</p>}
                </Link>
              ))}
              {weakConcepts.length === 0 && <Empty label="등록된 취약개념이 없습니다." />}
            </Panel>
          </section>

          <section className="grid gap-5 lg:grid-cols-2">
            <Panel title="예정 복습">
              {upcomingReviews.map((review) => (
                <Link key={review.id} href={`/learn/${review.lesson_id}`} className="rounded-md border border-line p-4 hover:border-brand">
                  <p className="font-black">{lessonMap.get(review.lesson_id)?.title ?? "복습 단원"}</p>
                  <p className="mt-1 text-sm text-slate-600">
                    {review.review_step}일 복습 · {review.due_date}
                  </p>
                </Link>
              ))}
              {upcomingReviews.length === 0 && <Empty label="예정된 복습이 없습니다." />}
            </Panel>

            <Panel title="완료한 복습">
              {completedReviews.map((review) => (
                <div key={review.id} className="rounded-md bg-emerald-50 p-4">
                  <p className="font-black text-emerald-800">{lessonMap.get(review.lesson_id)?.title ?? "복습 단원"}</p>
                  <p className="mt-1 text-sm text-slate-700">
                    {review.review_step}일 복습 · 완료 {formatDateTime(review.completed_at)}
                  </p>
                </div>
              ))}
              {completedReviews.length === 0 && <Empty label="완료한 복습 기록이 없습니다." />}
            </Panel>
          </section>
        </div>
      )}
    </AppShell>
  );
}

function ReviewCard({ review, lesson, overdue, onComplete }: { review: ReviewSchedule; lesson?: Lesson; overdue: boolean; onComplete: () => void }) {
  return (
    <article className={clsx("rounded-md border p-4", overdue ? "border-danger bg-red-50" : "border-line bg-white")}>
      <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <div>
          <p className="font-black">{lesson?.title ?? "복습 단원"}</p>
          <p className="mt-1 inline-flex items-center gap-2 text-sm text-slate-600">
            <Clock3 size={15} />
            {review.review_step}일 복습 · 마감 {review.due_date}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Link href={`/learn/${review.lesson_id}`} className="inline-flex h-9 items-center gap-2 rounded-md border border-line bg-white px-3 text-sm font-black">
            학습 열기 <ArrowRight size={15} />
          </Link>
          <button onClick={onComplete} className="inline-flex h-9 items-center gap-2 rounded-md bg-brand px-3 text-sm font-black text-white">
            <CheckCircle2 size={15} /> 복습 완료
          </button>
        </div>
      </div>
    </article>
  );
}

function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <h2 className="text-lg font-black">{title}</h2>
      <div className="mt-4 grid gap-3">{children}</div>
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

function toIsoDate(date: Date) {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}
