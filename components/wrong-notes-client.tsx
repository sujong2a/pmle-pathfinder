"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, CheckCircle2, CircleAlert, RotateCcw } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { Lesson, Quiz, QuizOption, WrongNote } from "@/lib/types";

type WrongNoteState = {
  notes: WrongNote[];
  quizzes: Quiz[];
  lessons: Lesson[];
  options: QuizOption[];
};

type Filter = "all" | "open" | "resolved";

export function WrongNotesClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<WrongNoteState>({ notes: [], quizzes: [], lessons: [], options: [] });
  const [filter, setFilter] = useState<Filter>("open");
  const [loadingData, setLoadingData] = useState(true);
  const [dataError, setDataError] = useState("");

  async function loadWrongNotes() {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;
    setLoadingData(true);
    setDataError("");

    const notesResult = await supabase.from("wrong_notes").select("*").eq("user_id", currentUser.id).order("updated_at", { ascending: false });
    if (notesResult.error) {
      setDataError(notesResult.error.message);
      setLoadingData(false);
      return;
    }

    const notes = (notesResult.data ?? []) as WrongNote[];
    const quizIds = notes.map((note) => note.quiz_id);
    let quizzes: Quiz[] = [];
    let lessons: Lesson[] = [];
    let options: QuizOption[] = [];

    if (quizIds.length > 0) {
      const quizzesResult = await supabase.from("quizzes").select("*").in("id", quizIds);
      if (quizzesResult.error) {
        setDataError(quizzesResult.error.message);
        setLoadingData(false);
        return;
      }

      quizzes = (quizzesResult.data ?? []) as Quiz[];
      const lessonIds = [...new Set(quizzes.map((quiz) => quiz.lesson_id))];
      const optionIds = [...new Set(notes.flatMap((note) => [note.selected_option_id, note.correct_option_id]).filter(Boolean))] as string[];

      const [lessonsResult, optionsResult] = await Promise.all([
        lessonIds.length ? supabase.from("lessons").select("*").in("id", lessonIds) : Promise.resolve({ data: [], error: null }),
        optionIds.length ? supabase.from("quiz_options").select("*").in("id", optionIds) : Promise.resolve({ data: [], error: null })
      ]);

      const firstError = lessonsResult.error || optionsResult.error;
      if (firstError) {
        setDataError(firstError.message);
        setLoadingData(false);
        return;
      }

      lessons = (lessonsResult.data ?? []) as Lesson[];
      options = (optionsResult.data ?? []) as QuizOption[];
    }

    setState({ notes, quizzes, lessons, options });
    setLoadingData(false);
  }

  useEffect(() => {
    loadWrongNotes();
    // loadWrongNotes uses current auth state and is intentionally re-run when those values change.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [client, user]);

  const quizMap = useMemo(() => new Map(state.quizzes.map((quiz) => [quiz.id, quiz])), [state.quizzes]);
  const lessonMap = useMemo(() => new Map(state.lessons.map((lesson) => [lesson.id, lesson])), [state.lessons]);
  const optionMap = useMemo(() => new Map(state.options.map((option) => [option.id, option])), [state.options]);
  const filteredNotes = state.notes.filter((note) => {
    if (filter === "open") return !note.resolved;
    if (filter === "resolved") return note.resolved;
    return true;
  });

  async function toggleResolved(note: WrongNote) {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;
    const now = new Date().toISOString();
    await supabase
      .from("wrong_notes")
      .update({
        resolved: !note.resolved,
        resolved_at: note.resolved ? null : now,
        updated_at: now
      })
      .eq("id", note.id)
      .eq("user_id", currentUser.id);
    await loadWrongNotes();
  }

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="오답노트를 불러오는 중입니다." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : (
        <div className="grid gap-5">
          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
              <div>
                <h2 className="text-xl font-black">오답노트</h2>
                <p className="mt-2 text-sm leading-6 text-slate-600">틀린 문제는 자동 저장됩니다. 원래 단원으로 돌아가 다시 풀 수 있습니다.</p>
              </div>
              <div className="grid grid-cols-3 rounded-md border border-line bg-slate-50 p-1">
                {(["open", "all", "resolved"] as const).map((item) => (
                  <button
                    key={item}
                    onClick={() => setFilter(item)}
                    className={clsx("h-9 rounded px-3 text-sm font-black", filter === item ? "bg-white text-ink shadow-sm" : "text-slate-600")}
                  >
                    {item === "open" ? "미해결" : item === "resolved" ? "해결" : "전체"}
                  </button>
                ))}
              </div>
            </div>
          </section>

          <section className="grid gap-3">
            {filteredNotes.map((note) => {
              const quiz = quizMap.get(note.quiz_id);
              const lesson = quiz ? lessonMap.get(quiz.lesson_id) : undefined;
              const selectedOption = note.selected_option_id ? optionMap.get(note.selected_option_id) : undefined;
              const correctOption = note.correct_option_id ? optionMap.get(note.correct_option_id) : undefined;

              return (
                <article key={note.id} className="rounded-lg border border-line bg-white p-5 shadow-soft">
                  <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
                    <div>
                      <div
                        className={clsx(
                          "inline-flex items-center gap-2 rounded-full px-2 py-1 text-xs font-black",
                          note.resolved ? "bg-emerald-50 text-emerald-700" : "bg-red-50 text-danger"
                        )}
                      >
                        {note.resolved ? <CheckCircle2 size={14} /> : <CircleAlert size={14} />}
                        {note.resolved ? "해결됨" : "다시 풀기 필요"}
                      </div>
                      <h3 className="mt-3 text-lg font-black">{note.question_snapshot}</h3>
                      <p className="mt-1 text-sm font-semibold text-slate-500">{lesson?.title ?? "단원 정보 없음"}</p>
                    </div>
                    {lesson && (
                      <Link href={`/learn/${lesson.id}`} className="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-brand px-3 text-sm font-black text-white">
                        <RotateCcw size={16} /> 다시 풀기
                      </Link>
                    )}
                  </div>

                  <div className="mt-4 grid gap-3 md:grid-cols-2">
                    <AnswerBox label="내가 고른 답" value={selectedOption?.option_text ?? "기록 없음"} tone="wrong" />
                    <AnswerBox label="정답" value={correctOption?.option_text ?? "기록 없음"} tone="correct" />
                  </div>

                  <p className="mt-4 rounded-md bg-slate-50 p-4 text-sm leading-6 text-slate-700">{note.explanation_snapshot}</p>

                  <div className="mt-4 flex flex-wrap items-center gap-2">
                    <span className="rounded-full bg-slate-50 px-3 py-1 text-xs font-black text-slate-600">누적 오답 {note.attempt_count}회</span>
                    <button onClick={() => toggleResolved(note)} className="inline-flex h-9 items-center gap-2 rounded-md border border-line px-3 text-sm font-black">
                      {note.resolved ? "미해결로 변경" : "해결 처리"} <ArrowRight size={15} />
                    </button>
                  </div>
                </article>
              );
            })}

            {filteredNotes.length === 0 && (
              <div className="rounded-lg border border-line bg-white p-8 text-center shadow-soft">
                <p className="font-black">표시할 오답이 없습니다.</p>
                <Link href="/curriculum" className="mt-4 inline-flex h-10 items-center justify-center gap-2 rounded-md bg-ink px-4 text-sm font-black text-white">
                  커리큘럼으로 이동 <ArrowRight size={16} />
                </Link>
              </div>
            )}
          </section>
        </div>
      )}
    </AppShell>
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
