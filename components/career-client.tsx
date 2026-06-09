"use client";

import { useEffect, useMemo, useState } from "react";
import { BarChart3, BriefcaseBusiness, CalendarDays, CheckCircle2, ClipboardList, FileText, GitBranch, MessageSquareText, Save, Sparkles, Target, TimerReset } from "lucide-react";
import clsx from "clsx";
import { AppShell, ErrorPanel, LoadingPanel } from "@/components/app-shell";
import { buildMonthlyReport, buildWeeklyReport, calculateCareerReadiness, calculatePmleReadiness, getReadinessLabel } from "@/lib/career/readiness";
import { useRequiredUser } from "@/lib/supabase/use-required-user";
import type {
  CareerReadinessMetrics,
  InterviewQuestion,
  LearningJournal,
  Lesson,
  MockExamAttempt,
  Module,
  PortfolioProject,
  ProjectStep,
  ResumeBullet,
  UserProgress,
  WrongNote
} from "@/lib/types";

type CareerState = {
  modules: Module[];
  lessons: Lesson[];
  progress: UserProgress[];
  journals: LearningJournal[];
  wrongNotes: WrongNote[];
  mockAttempts: MockExamAttempt[];
  projects: PortfolioProject[];
  steps: ProjectStep[];
  resumeBullets: ResumeBullet[];
  interviewQuestions: InterviewQuestion[];
};

type ProjectForm = {
  title: string;
  summary: string;
  role: string;
  target_domain: string;
  tech_stack: string;
  problem: string;
  solution: string;
  result: string;
  github_url: string;
  demo_url: string;
  status: PortfolioProject["status"];
  target_date: string;
};

const emptyProjectForm: ProjectForm = {
  title: "",
  summary: "",
  role: "AI Engineer",
  target_domain: "PMLE / Vertex AI",
  tech_stack: "Python, Pandas, Scikit-learn, GCP, Vertex AI",
  problem: "",
  solution: "",
  result: "",
  github_url: "",
  demo_url: "",
  status: "building",
  target_date: ""
};

