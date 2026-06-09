"use client";

import { useEffect, useMemo, useState } from "react";
import { CheckCircle2, Code2, History, RotateCcw, Send, Sparkles, XCircle } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type { CodingFeedback, CodingSubmission, CodingTask } from "@/lib/types";

type CodingLabState = {
  tasks: CodingTask[];
  submissions: CodingSubmission[];
  feedback: CodingFeedback[];
};

export function CodingLabClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<CodingLabState>({ tasks: [], submissions: [], feedback: [] });
  const [activeTaskId, setActiveTaskId] = useState("");
  const [code, setCode] = useState("");
  const [userExpectedOutput, setUserExpectedOutput] = useState("");
  const [dataError, setDataError] = useState("");
  const [loadingData, setLoadingData] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [latestSubmissionId, setLatestSubmissionId] = useState("");

  const activeTask = useMemo(() => state.tasks.find((task) => task.id === activeTaskId) ?? state.tasks[0], [activeTaskId, state.tasks]);
  const taskSubmissions = state.submissions.filter((submission) => submission.task_id === activeTask?.id);
  const latestFeedback = state.feedback.find((item) => item.submission_id === latestSubmissionId) ?? state.feedback.find((item) => item.task_id === activeTask?.id);

  async function getAccessToken() {
    const supabase = getSupabaseBrowserClient();
    const { data } = await supabase.auth.getSession();
    return data.session?.access_token ?? "";
  }

  async function loadCodingData() {
    if (!client || !user) return;
    setLoadingData(true);
    setDataError("");

    try {
      const token = await getAccessToken();
      const response = await fetch("/api/coding-tasks", {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await response.json();

      if (!response.ok) throw new Error(data.error ?? "실습 데이터를 불러오지 못했습니다.");

      setState({
        tasks: data.tasks ?? [],
        submissions: data.submissions ?? [],
        feedback: data.feedback ?? []
      });

      const nextTask = activeTaskId || data.tasks?.[0]?.id || "";
      setActiveTaskId(nextTask);
      const selectedTask = data.tasks?.find((task: CodingTask) => task.id === nextTask) ?? data.tasks?.[0];
      if (selectedTask && !code) {
        setCode(selectedTask.starter_code ?? "");
        setUserExpectedOutput("");
      }
    } catch (error) {
      setDataError(error instanceof Error ? error.message : "실습 데이터를 불러오지 못했습니다.");
    } finally {
      setLoadingData(false);
    }
  }

  useEffect(() => {
    loadCodingData();
    // 인증 상태가 준비된 뒤 최초 1회 데이터를 가져옵니다.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [client, user]);

  function selectTask(task: CodingTask) {
    setActiveTaskId(task.id);
    setCode(task.starter_code ?? "");
    setUserExpectedOutput("");
    setLatestSubmissionId("");
  }

  async function submitCode() {
    if (!activeTask) return;
    setSubmitting(true);
    setDataError("");

    try {
      const token = await getAccessToken();
      const response = await fetch("/api/coding-tasks", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          taskId: activeTask.id,
          code,
          userExpectedOutput
        })
      });
      const data = await response.json();

      if (!response.ok) throw new Error(data.error ?? "실습 제출에 실패했습니다.");

      setLatestSubmissionId(data.submission.id);
      setState((current) => ({
        ...current,
        submissions: [data.submission, ...current.submissions],
        feedback: [data.feedback, ...current.feedback]
      }));
    } catch (error) {
      setDataError(error instanceof Error ? error.message : "실습 제출에 실패했습니다.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="실습 과제를 불러오는 중입니다..." />
      ) : error || dataError ? (
        <div className="grid gap-4">
          <ErrorPanel message={error || dataError} />
          {activeTask && (
            <CodingWorkspace
              task={activeTask}
              tasks={state.tasks}
              selectTask={selectTask}
              code={code}
              setCode={setCode}
              userExpectedOutput={userExpectedOutput}
              setUserExpectedOutput={setUserExpectedOutput}
              submitCode={submitCode}
              submitting={submitting}
              submissions={taskSubmissions}
              feedback={latestFeedback}
            />
          )}
        </div>
      ) : activeTask ? (
        <CodingWorkspace
          task={activeTask}
          tasks={state.tasks}
          selectTask={selectTask}
          code={code}
          setCode={setCode}
          userExpectedOutput={userExpectedOutput}
          setUserExpectedOutput={setUserExpectedOutput}
          submitCode={submitCode}
          submitting={submitting}
          submissions={taskSubmissions}
          feedback={latestFeedback}
        />
      ) : (
        <ErrorPanel message="등록된 실습 과제가 없습니다. MVP4 SQL 마이그레이션을 먼저 실행해 주세요." />
      )}
    </AppShell>
  );
}

