-- PMLE Pathfinder Phase 0 / MVP1 base schema
-- Run this file before MVP2-MVP8 migrations.

create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default 'PMLE Learner',
  role_goal text not null default 'AI Engineer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.modules (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  slug text not null unique,
  title text not null,
  objective text not null default '',
  concept text not null default '',
  example_code text not null default '',
  summary text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  question text not null,
  explanation text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.quiz_options (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  option_text text not null,
  is_correct boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.user_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  status text not null default 'not_started' check (status in ('not_started', 'in_progress', 'completed')),
  completed boolean not null default false,
  started_at timestamptz,
  completed_at timestamptz,
  last_viewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  selected_option_id uuid references public.quiz_options(id) on delete set null,
  correct_option_id uuid references public.quiz_options(id) on delete set null,
  is_correct boolean not null,
  attempted_at timestamptz not null default now()
);

create table if not exists public.wrong_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  selected_option_id uuid references public.quiz_options(id) on delete set null,
  correct_option_id uuid references public.quiz_options(id) on delete set null,
  question_snapshot text not null,
  explanation_snapshot text not null default '',
  attempt_count integer not null default 1,
  resolved boolean not null default false,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, quiz_id)
);

create table if not exists public.learning_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  content text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);

create index if not exists idx_lessons_module_order on public.lessons(module_id, sort_order);
create index if not exists idx_quizzes_lesson_order on public.quizzes(lesson_id, sort_order);
create index if not exists idx_quiz_options_quiz_order on public.quiz_options(quiz_id, sort_order);
create index if not exists idx_user_progress_user on public.user_progress(user_id, updated_at desc);
create index if not exists idx_wrong_notes_user on public.wrong_notes(user_id, resolved, updated_at desc);
create index if not exists idx_learning_notes_user on public.learning_notes(user_id, updated_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists set_user_progress_updated_at on public.user_progress;
create trigger set_user_progress_updated_at before update on public.user_progress
for each row execute function public.set_updated_at();

drop trigger if exists set_wrong_notes_updated_at on public.wrong_notes;
create trigger set_wrong_notes_updated_at before update on public.wrong_notes
for each row execute function public.set_updated_at();

drop trigger if exists set_learning_notes_updated_at on public.learning_notes;
create trigger set_learning_notes_updated_at before update on public.learning_notes
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(coalesce(new.email, ''), '@', 1), 'PMLE Learner')
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.users enable row level security;
alter table public.modules enable row level security;
alter table public.lessons enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_options enable row level security;
alter table public.user_progress enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.wrong_notes enable row level security;
alter table public.learning_notes enable row level security;

drop policy if exists "users select own" on public.users;
create policy "users select own" on public.users
for select to authenticated using (auth.uid() = id);

drop policy if exists "users insert own" on public.users;
create policy "users insert own" on public.users
for insert to authenticated with check (auth.uid() = id);

drop policy if exists "users update own" on public.users;
create policy "users update own" on public.users
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "modules read authenticated" on public.modules;
create policy "modules read authenticated" on public.modules
for select to authenticated using (true);

drop policy if exists "lessons read authenticated" on public.lessons;
create policy "lessons read authenticated" on public.lessons
for select to authenticated using (true);

drop policy if exists "quizzes read authenticated" on public.quizzes;
create policy "quizzes read authenticated" on public.quizzes
for select to authenticated using (true);

drop policy if exists "quiz options read authenticated" on public.quiz_options;
create policy "quiz options read authenticated" on public.quiz_options
for select to authenticated using (true);

drop policy if exists "progress select own" on public.user_progress;
create policy "progress select own" on public.user_progress
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "progress insert own" on public.user_progress;
create policy "progress insert own" on public.user_progress
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "progress update own" on public.user_progress;
create policy "progress update own" on public.user_progress
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "attempts select own" on public.quiz_attempts;
create policy "attempts select own" on public.quiz_attempts
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "attempts insert own" on public.quiz_attempts;
create policy "attempts insert own" on public.quiz_attempts
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "wrong notes select own" on public.wrong_notes;
create policy "wrong notes select own" on public.wrong_notes
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "wrong notes insert own" on public.wrong_notes;
create policy "wrong notes insert own" on public.wrong_notes
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "wrong notes update own" on public.wrong_notes;
create policy "wrong notes update own" on public.wrong_notes
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "learning notes select own" on public.learning_notes;
create policy "learning notes select own" on public.learning_notes
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "learning notes insert own" on public.learning_notes;
create policy "learning notes insert own" on public.learning_notes
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "learning notes update own" on public.learning_notes;
create policy "learning notes update own" on public.learning_notes
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "learning notes delete own" on public.learning_notes;
create policy "learning notes delete own" on public.learning_notes
for delete to authenticated using (auth.uid() = user_id);

insert into public.modules (id, title, description, sort_order)
values
  ('10000000-0000-4000-8000-000000000001', 'Python Basics', 'First Python module for non-programmers and complete beginners.', 1)
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    sort_order = excluded.sort_order;