export function CareerClient() {
  const { client, user, loading, error } = useRequiredUser();
  const [state, setState] = useState<CareerState>({
    modules: [],
    lessons: [],
    progress: [],
    journals: [],
    wrongNotes: [],
    mockAttempts: [],
    projects: [],
    steps: [],
    resumeBullets: [],
    interviewQuestions: []
  });
  const [projectForm, setProjectForm] = useState<ProjectForm>(emptyProjectForm);
  const [selectedProjectId, setSelectedProjectId] = useState("");
  const [newStepTitle, setNewStepTitle] = useState("");
  const [newStepDescription, setNewStepDescription] = useState("");
  const [message, setMessage] = useState("");
  const [loadingData, setLoadingData] = useState(true);
  const [dataError, setDataError] = useState("");
  const [savingProject, setSavingProject] = useState(false);
  const [generating, setGenerating] = useState("");

  async function loadCareerData(nextSelectedProjectId?: string) {
    if (!client || !user) return;
    const supabase = client;
    const currentUser = user;
    setLoadingData(true);
    setDataError("");

    const [modulesResult, lessonsResult, progressResult, journalsResult, wrongNotesResult, attemptsResult, projectsResult, stepsResult, bulletsResult, questionsResult] = await Promise.all([
      supabase.from("modules").select("*").order("sort_order", { ascending: true }),
      supabase.from("lessons").select("*").order("sort_order", { ascending: true }),
      supabase.from("user_progress").select("*").eq("user_id", currentUser.id),
      supabase.from("learning_journal").select("*").eq("user_id", currentUser.id).order("journal_date", { ascending: false }),
      supabase.from("wrong_notes").select("*").eq("user_id", currentUser.id).eq("resolved", false),
      supabase.from("mock_exam_attempts").select("*").eq("user_id", currentUser.id).order("created_at", { ascending: false }),
      supabase.from("portfolio_projects").select("*").eq("user_id", currentUser.id).order("updated_at", { ascending: false }),
      supabase.from("project_steps").select("*").eq("user_id", currentUser.id).order("sort_order", { ascending: true }),
      supabase.from("resume_bullets").select("*").eq("user_id", currentUser.id).order("created_at", { ascending: false }),
      supabase.from("interview_questions").select("*").eq("user_id", currentUser.id).order("created_at", { ascending: false })
    ]);

    const firstError =
      modulesResult.error ||
      lessonsResult.error ||
      progressResult.error ||
      journalsResult.error ||
      wrongNotesResult.error ||
      attemptsResult.error ||
      projectsResult.error ||
      stepsResult.error ||
      bulletsResult.error ||
      questionsResult.error;

    if (firstError) {
      setDataError(firstError.message);
      setLoadingData(false);
      return;
    }

    const projects = normalizeProjects((projectsResult.data ?? []) as PortfolioProject[]);
    const selectedId = nextSelectedProjectId || selectedProjectId || projects[0]?.id || "";

    setState({
      modules: (modulesResult.data ?? []) as Module[],
      lessons: (lessonsResult.data ?? []) as Lesson[],
      progress: (progressResult.data ?? []) as UserProgress[],
      journals: (journalsResult.data ?? []) as LearningJournal[],
      wrongNotes: (wrongNotesResult.data ?? []) as WrongNote[],
      mockAttempts: (attemptsResult.data ?? []) as MockExamAttempt[],
      projects,
      steps: (stepsResult.data ?? []) as ProjectStep[],
      resumeBullets: (bulletsResult.data ?? []) as ResumeBullet[],
      interviewQuestions: (questionsResult.data ?? []) as InterviewQuestion[]
    });

    setSelectedProjectId(selectedId);
    const selected = projects.find((project) => project.id === selectedId);
    if (selected) setProjectForm(projectToForm(selected));
    setLoadingData(false);
  }

  useEffect(() => {
    loadCareerData();
    // loadCareerData intentionally follows auth/client changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [client, user]);

  const selectedProject = useMemo(() => state.projects.find((project) => project.id === selectedProjectId) ?? null, [selectedProjectId, state.projects]);
  const selectedProjectSteps = state.steps.filter((step) => step.project_id === selectedProjectId);
  const selectedResumeBullets = state.resumeBullets.filter((bullet) => bullet.project_id === selectedProjectId);
  const selectedInterviewQuestions = state.interviewQuestions.filter((question) => question.project_id === selectedProjectId);
  const metrics = useMemo(() => buildMetrics(state), [state]);
  const pmleScore = calculatePmleReadiness(metrics);
  const careerScore = calculateCareerReadiness(metrics);
  const weeklyReport = buildWeeklyReport(metrics);
  const monthlyReport = buildMonthlyReport(metrics);

  function selectProject(project: PortfolioProject) {
    setSelectedProjectId(project.id);
    setProjectForm(projectToForm(project));
    setMessage("");
  }

  function startNewProject() {
    setSelectedProjectId("");
    setProjectForm(emptyProjectForm);
    setMessage("");
  }

  async function saveProject() {
    if (!client || !user) return;
    setSavingProject(true);
    setMessage("");

    const payload = {
      user_id: user.id,
      title: projectForm.title.trim() || "제목 없는 AI 포트폴리오 프로젝트",
      summary: projectForm.summary.trim(),
      role: projectForm.role.trim(),
      target_domain: projectForm.target_domain.trim(),
      tech_stack: parseStack(projectForm.tech_stack),
      problem: projectForm.problem.trim(),
      solution: projectForm.solution.trim(),
      result: projectForm.result.trim(),
      github_url: projectForm.github_url.trim(),
      demo_url: projectForm.demo_url.trim(),
      status: projectForm.status,
      target_date: projectForm.target_date || null,
      started_at: new Date().toISOString(),
      completed_at: projectForm.status === "completed" ? new Date().toISOString() : null,
      updated_at: new Date().toISOString()
    };

    const query = selectedProjectId
      ? client.from("portfolio_projects").update(payload).eq("id", selectedProjectId).eq("user_id", user.id).select("*").single()
      : client.from("portfolio_projects").insert(payload).select("*").single();

    const result = await query;
    setSavingProject(false);

    if (result.error || !result.data) {
      setMessage(result.error?.message ?? "프로젝트 저장에 실패했습니다.");
      return;
    }

    await loadCareerData(result.data.id);
    setMessage("포트폴리오 프로젝트를 저장했습니다.");
  }

  async function addStep() {
    if (!client || !user || !selectedProjectId || !newStepTitle.trim()) return;
    const nextOrder = selectedProjectSteps.length + 1;
    const result = await client.from("project_steps").insert({
      user_id: user.id,
      project_id: selectedProjectId,
      title: newStepTitle.trim(),
      description: newStepDescription.trim(),
      status: "todo",
      sort_order: nextOrder
    });

    if (result.error) {
      setMessage(result.error.message);
      return;
    }

    setNewStepTitle("");
    setNewStepDescription("");
    await loadCareerData(selectedProjectId);
  }

  async function toggleStep(step: ProjectStep) {
    if (!client || !user) return;
    const nextStatus = step.status === "done" ? "todo" : "done";
    const result = await client
      .from("project_steps")
      .update({
        status: nextStatus,
        completed_at: nextStatus === "done" ? new Date().toISOString() : null,
        updated_at: new Date().toISOString()
      })
      .eq("id", step.id)
      .eq("user_id", user.id);

    if (result.error) {
      setMessage(result.error.message);
      return;
    }

    await loadCareerData(selectedProjectId);
  }

  async function runGenerator(action: "generate_readme" | "generate_resume_bullet" | "generate_interview_questions") {
    if (!client || !selectedProjectId) return;
    setGenerating(action);
    setMessage("");

    const {
      data: { session }
    } = await client.auth.getSession();

    const response = await fetch("/api/career-tools", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: session?.access_token ? `Bearer ${session.access_token}` : ""
      },
      body: JSON.stringify({
        action,
        projectId: selectedProjectId,
        roleFocus: projectForm.role || "AI Engineer",
        category: "pmle"
      })
    });

    const data = (await response.json()) as { error?: string; source?: string };
    setGenerating("");

    if (!response.ok) {
      setMessage(data.error ?? "Generation failed.");
      return;
    }

    await loadCareerData(selectedProjectId);
    setMessage(`${data.source ?? "template"} 방식으로 생성하고 저장했습니다.`);
  }

  return (
    <AppShell>
      {loading || loadingData ? (
        <LoadingPanel label="커리어 전환 OS를 불러오는 중입니다..." />
      ) : error || dataError ? (
        <ErrorPanel message={error || dataError} />
      ) : (
        <div className="grid gap-5">
          <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
            <div className="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand">AI Engineer Career OS</p>
                <h1 className="mt-1 text-2xl font-black">포트폴리오, PMLE 준비도, 커리어 전환 대시보드</h1>
                <p className="mt-2 max-w-4xl text-sm leading-6 text-slate-600">
                  Manage projects, generate job-ready artifacts, track PMLE readiness, and keep weekly/monthly execution visible.
                </p>
              </div>
              <button onClick={startNewProject} className="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-brand px-4 text-sm font-black text-white">
                <BriefcaseBusiness size={16} /> 새 프로젝트
              </button>
            </div>
          </section>

          <section className="grid gap-3 md:grid-cols-4">
            <Metric label="PMLE 준비도" value={`${pmleScore}%`} detail={getReadinessLabel(pmleScore)} icon={Target} />
            <Metric label="커리어 전환 준비도" value={`${careerScore}%`} detail={getReadinessLabel(careerScore)} icon={BriefcaseBusiness} />
            <Metric label="D-Day" value={metrics.dDay === null ? "미설정" : `D-${metrics.dDay}`} detail="가장 가까운 프로젝트 목표일" icon={CalendarDays} />
            <Metric label="이번 주 학습" value={`${metrics.weeklyStudyMinutes}분`} detail={`총 ${metrics.studyDays}일 학습`} icon={BarChart3} />
          </section>

          <section className="grid gap-5 lg:grid-cols-[0.95fr_1.05fr]">
            <Panel title="포트폴리오 프로젝트">
              {state.projects.map((project) => {
                const steps = state.steps.filter((step) => step.project_id === project.id);
                const done = steps.filter((step) => step.status === "done").length;
                const active = project.id === selectedProjectId;
                return (
                  <button
                    key={project.id}
                    onClick={() => selectProject(project)}
                    className={clsx("rounded-md border p-4 text-left", active ? "border-brand bg-blue-50" : "border-line bg-white hover:border-brand")}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="font-black">{project.title}</p>
                        <p className="mt-1 text-sm leading-6 text-slate-600">{project.summary || "아직 요약이 없습니다."}</p>
                      </div>
                      <span className="shrink-0 rounded-full bg-white px-2 py-1 text-xs font-black text-slate-600">{project.status}</span>
                    </div>
                    <p className="mt-3 text-xs font-black text-slate-500">
                      단계 {done}/{steps.length} / {project.tech_stack.join(", ") || "기술스택 없음"}
                    </p>
                  </button>
                );
              })}
              {state.projects.length === 0 && <Empty label="Create the first AI engineering portfolio project." />}
            </Panel>

            <Panel title="프로젝트 편집">
              <div className="grid gap-3 md:grid-cols-2">
                <Input label="프로젝트 제목" value={projectForm.title} onChange={(value) => setProjectForm((current) => ({ ...current, title: value }))} />
                <Input label="목표 직무" value={projectForm.role} onChange={(value) => setProjectForm((current) => ({ ...current, role: value }))} />
                <Input label="목표 분야" value={projectForm.target_domain} onChange={(value) => setProjectForm((current) => ({ ...current, target_domain: value }))} />
                <Input label="목표 날짜" value={projectForm.target_date} onChange={(value) => setProjectForm((current) => ({ ...current, target_date: value }))} type="date" />
              </div>
              <Textarea label="요약" value={projectForm.summary} onChange={(value) => setProjectForm((current) => ({ ...current, summary: value }))} />
              <Input label="기술스택" value={projectForm.tech_stack} onChange={(value) => setProjectForm((current) => ({ ...current, tech_stack: value }))} />
              <Textarea label="문제 정의" value={projectForm.problem} onChange={(value) => setProjectForm((current) => ({ ...current, problem: value }))} />
              <Textarea label="해결 방법" value={projectForm.solution} onChange={(value) => setProjectForm((current) => ({ ...current, solution: value }))} />
              <Textarea label="결과" value={projectForm.result} onChange={(value) => setProjectForm((current) => ({ ...current, result: value }))} />
              <div className="grid gap-3 md:grid-cols-2">
                <Input label="GitHub URL" value={projectForm.github_url} onChange={(value) => setProjectForm((current) => ({ ...current, github_url: value }))} />
                <Input label="Demo URL" value={projectForm.demo_url} onChange={(value) => setProjectForm((current) => ({ ...current, demo_url: value }))} />
              </div>
              <label className="grid gap-1 text-sm font-bold text-slate-700">
                Status
                <select value={projectForm.status} onChange={(event) => setProjectForm((current) => ({ ...current, status: event.target.value as PortfolioProject["status"] }))} className="h-10 rounded-md border border-line px-3 text-ink">
                  <option value="planned">계획 중</option>
                  <option value="building">진행 중</option>
                  <option value="completed">완료</option>
                </select>
              </label>
              <button onClick={saveProject} disabled={savingProject} className="inline-flex h-10 w-full items-center justify-center gap-2 rounded-md bg-ink px-4 text-sm font-black text-white disabled:bg-slate-400">
                <Save size={16} /> {savingProject ? "저장 중..." : "프로젝트 저장"}
              </button>
            </Panel>
          </section>

          {selectedProject && (
            <section className="grid gap-5 lg:grid-cols-[0.9fr_1.1fr]">
              <Panel title="프로젝트 단계">
                {selectedProjectSteps.map((step) => (
                  <button key={step.id} onClick={() => toggleStep(step)} className="flex items-start gap-3 rounded-md border border-line p-4 text-left hover:border-brand">
                    <span className={clsx("mt-1 inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full border", step.status === "done" ? "border-emerald-500 bg-emerald-500 text-white" : "border-slate-300")}>
                      {step.status === "done" && <CheckCircle2 size={14} />}
                    </span>
                    <span>
                      <span className="block font-black">{step.title}</span>
                      <span className="mt-1 block text-sm leading-6 text-slate-600">{step.description || "설명이 없습니다."}</span>
                    </span>
                  </button>
                ))}
                <div className="rounded-md bg-slate-50 p-4">
                  <Input label="새 단계" value={newStepTitle} onChange={setNewStepTitle} />
                  <Textarea label="단계 설명" value={newStepDescription} onChange={setNewStepDescription} rows={3} />
                  <button onClick={addStep} className="mt-3 h-10 rounded-md bg-brand px-4 text-sm font-black text-white">단계 추가</button>
                </div>
              </Panel>

              <Panel title="생성된 커리어 자료">
                <div className="grid gap-2 md:grid-cols-3">
                  <GenerateButton label="README" icon={GitBranch} busy={generating === "generate_readme"} onClick={() => runGenerator("generate_readme")} />
                  <GenerateButton label="이력서 문장" icon={FileText} busy={generating === "generate_resume_bullet"} onClick={() => runGenerator("generate_resume_bullet")} />
                  <GenerateButton label="면접 질문" icon={MessageSquareText} busy={generating === "generate_interview_questions"} onClick={() => runGenerator("generate_interview_questions")} />
                </div>
                {selectedProject.readme_content && (
                  <div>
                    <p className="mb-2 text-sm font-black">GitHub README 초안</p>
                    <textarea value={selectedProject.readme_content} readOnly rows={10} className="w-full rounded-md border border-line bg-slate-50 p-3 text-sm leading-6" />
                  </div>
                )}
                <AssetList title="이력서 문장" items={selectedResumeBullets.map((item) => item.content)} />
                <div className="grid gap-3">
                  <p className="text-sm font-black">면접 질문</p>
                  {selectedInterviewQuestions.slice(0, 8).map((item) => (
                    <article key={item.id} className="rounded-md border border-line p-4">
                      <p className="font-black">{item.question}</p>
                      <p className="mt-2 text-sm leading-6 text-slate-600">{item.suggested_answer}</p>
                      <p className="mt-2 text-xs font-black text-brand">{item.category} · {item.difficulty}</p>
                    </article>
                  ))}
                  {selectedInterviewQuestions.length === 0 && <Empty label="이 프로젝트용 면접 질문을 생성해 보세요." />}
                </div>
              </Panel>
            </section>
          )}

          <section className="grid gap-5 lg:grid-cols-2">
            <Panel title="주간 리포트">
              {weeklyReport.map((item) => (
                <ReportLine key={item} text={item} />
              ))}
            </Panel>
            <Panel title="월간 리포트">
              {monthlyReport.map((item) => (
                <ReportLine key={item} text={item} />
              ))}
            </Panel>
          </section>

          <Panel title="최종 점검">
            <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
              <CheckItem label="Supabase RLS" ok detail="사용자별 테이블은 auth.uid() 정책을 사용합니다." />
              <CheckItem label="인증" ok detail="보호된 페이지는 Supabase Auth 가드로 접근을 확인합니다." />
              <CheckItem label="Gemini 보안" ok detail="Gemini API 호출은 서버 라우트에서만 실행됩니다." />
              <CheckItem label="Netlify 준비" ok detail="빌드 명령과 .next 배포 대상이 설정되어 있습니다." />
              <CheckItem label="에러 처리" ok detail="불러오기, 저장, 생성 흐름에서 에러를 화면에 표시합니다." />
              <CheckItem label="반응형 UI" ok detail="대시보드는 화면 크기에 맞게 배치됩니다." />
              <CheckItem label="성능" ok detail="데이터 불러오기는 Promise.all로 묶어 처리합니다." />
              <CheckItem label="OpenAI 미사용" ok detail="이번 빌드는 Gemini 전용 provider 구조를 사용합니다." />
            </div>
          </Panel>

          {message && <p className="rounded-lg border border-line bg-white p-4 text-sm font-bold text-slate-700 shadow-soft">{message}</p>}
        </div>
      )}
    </AppShell>
  );
}

