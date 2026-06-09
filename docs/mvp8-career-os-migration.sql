-- PMLE Pathfinder MVP8 career operating system migration
-- Apply after MVP1-MVP7 migrations.

create table if not exists public.portfolio_projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  summary text not null default '',
  role text not null default 'AI Engineer',
  target_domain text not null default 'PMLE / Vertex AI',
  tech_stack jsonb not null default '[]'::jsonb,
  problem text not null default '',
  solution text not null default '',
  result text not null default '',
  github_url text not null default '',
  demo_url text not null default '',
  readme_content text not null default '',
  status text not null default 'building' check (status in ('planned', 'building', 'completed')),
  target_date date,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.project_steps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.portfolio_projects(id) on delete cascade,
  title text not null,
  description text not null default '',
  status text not null default 'todo' check (status in ('todo', 'doing', 'done')),
  sort_order integer not null default 0,
  due_date date,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.resume_bullets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid references public.portfolio_projects(id) on delete set null,
  content text not null,
  role_focus text not null default 'AI Engineer',
  source text not null default 'template' check (source in ('template', 'gemini')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.interview_questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid references public.portfolio_projects(id) on delete set null,
  question text not null,
  suggested_answer text not null default '',
  category text not null default 'project' check (category in ('technical', 'project', 'behavioral', 'pmle')),
  difficulty text not null default 'medium' check (difficulty in ('easy', 'medium', 'hard')),
  source text not null default 'template' check (source in ('template', 'gemini')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_portfolio_projects_user on public.portfolio_projects(user_id, updated_at desc);
create index if not exists idx_project_steps_user_project on public.project_steps(user_id, project_id, sort_order);
create index if not exists idx_resume_bullets_user_project on public.resume_bullets(user_id, project_id, created_at desc);
create index if not exists idx_interview_questions_user_project on public.interview_questions(user_id, project_id, created_at desc);

drop trigger if exists set_portfolio_projects_updated_at on public.portfolio_projects;
create trigger set_portfolio_projects_updated_at before update on public.portfolio_projects
for each row execute function public.set_updated_at();

drop trigger if exists set_project_steps_updated_at on public.project_steps;
create trigger set_project_steps_updated_at before update on public.project_steps
for each row execute function public.set_updated_at();

drop trigger if exists set_resume_bullets_updated_at on public.resume_bullets;
create trigger set_resume_bullets_updated_at before update on public.resume_bullets
for each row execute function public.set_updated_at();

drop trigger if exists set_interview_questions_updated_at on public.interview_questions;
create trigger set_interview_questions_updated_at before update on public.interview_questions
for each row execute function public.set_updated_at();

alter table public.portfolio_projects enable row level security;
alter table public.project_steps enable row level security;
alter table public.resume_bullets enable row level security;
alter table public.interview_questions enable row level security;

drop policy if exists "portfolio projects select own" on public.portfolio_projects;
create policy "portfolio projects select own" on public.portfolio_projects
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "portfolio projects insert own" on public.portfolio_projects;
create policy "portfolio projects insert own" on public.portfolio_projects
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "portfolio projects update own" on public.portfolio_projects;
create policy "portfolio projects update own" on public.portfolio_projects
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "portfolio projects delete own" on public.portfolio_projects;
create policy "portfolio projects delete own" on public.portfolio_projects
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "project steps select own" on public.project_steps;
create policy "project steps select own" on public.project_steps
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "project steps insert own" on public.project_steps;
create policy "project steps insert own" on public.project_steps
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "project steps update own" on public.project_steps;
create policy "project steps update own" on public.project_steps
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "project steps delete own" on public.project_steps;
create policy "project steps delete own" on public.project_steps
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "resume bullets select own" on public.resume_bullets;
create policy "resume bullets select own" on public.resume_bullets
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "resume bullets insert own" on public.resume_bullets;
create policy "resume bullets insert own" on public.resume_bullets
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "resume bullets update own" on public.resume_bullets;
create policy "resume bullets update own" on public.resume_bullets
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "resume bullets delete own" on public.resume_bullets;
create policy "resume bullets delete own" on public.resume_bullets
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "interview questions select own" on public.interview_questions;
create policy "interview questions select own" on public.interview_questions
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "interview questions insert own" on public.interview_questions;
create policy "interview questions insert own" on public.interview_questions
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "interview questions update own" on public.interview_questions;
create policy "interview questions update own" on public.interview_questions
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "interview questions delete own" on public.interview_questions;
create policy "interview questions delete own" on public.interview_questions
for delete to authenticated using (auth.uid() = user_id);
