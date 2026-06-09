"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { BookOpenCheck, Bot, BrainCircuit, BriefcaseBusiness, CalendarCheck2, ClipboardCheck, Cloud, Code2, LayoutDashboard, LogOut, NotebookPen } from "lucide-react";
import clsx from "clsx";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";

const navItems = [
  { href: "/dashboard", label: "대시보드", icon: LayoutDashboard },
  { href: "/curriculum", label: "커리큘럼", icon: BookOpenCheck },
  { href: "/ml-dashboard", label: "ML", icon: BrainCircuit },
  { href: "/gcp-dashboard", label: "GCP", icon: Cloud },
  { href: "/mock-exams", label: "모의고사", icon: ClipboardCheck },
  { href: "/career", label: "커리어", icon: BriefcaseBusiness },
  { href: "/coding-lab", label: "실습", icon: Code2 },
  { href: "/reviews", label: "복습", icon: CalendarCheck2 },
  { href: "/ai-tutor", label: "AI 튜터", icon: Bot },
  { href: "/wrong-notes", label: "오답노트", icon: NotebookPen }
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [email, setEmail] = useState("");

  useEffect(() => {
    try {
      const client = getSupabaseBrowserClient();
      client.auth.getUser().then(({ data }) => setEmail(data.user?.email ?? ""));
    } catch {
      setEmail("");
    }
  }, []);

  async function signOut() {
    const client = getSupabaseBrowserClient();
    await client.auth.signOut();
    router.replace("/auth");
  }

  return (
    <div className="min-h-screen bg-paper text-ink">
      <header className="border-b border-line bg-white">
        <div className="mx-auto flex w-full max-w-7xl flex-col gap-3 px-4 py-4 md:px-6">
          <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <Link href="/dashboard" className="min-w-0">
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">PMLE Pathfinder</p>
              <h1 className="text-xl font-black md:text-2xl">AI 엔지니어 전환 학습 OS</h1>
            </Link>

            <button
              onClick={signOut}
              className="inline-flex h-10 w-fit items-center justify-center gap-2 rounded-md border border-line bg-white px-3 text-sm font-bold text-slate-700 hover:border-danger"
              title={email || "로그아웃"}
            >
              <LogOut size={16} />
              <span>로그아웃</span>
            </button>
          </div>

          <nav className="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-10">
            {navItems.map(({ href, label, icon: Icon }) => {
              const active = pathname === href || pathname.startsWith(`${href}/`);
              return (
                <Link
                  key={href}
                  href={href}
                  className={clsx(
                    "inline-flex h-10 items-center justify-center gap-2 rounded-md border px-3 text-sm font-bold transition",
                    active ? "border-ink bg-ink text-white" : "border-line bg-white text-slate-700 hover:border-brand"
                  )}
                >
                  <Icon size={16} />
                  <span>{label}</span>
                </Link>
              );
            })}
          </nav>
        </div>
      </header>

      <main className="mx-auto w-full max-w-7xl px-4 py-5 md:px-6 md:py-6">{children}</main>
    </div>
  );
}

export function LoadingPanel({ label = "불러오는 중입니다..." }: { label?: string }) {
  return (
    <div className="rounded-lg border border-line bg-white p-6 shadow-soft">
      <p className="text-sm font-semibold text-slate-600">{label}</p>
    </div>
  );
}

export function ErrorPanel({ message }: { message: string }) {
  return <div className="rounded-lg border border-danger bg-red-50 p-5 text-sm font-semibold text-danger">{message}</div>;
}
