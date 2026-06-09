"use client";

import { useEffect, useMemo, useState } from "react";
import { Bot, BookmarkPlus, MessageSquare, Plus, Send, Sparkles } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import { useRequiredUser } from "@/lib/supabase/use-required-user";

type ChatSession = {
  id: string;
  title: string;
  lesson_id: string | null;
  created_at: string;
  updated_at: string;
};

type ChatMessage = {
  id: string;
  session_id: string;
  role: "user" | "assistant";
  content: string;
  created_at: string;
};

type SavedExplanation = {
  id: string;
  title: string;
  content: string;
  source_question: string;
  created_at: string;
};

const starterPrompts = [
  "변수와 자료형 차이를 초등학생도 이해할 수 있게 설명해줘.",
  "내 오답노트를 보고 지금 먼저 복습할 개념을 추천해줘.",
  "함수를 왜 쓰는지 비유와 단계별 예제로 알려줘.",
  "Pandas가 뭔지 Python 초보 기준으로 힌트부터 설명해줘."
];

export function AiTutorClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [savedExplanations, setSavedExplanations] = useState<SavedExplanation[]>([]);
  const [activeSessionId, setActiveSessionId] = useState<string>("");
  const [input, setInput] = useState("");
  const [dataError, setDataError] = useState("");
  const [loadingData, setLoadingData] = useState(true);
  const [sending, setSending] = useState(false);
  const [savingMessageId, setSavingMessageId] = useState("");

  const lastUserQuestion = useMemo(() => {
    const userMessages = messages.filter((message) => message.role === "user");
    return userMessages[userMessages.length - 1]?.content ?? "";
  }, [messages]);

  async function getAccessToken() {
    const supabase = getSupabaseBrowserClient();
    const { data } = await supabase.auth.getSession();
    return data.session?.access_token ?? "";
  }

  async function loadTutorData(sessionId = activeSessionId) {
    if (!client || !user) return;
    setLoadingData(true);
    setDataError("");

    try {
      const token = await getAccessToken();
      const query = sessionId ? `?sessionId=${encodeURIComponent(sessionId)}` : "";
      const response = await fetch(`/api/ai-tutor${query}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await response.json();

      if (!response.ok) throw new Error(data.error ?? "AI 튜터 데이터를 불러오지 못했습니다.");

      setSessions(data.sessions ?? []);
      setSavedExplanations(data.savedExplanations ?? []);
      setMessages(data.messages ?? []);
      if (!sessionId && data.sessions?.[0]?.id) setActiveSessionId(data.sessions[0].id);
    } catch (error) {
      setDataError(error instanceof Error ? error.message : "AI 튜터 데이터를 불러오지 못했습니다.");
    } finally {
      setLoadingData(false);
    }
  }

  useEffect(() => {
    loadTutorData("");
    // Initial load runs after auth state is available.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [client, user]);

  async function selectSession(sessionId: string) {
    setActiveSessionId(sessionId);
    await loadTutorData(sessionId);
  }

  async function sendMessage(promptText = input) {
    const message = promptText.trim();
    if (!message) return;

    setSending(true);
    setDataError("");
    setInput("");

    try {
      const token = await getAccessToken();
      const response = await fetch("/api/ai-tutor", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          action: "send_message",
          message,
          sessionId: activeSessionId || undefined
        })
      });
      const data = await response.json();

      if (!response.ok) throw new Error(data.error ?? "AI 튜터 응답 생성에 실패했습니다.");

      setActiveSessionId(data.session.id);
      setMessages((current) => [...current, data.userMessage, data.assistantMessage]);
      await loadTutorData(data.session.id);
    } catch (error) {
      setDataError(error instanceof Error ? error.message : "AI 튜터 응답 생성에 실패했습니다.");
    } finally {
      setSending(false);
    }
  }

  async function saveExplanation(message: ChatMessage) {
    if (message.role !== "assistant") return;
    setSavingMessageId(message.id);
    setDataError("");

    try {
      const token = await getAccessToken();
      const response = await fetch("/api/ai-tutor", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          action: "save_explanation",
          title: makeExplanationTitle(lastUserQuestion || message.content),
          content: message.content,
          sourceQuestion: lastUserQuestion,
          sessionId: message.session_id,
          messageId: message.id
        })
      });
      const data = await response.json();

      if (!response.ok) throw new Error(data.error ?? "AI 설명 저장에 실패했습니다.");

      setSavedExplanations((current) => [data.savedExplanation, ...current]);
    } catch (error) {
      setDataError(error instanceof Error ? error.message : "AI 설명 저장에 실패했습니다.");
    } finally {
      setSavingMessageId("");
    }
  }

  function startNewSession() {
    setActiveSessionId("");
    setMessages([]);
    setInput("");
  }

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="AI 튜터를 불러오는 중입니다." />
      ) : error || dataError ? (
        <div className="grid gap-4">
          <ErrorPanel message={error || dataError} />
          <TutorLayout
            sessions={sessions}
            activeSessionId={activeSessionId}
            onSelectSession={selectSession}
            onNewSession={startNewSession}
            messages={messages}
            input={input}
            setInput={setInput}
            sendMessage={sendMessage}
            sending={sending}
            saveExplanation={saveExplanation}
            savingMessageId={savingMessageId}
            savedExplanations={savedExplanations}
          />
        </div>
      ) : (
        <TutorLayout
          sessions={sessions}
          activeSessionId={activeSessionId}
          onSelectSession={selectSession}
          onNewSession={startNewSession}
          messages={messages}
          input={input}
          setInput={setInput}
          sendMessage={sendMessage}
          sending={sending}
          saveExplanation={saveExplanation}
          savingMessageId={savingMessageId}
          savedExplanations={savedExplanations}
        />
      )}
    </AppShell>
  );
}

function TutorLayout({
  sessions,
  activeSessionId,
  onSelectSession,
  onNewSession,
  messages,
  input,
  setInput,
  sendMessage,
  sending,
  saveExplanation,
  savingMessageId,
  savedExplanations
}: {
  sessions: ChatSession[];
  activeSessionId: string;
  onSelectSession: (sessionId: string) => void;
  onNewSession: () => void;
  messages: ChatMessage[];
  input: string;
  setInput: (value: string) => void;
  sendMessage: (message?: string) => void;
  sending: boolean;
  saveExplanation: (message: ChatMessage) => void;
  savingMessageId: string;
  savedExplanations: SavedExplanation[];
}) {
  return (
    <div className="grid gap-5 lg:grid-cols-[300px_minmax(0,1fr)_330px]">
      <aside className="grid h-fit gap-5">
        <section className="rounded-lg border border-line bg-white p-4 shadow-soft">
          <button onClick={onNewSession} className="inline-flex h-10 w-full items-center justify-center gap-2 rounded-md bg-brand px-4 text-sm font-black text-white">
            <Plus size={16} /> 새 질문 시작
          </button>
          <div className="mt-4 grid gap-2">
            {sessions.map((session) => (
              <button
                key={session.id}
                onClick={() => onSelectSession(session.id)}
                className={clsx(
                  "rounded-md border p-3 text-left text-sm transition",
                  activeSessionId === session.id ? "border-ink bg-ink text-white" : "border-line bg-white text-slate-700 hover:border-brand"
                )}
              >
                <p className="line-clamp-2 font-black">{session.title}</p>
                <p className="mt-1 text-xs opacity-75">{formatDateTime(session.updated_at)}</p>
              </button>
            ))}
            {sessions.length === 0 && <Empty label="아직 AI 대화가 없습니다." />}
          </div>
        </section>
      </aside>

      <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">Gemini Tutor</p>
            <h2 className="mt-1 text-xl font-black">AI 질문하기</h2>
          </div>
          <Bot size={24} className="text-brand" />
        </div>

        <div className="mt-5 grid min-h-[420px] content-start gap-4">
          {messages.map((message) => (
            <article key={message.id} className={clsx("max-w-[88%] rounded-lg p-4", message.role === "user" ? "ml-auto bg-brand text-white" : "mr-auto bg-slate-50 text-ink")}>
              <div className="flex items-start justify-between gap-3">
                <p className="whitespace-pre-wrap text-sm leading-7">{message.content}</p>
                {message.role === "assistant" && (
                  <button
                    onClick={() => saveExplanation(message)}
                    className="shrink-0 rounded-md border border-line bg-white p-2 text-ink hover:border-brand"
                    title="AI 설명 저장"
                  >
                    {savingMessageId === message.id ? <Sparkles size={16} /> : <BookmarkPlus size={16} />}
                  </button>
                )}
              </div>
            </article>
          ))}
          {messages.length === 0 && (
            <div className="rounded-lg bg-slate-50 p-5">
              <p className="font-black">학습 도우미에게 질문하세요.</p>
              <p className="mt-2 text-sm leading-6 text-slate-600">진도, 오답노트, 취약개념을 참고해서 Python 초보자에게 맞는 힌트 중심 설명을 제공합니다.</p>
              <div className="mt-4 grid gap-2">
                {starterPrompts.map((prompt) => (
                  <button key={prompt} onClick={() => sendMessage(prompt)} className="rounded-md border border-line bg-white p-3 text-left text-sm font-bold hover:border-brand">
                    {prompt}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        <div className="mt-5 flex gap-2">
          <textarea
            value={input}
            onChange={(event) => setInput(event.target.value)}
            rows={3}
            className="min-h-20 flex-1 resize-none rounded-md border border-line p-3 text-sm leading-6"
            placeholder="예: 반복문이 왜 필요한지 힌트부터 설명해줘."
          />
          <button
            onClick={() => sendMessage()}
            disabled={sending}
            className="inline-flex w-24 items-center justify-center gap-2 rounded-md bg-ink px-4 text-sm font-black text-white disabled:bg-slate-400"
          >
            <Send size={16} /> {sending ? "전송" : "질문"}
          </button>
        </div>
      </section>

      <aside className="grid h-fit gap-5">
        <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
          <div className="flex items-center justify-between gap-3">
            <h3 className="text-lg font-black">AI 학습 도우미</h3>
            <MessageSquare size={18} className="text-brand" />
          </div>
          <div className="mt-4 grid gap-3 text-sm leading-6 text-slate-700">
            <p className="rounded-md bg-slate-50 p-3">질문하면 정답보다 힌트를 먼저 주고, 단계별 사고 과정을 유도합니다.</p>
            <p className="rounded-md bg-slate-50 p-3">오답노트와 취약개념이 있으면 그 부분을 우선 참고해 설명합니다.</p>
            <p className="rounded-md bg-slate-50 p-3">저장 버튼을 누르면 좋은 설명을 다시 볼 수 있게 보관합니다.</p>
          </div>
        </section>

        <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
          <h3 className="text-lg font-black">저장한 AI 설명</h3>
          <div className="mt-4 grid gap-3">
            {savedExplanations.slice(0, 6).map((item) => (
              <article key={item.id} className="rounded-md bg-slate-50 p-4">
                <p className="font-black">{item.title}</p>
                <p className="mt-2 line-clamp-4 text-sm leading-6 text-slate-700">{item.content}</p>
              </article>
            ))}
            {savedExplanations.length === 0 && <Empty label="저장한 설명이 없습니다." />}
          </div>
        </section>
      </aside>
    </div>
  );
}

function Empty({ label }: { label: string }) {
  return <p className="rounded-md bg-slate-50 p-4 text-sm font-semibold text-slate-500">{label}</p>;
}

function makeExplanationTitle(source: string) {
  const trimmed = source.replace(/\s+/g, " ").trim();
  if (!trimmed) return "AI 설명";
  return trimmed.length > 24 ? `${trimmed.slice(0, 24)}...` : trimmed;
}

function formatDateTime(value: string | null) {
  if (!value) return "-";
  return new Intl.DateTimeFormat("ko-KR", { dateStyle: "short", timeStyle: "short" }).format(new Date(value));
}
