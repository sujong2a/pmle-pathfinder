-- PMLE Pathfinder MVP4 Python coding lab migration
-- Apply after MVP1, MVP2, and MVP3 migrations.

create table if not exists public.coding_tasks (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references public.lessons(id) on delete set null,
  title text not null,
  description text not null default '',
  instructions text not null default '',
  starter_code text not null default '',
  expected_output text not null default '',
  required_keywords text[] not null default '{}',
  solution_pattern text not null default '',
  difficulty text not null default 'easy' check (difficulty in ('easy', 'medium', 'hard')),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.coding_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  task_id uuid not null references public.coding_tasks(id) on delete cascade,
  code text not null,
  user_expected_output text not null default '',
  evaluation_result jsonb not null default '{}'::jsonb,
  score integer not null default 0 check (score between 0 and 100),
  status text not null default 'needs_retry' check (status in ('passed', 'needs_retry')),
  attempt_number integer not null default 1,
  created_at timestamptz not null default now()
);

create table if not exists public.coding_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  task_id uuid not null references public.coding_tasks(id) on delete cascade,
  submission_id uuid not null references public.coding_submissions(id) on delete cascade,
  improvements text[] not null default '{}',
  recommended_study text[] not null default '{}',
  feedback text not null default '',
  ai_feedback text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists idx_coding_tasks_active_order on public.coding_tasks(is_active, sort_order);
create index if not exists idx_coding_submissions_user_task on public.coding_submissions(user_id, task_id, created_at desc);
create index if not exists idx_coding_feedback_user_submission on public.coding_feedback(user_id, submission_id);

drop trigger if exists set_coding_tasks_updated_at on public.coding_tasks;
create trigger set_coding_tasks_updated_at before update on public.coding_tasks
for each row execute function public.set_updated_at();

alter table public.coding_tasks enable row level security;
alter table public.coding_submissions enable row level security;
alter table public.coding_feedback enable row level security;

drop policy if exists "coding tasks read authenticated" on public.coding_tasks;
create policy "coding tasks read authenticated" on public.coding_tasks
for select to authenticated using (is_active = true);

drop policy if exists "coding submissions select own" on public.coding_submissions;
create policy "coding submissions select own" on public.coding_submissions
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "coding submissions insert own" on public.coding_submissions;
create policy "coding submissions insert own" on public.coding_submissions
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "coding feedback select own" on public.coding_feedback;
create policy "coding feedback select own" on public.coding_feedback
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "coding feedback insert own" on public.coding_feedback;
create policy "coding feedback insert own" on public.coding_feedback
for insert to authenticated with check (auth.uid() = user_id);

insert into public.coding_tasks (
  id,
  lesson_id,
  title,
  description,
  instructions,
  starter_code,
  expected_output,
  required_keywords,
  solution_pattern,
  difficulty,
  sort_order
)
values
  (
    '60000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    'Print a goal variable',
    'Create a string variable and print it.',
    'Store AI Engineer in a variable named goal and print it. In expected output, write only what should appear on the screen.',
    'goal = ""\nprint(goal)',
    'AI Engineer',
    array['goal', 'print'],
    'goal\\s*=\\s*["'']AI Engineer["''].*print\\s*\\(\\s*goal\\s*\\)',
    'easy',
    1
  ),
  (
    '60000000-0000-4000-8000-000000000002',
    '21000000-0000-4000-8000-000000000001',
    'Add two numbers with a function',
    'Practice defining a function and returning a result.',
    'Define an add function and print the result of add(3, 5).',
    'def add(a, b):\n    return 0\n\nprint(add(3, 5))',
    '8',
    array['def', 'return', 'print'],
    'def\\s+add\\s*\\(\\s*a\\s*,\\s*b\\s*\\).*return\\s+a\\s*\\+\\s*b.*print\\s*\\(\\s*add\\s*\\(\\s*3\\s*,\\s*5\\s*\\)\\s*\\)',
    'easy',
    2
  ),
  (
    '60000000-0000-4000-8000-000000000003',
    '21000000-0000-4000-8000-000000000002',
    'Calculate list average',
    'Use sum and len to calculate an average.',
    'Create scores = [70, 80, 90], calculate the average, and print it.',
    'scores = [70, 80, 90]\n\naverage = 0\nprint(average)',
    '80.0',
    array['scores', 'sum', 'len', 'print'],
    'scores\\s*=\\s*\\[\\s*70\\s*,\\s*80\\s*,\\s*90\\s*\\].*sum\\s*\\(\\s*scores\\s*\\).*len\\s*\\(\\s*scores\\s*\\).*print\\s*\\(',
    'medium',
    3
  )
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    title = excluded.title,
    description = excluded.description,
    instructions = excluded.instructions,
    starter_code = excluded.starter_code,
    expected_output = excluded.expected_output,
    required_keywords = excluded.required_keywords,
    solution_pattern = excluded.solution_pattern,
    difficulty = excluded.difficulty,
    sort_order = excluded.sort_order,
    is_active = true;