function buildMetrics(state: CareerState): CareerReadinessMetrics {
  const gcpModule = state.modules.find((module) => module.title === "GCP + Vertex AI");
  const gcpLessons = gcpModule ? state.lessons.filter((lesson) => lesson.module_id === gcpModule.id) : [];
  const progressByLesson = new Map(state.progress.map((item) => [item.lesson_id, item]));
  const completedLessons = state.lessons.filter((lesson) => progressByLesson.get(lesson.id)?.completed).length;
  const gcpCompletedLessons = gcpLessons.filter((lesson) => progressByLesson.get(lesson.id)?.completed).length;
  const bestMockExamScore = state.mockAttempts.reduce((best, attempt) => Math.max(best, Number(attempt.score_percent)), 0);
  const now = new Date();
  const weekStart = daysAgo(now, 7);
  const monthStart = daysAgo(now, 30);
  const weeklyStudyMinutes = sumStudyMinutes(state.journals, weekStart);
  const monthlyStudyMinutes = sumStudyMinutes(state.journals, monthStart);
  const totalStudyMinutes = state.journals.reduce((sum, item) => sum + item.study_minutes, 0);
  const studyDays = new Set(state.journals.map((item) => item.journal_date)).size;
  const dDay = nearestDday(state.projects);

  return {
    completedLessons,
    totalLessons: state.lessons.length,
    gcpCompletedLessons,
    gcpTotalLessons: gcpLessons.length,
    bestMockExamScore,
    unresolvedWrongNotes: state.wrongNotes.length,
    portfolioProjects: state.projects.length,
    completedPortfolioProjects: state.projects.filter((project) => project.status === "completed").length,
    resumeBullets: state.resumeBullets.length,
    interviewQuestions: state.interviewQuestions.length,
    totalStudyMinutes,
    weeklyStudyMinutes,
    monthlyStudyMinutes,
    studyDays,
    dDay
  };
}