insert into public.lessons (id, module_id, slug, title, objective, concept, example_code, summary, sort_order)
values
  (
    '20000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001',
    'python-variables',
    'Variables',
    'Learn how to name a value and reuse it in Python.',
    $concept$A variable is a name attached to a value. It helps you reuse data without typing the same value again.

Think of a variable like a labeled box. The label is the variable name, and the item inside is the value.$concept$,
    $code$goal = "AI Engineer"
hours_per_week = 7

print(goal)
print(hours_per_week + 3)$code$,
    $summary$- A variable stores a value with a name.
- The = sign assigns the value on the right to the name on the left.
- Good names make code easier to read.$summary$,
    1
  ),
  (
    '20000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000001',
    'python-data-types',
    'Data Types',
    'Understand strings, integers, floats, and booleans.',
    $concept$A data type is the kind of value Python is working with. Text is a string, whole numbers are integers, decimal numbers are floats, and True or False values are booleans.

Python uses data types to decide what operations are allowed.$concept$,
    $code$name = "PMLE"
study_hours = 10
accuracy = 0.85
passed = True

print(type(name))
print(type(study_hours))
print(type(accuracy))
print(type(passed))$code$,
    $summary$- str means text.
- int means a whole number.
- float means a decimal number.
- bool means True or False.$summary$,
    2
  ),
  (
    '20000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000001',
    'python-conditionals',
    'Conditionals',
    'Use if statements to make decisions in code.',
    $concept$Conditionals let a program choose what to do. If a condition is true, Python runs one block. Otherwise, it can run another block.

This is like deciding what to study based on your quiz score.$concept$,
    $code$score = 72

if score >= 80:
    print("Move to the next lesson")
elif score >= 60:
    print("Review and try again")
else:
    print("Study the concept again")$code$,
    $summary$- if checks the first condition.
- elif checks another condition.
- else runs when the earlier conditions are false.$summary$,
    3
  ),
  (
    '20000000-0000-4000-8000-000000000004',
    '10000000-0000-4000-8000-000000000001',
    'python-loops',
    'Loops',
    'Repeat work with for loops.',
    $concept$A loop repeats the same kind of work. A for loop is useful when you have a list of items and want to handle each one.

For example, you can print a study checklist item by item.$concept$,
    $code$topics = ["variables", "data types", "conditionals", "loops"]

for topic in topics:
    print("Study:", topic)$code$,
    $summary$- A loop repeats work.
- for loops are useful for lists.
- The indented block runs once for each item.$summary$,
    4
  )
on conflict (id) do update
set module_id = excluded.module_id,
    slug = excluded.slug,
    title = excluded.title,
    objective = excluded.objective,
    concept = excluded.concept,
    example_code = excluded.example_code,
    summary = excluded.summary,
    sort_order = excluded.sort_order;

insert into public.quizzes (id, lesson_id, question, explanation, sort_order)
values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'What does a Python variable do?', 'A variable stores a value under a reusable name.', 1),
  ('30000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 'Which data type is used for text?', 'Text values are strings, also called str in Python.', 1),
  ('30000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000003', 'Which keyword starts a basic condition?', 'if starts a basic conditional branch.', 1),
  ('30000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000004', 'What is a loop used for?', 'A loop repeats work, often for each item in a list.', 1)
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    question = excluded.question,
    explanation = excluded.explanation,
    sort_order = excluded.sort_order;

insert into public.quiz_options (id, quiz_id, option_text, is_correct, sort_order)
values
  ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'It stores a value with a name.', true, 1),
  ('40000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', 'It deletes all code.', false, 2),
  ('40000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000001', 'It only changes colors.', false, 3),
  ('40000000-0000-4000-8000-000000000004', '30000000-0000-4000-8000-000000000002', 'str', true, 1),
  ('40000000-0000-4000-8000-000000000005', '30000000-0000-4000-8000-000000000002', 'int', false, 2),
  ('40000000-0000-4000-8000-000000000006', '30000000-0000-4000-8000-000000000002', 'bool', false, 3),
  ('40000000-0000-4000-8000-000000000007', '30000000-0000-4000-8000-000000000003', 'if', true, 1),
  ('40000000-0000-4000-8000-000000000008', '30000000-0000-4000-8000-000000000003', 'repeat', false, 2),
  ('40000000-0000-4000-8000-000000000009', '30000000-0000-4000-8000-000000000003', 'folder', false, 3),
  ('40000000-0000-4000-8000-000000000010', '30000000-0000-4000-8000-000000000004', 'To repeat work.', true, 1),
  ('40000000-0000-4000-8000-000000000011', '30000000-0000-4000-8000-000000000004', 'To stop the computer.', false, 2),
  ('40000000-0000-4000-8000-000000000012', '30000000-0000-4000-8000-000000000004', 'To create an account.', false, 3)
on conflict (id) do update
set quiz_id = excluded.quiz_id,
    option_text = excluded.option_text,
    is_correct = excluded.is_correct,
    sort_order = excluded.sort_order;
