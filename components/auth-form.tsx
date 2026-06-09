"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LogIn, UserPlus } from "lucide-react";
import clsx from "clsx";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import { ensureUserProfile } from "@/lib/supabase/profile";

type AuthMode = "login" | "signup";

export function AuthForm() {
  const router = useRouter();
  const [mode, setMode] = useState<AuthMode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage("");

    try {
      const client = getSupabaseBrowserClient();

      if (mode === "signup") {
        const { data, error } = await client.auth.signUp({
          email,
          password,
          options: { data: { display_name: displayName } }
        });

        if (error) throw error;
        if (data.user) await ensureUserProfile(client, data.user, displayName);

        if (data.session) {
          router.replace("/dashboard");
          return;
        }

        setMessage("회원가입이 완료되었습니다. Supabase 이메일 인증이 켜져 있으면 메일 확인 후 로그인하세요.");
        return;
      }

      const { data, error } = await client.auth.signInWithPassword({ email, password });
      if (error) throw error;
      if (data.user) await ensureUserProfile(client, data.user);
      router.replace("/dashboard");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "인증 처리 중 오류가 발생했습니다.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="grid min-h-screen place-items-center bg-paper px-4 py-8 text-ink">
      <section className="w-full max-w-md rounded-lg border border-line bg-white p-5 shadow-soft">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">PMLE Pathfinder</p>
          <h1 className="mt-2 text-2xl font-black">학습 계정</h1>
          <p className="mt-2 text-sm leading-6 text-slate-600">Python 기초 단원부터 진행률, 메모, 오답노트를 사용자별로 저장합니다.</p>
        </div>

        <div className="mt-5 grid grid-cols-2 rounded-md border border-line bg-slate-50 p-1">
          {(["login", "signup"] as const).map((item) => (
            <button
              key={item}
              type="button"
              onClick={() => {
                setMode(item);
                setMessage("");
              }}
              className={clsx(
                "h-10 rounded px-3 text-sm font-bold",
                mode === item ? "bg-white text-ink shadow-sm" : "text-slate-600"
              )}
            >
              {item === "login" ? "로그인" : "회원가입"}
            </button>
          ))}
        </div>

        <form onSubmit={submit} className="mt-5 grid gap-4">
          {mode === "signup" && (
            <label className="grid gap-1 text-sm font-bold text-slate-700">
              이름
              <input
                value={displayName}
                onChange={(event) => setDisplayName(event.target.value)}
                className="h-11 rounded-md border border-line px-3 text-ink"
                placeholder="예: PMLE Learner"
              />
            </label>
          )}

          <label className="grid gap-1 text-sm font-bold text-slate-700">
            이메일
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              required
              className="h-11 rounded-md border border-line px-3 text-ink"
              placeholder="you@example.com"
            />
          </label>

          <label className="grid gap-1 text-sm font-bold text-slate-700">
            비밀번호
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
              minLength={6}
              className="h-11 rounded-md border border-line px-3 text-ink"
              placeholder="6자 이상"
            />
          </label>

          <button
            disabled={busy}
            className="inline-flex h-11 items-center justify-center gap-2 rounded-md bg-brand px-4 font-black text-white disabled:cursor-not-allowed disabled:bg-slate-400"
          >
            {mode === "login" ? <LogIn size={18} /> : <UserPlus size={18} />}
            {busy ? "처리 중" : mode === "login" ? "로그인" : "회원가입"}
          </button>
        </form>

        {message && <p className="mt-4 rounded-md bg-slate-50 p-3 text-sm font-semibold text-slate-700">{message}</p>}
      </section>
    </main>
  );
}