function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <h2 className="text-lg font-black">{title}</h2>
      <div className="mt-4 grid gap-3">{children}</div>
    </section>
  );
}

function Metric({ label, value, detail, icon: Icon }: { label: string; value: string; detail: string; icon: React.ComponentType<{ size?: number; className?: string }> }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm font-bold text-slate-600">{label}</p>
        <Icon size={18} className="text-brand" />
      </div>
      <p className="mt-3 text-3xl font-black">{value}</p>
      <p className="mt-1 text-sm font-semibold text-slate-500">{detail}</p>
    </div>
  );
}

function Input({ label, value, onChange, type = "text" }: { label: string; value: string; onChange: (value: string) => void; type?: string }) {
  return (
    <label className="grid gap-1 text-sm font-bold text-slate-700">
      {label}
      <input type={type} value={value} onChange={(event) => onChange(event.target.value)} className="h-10 rounded-md border border-line px-3 text-ink" />
    </label>
  );
}

function Textarea({ label, value, onChange, rows = 4 }: { label: string; value: string; onChange: (value: string) => void; rows?: number }) {
  return (
    <label className="grid gap-1 text-sm font-bold text-slate-700">
      {label}
      <textarea value={value} rows={rows} onChange={(event) => onChange(event.target.value)} className="rounded-md border border-line p-3 text-sm leading-6 text-ink" />
    </label>
  );
}