function CodingWorkspace({
  task,
  tasks,
  selectTask,
  code,
  setCode,
  userExpectedOutput,
  setUserExpectedOutput,
  submitCode,
  submitting,
  submissions,
  feedback
}: {
  task: CodingTask;
  tasks: CodingTask[];
  selectTask: (task: CodingTask) => void;
  code: string;
  setCode: (value: string) => void;
  userExpectedOutput: string;
  setUserExpectedOutput: (value: string) => void;
  submitCode: () => void;
  submitting: boolean;
  submissions: CodingSubmission[];
  feedback?: CodingFeedback;
}) {
  return (
    <div className="grid gap-5 lg:grid-cols-[300px_minmax(0,1fr)_360px]">
      <aside className="rounded-lg border border-line bg-white p-4 shadow-soft">
        <h2 className="text-lg font-black">Python 실습 과제</h2>
        <div className="mt-4 grid gap-2">
          {tasks.map((item) => (
            <button
              key={item.id}
              onClick={() => selectTask(item)}
              className={clsx(
                "rounded-md border p-3 text-left text-sm transition",
                item.id === task.id ? "border-ink bg-ink text-white" : "border-line bg-white text-slate-700 hover:border-brand"
              )}
            >
              <p className="font-black">{item.title}</p>
              <p className="mt-1 text-xs opacity-75">{difficultyLabel(item.difficulty)}</p>
            </button>
          ))}
        </div>
      </aside>

      <section className="grid gap-5">
        <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">실제 코드 실행 없음</p>
              <h1 className="mt-1 text-2xl font-black">{task.title}</h1>
              <p className="mt-2 text-sm leading-6 text-slate-600">{task.description}</p>
            </div>
            <Code2 size={24} className="text-brand" />
          </div>
          <div className="mt-4 rounded-md bg-slate-50 p-4 text-sm leading-6 text-slate-700">
            <p className="font-black">요구사항</p>
            <p className="mt-1 whitespace-pre-wrap">{task.instructions}</p>
          </div>
        </div>

        <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-lg font-black">코드 에디터</h2>
            <button onClick={() => setCode(task.starter_code ?? "")} className="inline-flex h-9 items-center gap-2 rounded-md border border-line px-3 text-sm font-black">
              <RotateCcw size={15} /> 초기화
            </button>
          </div>
          <textarea
            value={code}
            onChange={(event) => setCode(event.target.value)}
            spellCheck={false}
            rows={16}
            className="mt-3 w-full resize-y rounded-md border border-line bg-ink p-4 font-mono text-sm leading-7 text-white"
          />
          <div className="mt-4 grid gap-3 md:grid-cols-2">
            <label className="grid gap-1 text-sm font-bold text-slate-700">
              내가 예상한 출력
              <textarea
                value={userExpectedOutput}
                onChange={(event) => setUserExpectedOutput(event.target.value)}
                rows={5}
                className="rounded-md border border-line p-3 font-mono text-sm leading-6"
                placeholder="코드를 실행한다고 생각했을 때 화면에 나올 출력값을 적어보세요."
              />
            </label>
            <div className="rounded-md bg-slate-50 p-4">
              <p className="text-sm font-black">평가 기준</p>
              <ul className="mt-2 grid gap-1 text-sm leading-6 text-slate-700">
                <li>예상 출력 비교</li>
                <li>필수 키워드: {task.required_keywords.join(", ") || "없음"}</li>
                <li>정답 패턴 검사</li>
                <li>실제 코드 실행 없음</li>
              </ul>
            </div>
          </div>
          <button
            onClick={submitCode}
            disabled={submitting}
            className="mt-4 inline-flex h-11 items-center justify-center gap-2 rounded-md bg-brand px-5 text-sm font-black text-white disabled:bg-slate-400"
          >
            <Send size={16} /> {submitting ? "제출 중..." : "실습 제출"}
          </button>
        </div>
      </section>

      <aside className="grid h-fit gap-5">
        <FeedbackPanel feedback={feedback} />
        <SubmissionHistory submissions={submissions} />
      </aside>
    </div>
  );
}

function FeedbackPanel({ feedback }: { feedback?: CodingFeedback }) {
  if (!feedback) {
    return (
      <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
        <h2 className="text-lg font-black">AI 피드백</h2>
        <p className="mt-3 rounded-md bg-slate-50 p-4 text-sm leading-6 text-slate-600">제출하면 개선점, 추천 학습, 재제출 힌트가 표시됩니다.</p>
      </section>
    );
  }

  return (
    <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-lg font-black">AI 피드백</h2>
        <Sparkles size={18} className="text-brand" />
      </div>
      <div className="mt-4 rounded-md bg-blue-50 p-4 text-sm leading-7 text-slate-800">
        <p className="whitespace-pre-wrap">{feedback.ai_feedback || feedback.feedback}</p>
      </div>
      <div className="mt-4 grid gap-3">
        <MiniList title="개선점" items={feedback.improvements} />
        <MiniList title="추천 학습" items={feedback.recommended_study} />
      </div>
    </section>
  );
}

function SubmissionHistory({ submissions }: { submissions: CodingSubmission[] }) {
  return (
    <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-lg font-black">제출 기록</h2>
        <History size={18} className="text-brand" />
      </div>
      <div className="mt-4 grid gap-3">
        {submissions.map((submission) => (
          <article key={submission.id} className="rounded-md border border-line p-4">
            <div className="flex items-center justify-between gap-3">
              <p className="font-black">#{submission.attempt_number}</p>
              <span className={clsx("inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-black", submission.status === "passed" ? "bg-emerald-50 text-emerald-700" : "bg-red-50 text-danger")}>
                {submission.status === "passed" ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                {submission.status === "passed" ? "통과" : "재제출"}
              </span>
            </div>
            <p className="mt-2 text-sm text-slate-600">점수 {submission.score}점</p>
          </article>
        ))}
        {submissions.length === 0 && <p className="rounded-md bg-slate-50 p-4 text-sm font-semibold text-slate-500">아직 제출 기록이 없습니다.</p>}
      </div>
    </section>
  );
}

function MiniList({ title, items }: { title: string; items: string[] }) {
  return (
    <div>
      <p className="text-sm font-black">{title}</p>
      <ul className="mt-2 grid gap-1 text-sm leading-6 text-slate-700">
        {items.map((item) => (
          <li key={item}>- {item}</li>
        ))}
      </ul>
    </div>
  );
}

function difficultyLabel(value: string) {
  if (value === "easy") return "초급";
  if (value === "medium") return "중급";
  return "고급";
}