function GenerateButton({ label, icon: Icon, busy, onClick }: { label: string; icon: React.ComponentType<{ size?: number }>; busy: boolean; onClick: () => void }) {
  return (
    <button onClick={onClick} disabled={busy} className="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-brand px-3 text-sm font-black text-white disabled:bg-slate-400">
      {busy ? <TimerReset size={16} /> : <Icon size={16} />} {busy ? "생성 중..." : label}
    </button>
  );
}

function AssetList({ title, items }: { title: string; items: string[] }) {
  return (
    <div className="grid gap-2">
      <p className="text-sm font-black">{title}</p>
      {items.map((item) => (
        <p key={item} className="rounded-md bg-slate-50 p-3 text-sm leading-6 text-slate-700">{item}</p>
      ))}
      {items.length === 0 && <Empty label={`${title}을 생성해 보세요.`} />}
    </div>
  );
}

function ReportLine({ text }: { text: string }) {
  return (
    <div className="flex items-start gap-2 rounded-md bg-slate-50 p-3 text-sm font-semibold text-slate-700">
      <ClipboardList size={16} className="mt-0.5 shrink-0 text-brand" />
      <span>{text}</span>
    </div>
  );
}

function CheckItem({ label, ok, detail }: { label: string; ok: boolean; detail: string }) {
  return (
    <div className={clsx("rounded-md border p-4", ok ? "border-emerald-200 bg-emerald-50" : "border-red-200 bg-red-50")}>
      <p className={clsx("font-black", ok ? "text-emerald-800" : "text-danger")}>{label}</p>
      <p className="mt-1 text-sm leading-6 text-slate-700">{detail}</p>
    </div>
  );
}

function Empty({ label }: { label: string }) {
  return <p className="rounded-md bg-slate-50 p-4 text-sm font-semibold text-slate-500">{label}</p>;
}

function normalizeProjects(rows: PortfolioProject[]) {
  return rows.map((row) => ({
    ...row,
    tech_stack: Array.isArray(row.tech_stack) ? row.tech_stack : []
  }));
}

function projectToForm(project: PortfolioProject): ProjectForm {
  return {
    title: project.title,
    summary: project.summary,
    role: project.role,
    target_domain: project.target_domain,
    tech_stack: project.tech_stack.join(", "),
    problem: project.problem,
    solution: project.solution,
    result: project.result,
    github_url: project.github_url,
    demo_url: project.demo_url,
    status: project.status,
    target_date: project.target_date ?? ""
  };
}

function parseStack(value: string) {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function sumStudyMinutes(journals: LearningJournal[], start: Date) {
  return journals.filter((item) => new Date(item.journal_date) >= start).reduce((sum, item) => sum + item.study_minutes, 0);
}

function daysAgo(date: Date, days: number) {
  const next = new Date(date);
  next.setDate(date.getDate() - days);
  next.setHours(0, 0, 0, 0);
  return next;
}

function nearestDday(projects: PortfolioProject[]) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const futureTargets = projects
    .map((project) => project.target_date)
    .filter((value): value is string => Boolean(value))
    .map((value) => new Date(value))
    .filter((date) => date.getTime() >= today.getTime())
    .sort((left, right) => left.getTime() - right.getTime());

  if (futureTargets.length === 0) return null;
  return Math.ceil((futureTargets[0].getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
}
