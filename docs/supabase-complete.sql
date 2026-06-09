
-- ============================================================
-- docs\supabase.sql
-- ============================================================

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

-- ============================================================
-- docs\mvp2-migration.sql
-- ============================================================

-- PMLE Pathfinder MVP2 learning records and extended curriculum
-- Apply after docs/supabase.sql.

create table if not exists public.learning_journal (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete set null,
  journal_date date not null default current_date,
  study_minutes integer not null default 0 check (study_minutes >= 0),
  understanding_score integer not null default 0 check (understanding_score between 0 and 100),
  content text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.concept_mastery (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  concept_name text not null,
  mastery_score integer not null default 0 check (mastery_score between 0 and 100),
  is_weak boolean not null default false,
  note text not null default '',
  last_reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id, concept_name)
);

create table if not exists public.review_schedule (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  review_step integer not null check (review_step in (1, 3, 7, 14)),
  due_date date not null,
  completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id, review_step)
);

create index if not exists idx_learning_journal_user_date on public.learning_journal(user_id, journal_date desc);
create index if not exists idx_concept_mastery_user_weak on public.concept_mastery(user_id, is_weak, mastery_score);
create index if not exists idx_review_schedule_user_due on public.review_schedule(user_id, completed, due_date);

drop trigger if exists set_learning_journal_updated_at on public.learning_journal;
create trigger set_learning_journal_updated_at before update on public.learning_journal
for each row execute function public.set_updated_at();

drop trigger if exists set_concept_mastery_updated_at on public.concept_mastery;
create trigger set_concept_mastery_updated_at before update on public.concept_mastery
for each row execute function public.set_updated_at();

drop trigger if exists set_review_schedule_updated_at on public.review_schedule;
create trigger set_review_schedule_updated_at before update on public.review_schedule
for each row execute function public.set_updated_at();

alter table public.learning_journal enable row level security;
alter table public.concept_mastery enable row level security;
alter table public.review_schedule enable row level security;

drop policy if exists "learning journal select own" on public.learning_journal;
create policy "learning journal select own" on public.learning_journal
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "learning journal insert own" on public.learning_journal;
create policy "learning journal insert own" on public.learning_journal
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "learning journal update own" on public.learning_journal;
create policy "learning journal update own" on public.learning_journal
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "learning journal delete own" on public.learning_journal;
create policy "learning journal delete own" on public.learning_journal
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "concept mastery select own" on public.concept_mastery;
create policy "concept mastery select own" on public.concept_mastery
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "concept mastery insert own" on public.concept_mastery;
create policy "concept mastery insert own" on public.concept_mastery
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "concept mastery update own" on public.concept_mastery;
create policy "concept mastery update own" on public.concept_mastery
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "concept mastery delete own" on public.concept_mastery;
create policy "concept mastery delete own" on public.concept_mastery
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "review schedule select own" on public.review_schedule;
create policy "review schedule select own" on public.review_schedule
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "review schedule insert own" on public.review_schedule;
create policy "review schedule insert own" on public.review_schedule
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "review schedule update own" on public.review_schedule;
create policy "review schedule update own" on public.review_schedule
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "review schedule delete own" on public.review_schedule;
create policy "review schedule delete own" on public.review_schedule
for delete to authenticated using (auth.uid() = user_id);

insert into public.modules (id, title, description, sort_order)
values
  ('10000000-0000-4000-8000-000000000002', 'Python Advanced', 'Functions, lists, dictionaries, file input/output, and exception handling.', 2),
  ('10000000-0000-4000-8000-000000000003', 'Data Analysis', 'NumPy, Pandas, CSV files, missing values, and data visualization.', 3),
  ('10000000-0000-4000-8000-000000000004', 'Statistics', 'Mean, variance, standard deviation, probability, and correlation for ML foundations.', 4)
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    sort_order = excluded.sort_order;

insert into public.lessons (id, module_id, slug, title, objective, concept, example_code, summary, sort_order)
values
  ('21000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'python-functions', 'Functions', 'Reuse code by naming a repeatable task.', $c$A function is a reusable block of code. It can receive inputs, do work, and return a result.$c$, $e$def add(a, b):
    return a + b

print(add(3, 5))$e$, $s$- def creates a function.
- Parameters are inputs.
- return sends a result back.$s$, 5),
  ('21000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'python-lists', 'Lists', 'Store several values in order.', $c$A list stores multiple values under one name. You can read items by index and add items with append.$c$, $e$scores = [80, 90, 75]
scores.append(100)
print(scores[1])
print(scores)$e$, $s$- Lists use square brackets.
- Indexes start at 0.
- append adds a new item.$s$, 6),
  ('21000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'python-dictionaries', 'Dictionaries', 'Store data with key and value pairs.', $c$A dictionary stores data as key-value pairs. It is useful when each value has a meaningful label.$c$, $e$student = {"name": "PMLE", "hours": 7}
print(student["name"])
student["goal"] = "AI Engineer"
print(student)$e$, $s$- Dictionaries use curly braces.
- Keys retrieve values.
- They are useful for structured data.$s$, 7),
  ('21000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', 'python-file-io', 'File Input Output', 'Read from and write to files.', $c$File input/output lets Python exchange data with files outside the program. The with open pattern closes files safely.$c$, $e$with open("memo.txt", "w", encoding="utf-8") as file:
    file.write("study log")

with open("memo.txt", "r", encoding="utf-8") as file:
    print(file.read())$e$, $s$- w means write mode.
- r means read mode.
- with closes the file safely.$s$, 8),
  ('21000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000002', 'python-exceptions', 'Exceptions', 'Handle errors without stopping the whole program.', $c$Exception handling catches runtime errors and lets the program respond. try runs risky code, and except handles a specific error.$c$, $e$text = "10"

try:
    number = int(text)
    print(number)
except ValueError:
    print("Cannot convert to a number")$e$, $s$- try watches code that might fail.
- except handles the error.
- This is important for user input and files.$s$, 9),
  ('22000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 'data-numpy', 'NumPy', 'Use array-based numeric calculation.', $c$NumPy is a library for fast numeric arrays. Many ML datasets are represented as arrays.$c$, $e$import numpy as np

scores = np.array([80, 90, 100])
print(scores.mean())$e$, $s$- NumPy arrays support vectorized math.
- mean calculates the average.
- np is the common alias.$s$, 10),
  ('22000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000003', 'data-pandas', 'Pandas', 'Read and transform table-shaped data.', $c$Pandas handles table-shaped data. DataFrame is the most common structure for analysis.$c$, $e$import pandas as pd

df = pd.DataFrame({"name": ["A", "B"], "score": [80, 90]})
print(df["score"].mean())$e$, $s$- DataFrame is table data.
- Columns can be selected by name.
- Summary functions help analyze data.$s$, 11),
  ('22000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003', 'data-csv', 'CSV', 'Load CSV files for analysis.', $c$CSV is a common text file format for data. Pandas can load it with read_csv.$c$, $e$import pandas as pd

df = pd.read_csv("students.csv")
print(df.head())$e$, $s$- CSV files are common in data work.
- read_csv loads a file.
- head shows the first rows.$s$, 12),
  ('22000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000003', 'data-missing-values', 'Missing Values', 'Find and handle empty data.', $c$Missing values are empty or unknown values. Before analysis, decide whether to remove, fill, or investigate them.$c$, $e$import pandas as pd

df = pd.DataFrame({"score": [80, None, 90]})
print(df.isna().sum())
df["score"] = df["score"].fillna(df["score"].mean())$e$, $s$- isna finds missing values.
- fillna fills missing values.
- The right choice depends on the analysis goal.$s$, 13),
  ('22000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000003', 'data-visualization', 'Data Visualization', 'Use charts to see patterns.', $c$Visualization makes patterns, trends, and unusual values easier to notice. It also helps explain results.$c$, $e$import pandas as pd
import matplotlib.pyplot as plt

df = pd.DataFrame({"score": [70, 80, 90]})
df["score"].plot(kind="bar")
plt.show()$e$, $s$- Charts reveal patterns.
- Bar charts compare values.
- Visualization supports analysis and explanation.$s$, 14),
  ('23000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000004', 'stats-mean', 'Mean', 'Calculate and interpret an average.', $c$The mean is the sum of values divided by the count. It quickly describes the center of data.$c$, $e$scores = [70, 80, 90]
mean = sum(scores) / len(scores)
print(mean)$e$, $s$- Mean is average.
- Add values and divide by count.
- It is sensitive to outliers.$s$, 15),
  ('23000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000004', 'stats-variance', 'Variance', 'Measure how spread out values are.', $c$Variance measures how far values are from the mean on average. Larger variance means more spread.$c$, $e$scores = [70, 80, 90]
mean = sum(scores) / len(scores)
variance = sum((x - mean) ** 2 for x in scores) / len(scores)
print(variance)$e$, $s$- Variance measures spread.
- It squares distance from the mean.
- Larger variance means wider spread.$s$, 16),
  ('23000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000004', 'stats-standard-deviation', 'Standard Deviation', 'Interpret spread in original units.', $c$Standard deviation is the square root of variance. It is easier to interpret because it uses the original unit.$c$, $e$import math

variance = 66.67
std = math.sqrt(variance)
print(std)$e$, $s$- Standard deviation is sqrt variance.
- It describes data spread.
- Smaller values mean data is closer to the mean.$s$, 17),
  ('23000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000004', 'stats-probability', 'Probability', 'Represent how likely an event is.', $c$Probability is a number from 0 to 1. ML classification models often output probabilities.$c$, $e$favorable = 3
total = 10
probability = favorable / total
print(probability)$e$, $s$- Probability means likelihood.
- 0 means impossible and 1 means certain.
- It matters for classification.$s$, 18),
  ('23000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000004', 'stats-correlation', 'Correlation', 'Understand how two variables move together.', $c$Correlation describes how two variables move together. Positive correlation means they tend to increase together. Correlation is not causation.$c$, $e$import pandas as pd

df = pd.DataFrame({"study_hours": [1, 2, 3], "score": [60, 75, 90]})
print(df.corr())$e$, $s$- Correlation describes relationship.
- Positive means same direction.
- Correlation does not prove causation.$s$, 19)
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
  ('31000000-0000-4000-8000-000000000001', '21000000-0000-4000-8000-000000000001', 'What keyword creates a function?', 'def creates a Python function.', 1),
  ('31000000-0000-4000-8000-000000000002', '21000000-0000-4000-8000-000000000002', 'Which method adds an item to a list?', 'append adds an item to the end of a list.', 1),
  ('31000000-0000-4000-8000-000000000003', '21000000-0000-4000-8000-000000000003', 'What structure uses key-value pairs?', 'A dictionary stores key-value pairs.', 1),
  ('31000000-0000-4000-8000-000000000004', '21000000-0000-4000-8000-000000000004', 'Which mode reads a file?', 'r is read mode.', 1),
  ('31000000-0000-4000-8000-000000000005', '21000000-0000-4000-8000-000000000005', 'Which block handles an error?', 'except handles an error raised in try.', 1),
  ('32000000-0000-4000-8000-000000000001', '22000000-0000-4000-8000-000000000001', 'What is NumPy mainly used for?', 'NumPy supports fast numeric array calculation.', 1),
  ('32000000-0000-4000-8000-000000000002', '22000000-0000-4000-8000-000000000002', 'What is a Pandas DataFrame?', 'A DataFrame is table-shaped data.', 1),
  ('32000000-0000-4000-8000-000000000003', '22000000-0000-4000-8000-000000000003', 'Which Pandas function loads CSV files?', 'read_csv loads CSV files.', 1),
  ('32000000-0000-4000-8000-000000000004', '22000000-0000-4000-8000-000000000004', 'Which function finds missing values?', 'isna helps find missing values.', 1),
  ('32000000-0000-4000-8000-000000000005', '22000000-0000-4000-8000-000000000005', 'Why use visualization?', 'Charts help reveal patterns and explain results.', 1),
  ('33000000-0000-4000-8000-000000000001', '23000000-0000-4000-8000-000000000001', 'What does mean represent?', 'Mean is the average value.', 1),
  ('33000000-0000-4000-8000-000000000002', '23000000-0000-4000-8000-000000000002', 'What does variance measure?', 'Variance measures spread from the mean.', 1),
  ('33000000-0000-4000-8000-000000000003', '23000000-0000-4000-8000-000000000003', 'What is standard deviation?', 'It is the square root of variance.', 1),
  ('33000000-0000-4000-8000-000000000004', '23000000-0000-4000-8000-000000000004', 'What range does probability use?', 'Probability is between 0 and 1.', 1),
  ('33000000-0000-4000-8000-000000000005', '23000000-0000-4000-8000-000000000005', 'Does correlation prove causation?', 'No. Correlation does not prove causation.', 1)
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    question = excluded.question,
    explanation = excluded.explanation,
    sort_order = excluded.sort_order;

insert into public.quiz_options (id, quiz_id, option_text, is_correct, sort_order)
values
  ('41000000-0000-4000-8000-000000000001', '31000000-0000-4000-8000-000000000001', 'def', true, 1),
  ('41000000-0000-4000-8000-000000000002', '31000000-0000-4000-8000-000000000001', 'make', false, 2),
  ('41000000-0000-4000-8000-000000000003', '31000000-0000-4000-8000-000000000001', 'loop', false, 3),
  ('41000000-0000-4000-8000-000000000004', '31000000-0000-4000-8000-000000000002', 'append', true, 1),
  ('41000000-0000-4000-8000-000000000005', '31000000-0000-4000-8000-000000000002', 'delete_all', false, 2),
  ('41000000-0000-4000-8000-000000000006', '31000000-0000-4000-8000-000000000002', 'freeze', false, 3),
  ('41000000-0000-4000-8000-000000000007', '31000000-0000-4000-8000-000000000003', 'Dictionary', true, 1),
  ('41000000-0000-4000-8000-000000000008', '31000000-0000-4000-8000-000000000003', 'String only', false, 2),
  ('41000000-0000-4000-8000-000000000009', '31000000-0000-4000-8000-000000000003', 'Comment', false, 3),
  ('41000000-0000-4000-8000-000000000010', '31000000-0000-4000-8000-000000000004', 'r', true, 1),
  ('41000000-0000-4000-8000-000000000011', '31000000-0000-4000-8000-000000000004', 'paint', false, 2),
  ('41000000-0000-4000-8000-000000000012', '31000000-0000-4000-8000-000000000004', 'sleep', false, 3),
  ('41000000-0000-4000-8000-000000000013', '31000000-0000-4000-8000-000000000005', 'except', true, 1),
  ('41000000-0000-4000-8000-000000000014', '31000000-0000-4000-8000-000000000005', 'folder', false, 2),
  ('41000000-0000-4000-8000-000000000015', '31000000-0000-4000-8000-000000000005', 'chart', false, 3),
  ('42000000-0000-4000-8000-000000000001', '32000000-0000-4000-8000-000000000001', 'Numeric array calculation', true, 1),
  ('42000000-0000-4000-8000-000000000002', '32000000-0000-4000-8000-000000000001', 'Email design only', false, 2),
  ('42000000-0000-4000-8000-000000000003', '32000000-0000-4000-8000-000000000001', 'Password storage only', false, 3),
  ('42000000-0000-4000-8000-000000000004', '32000000-0000-4000-8000-000000000002', 'Table-shaped data', true, 1),
  ('42000000-0000-4000-8000-000000000005', '32000000-0000-4000-8000-000000000002', 'Single password', false, 2),
  ('42000000-0000-4000-8000-000000000006', '32000000-0000-4000-8000-000000000002', 'Screen color', false, 3),
  ('42000000-0000-4000-8000-000000000007', '32000000-0000-4000-8000-000000000003', 'read_csv', true, 1),
  ('42000000-0000-4000-8000-000000000008', '32000000-0000-4000-8000-000000000003', 'read_color', false, 2),
  ('42000000-0000-4000-8000-000000000009', '32000000-0000-4000-8000-000000000003', 'open_account', false, 3),
  ('42000000-0000-4000-8000-000000000010', '32000000-0000-4000-8000-000000000004', 'isna', true, 1),
  ('42000000-0000-4000-8000-000000000011', '32000000-0000-4000-8000-000000000004', 'paint', false, 2),
  ('42000000-0000-4000-8000-000000000012', '32000000-0000-4000-8000-000000000004', 'deploy', false, 3),
  ('42000000-0000-4000-8000-000000000013', '32000000-0000-4000-8000-000000000005', 'To see patterns', true, 1),
  ('42000000-0000-4000-8000-000000000014', '32000000-0000-4000-8000-000000000005', 'To hide data', false, 2),
  ('42000000-0000-4000-8000-000000000015', '32000000-0000-4000-8000-000000000005', 'To delete Python', false, 3),
  ('43000000-0000-4000-8000-000000000001', '33000000-0000-4000-8000-000000000001', 'Average', true, 1),
  ('43000000-0000-4000-8000-000000000002', '33000000-0000-4000-8000-000000000001', 'Maximum only', false, 2),
  ('43000000-0000-4000-8000-000000000003', '33000000-0000-4000-8000-000000000001', 'File name', false, 3),
  ('43000000-0000-4000-8000-000000000004', '33000000-0000-4000-8000-000000000002', 'Spread', true, 1),
  ('43000000-0000-4000-8000-000000000005', '33000000-0000-4000-8000-000000000002', 'Font size', false, 2),
  ('43000000-0000-4000-8000-000000000006', '33000000-0000-4000-8000-000000000002', 'Login time', false, 3),
  ('43000000-0000-4000-8000-000000000007', '33000000-0000-4000-8000-000000000003', 'Square root of variance', true, 1),
  ('43000000-0000-4000-8000-000000000008', '33000000-0000-4000-8000-000000000003', 'A list method', false, 2),
  ('43000000-0000-4000-8000-000000000009', '33000000-0000-4000-8000-000000000003', 'A file mode', false, 3),
  ('43000000-0000-4000-8000-000000000010', '33000000-0000-4000-8000-000000000004', '0 to 1', true, 1),
  ('43000000-0000-4000-8000-000000000011', '33000000-0000-4000-8000-000000000004', '10 to 20', false, 2),
  ('43000000-0000-4000-8000-000000000012', '33000000-0000-4000-8000-000000000004', 'Only negative values', false, 3),
  ('43000000-0000-4000-8000-000000000013', '33000000-0000-4000-8000-000000000005', 'No', true, 1),
  ('43000000-0000-4000-8000-000000000014', '33000000-0000-4000-8000-000000000005', 'Always yes', false, 2),
  ('43000000-0000-4000-8000-000000000015', '33000000-0000-4000-8000-000000000005', 'Only in Python', false, 3)
on conflict (id) do update
set quiz_id = excluded.quiz_id,
    option_text = excluded.option_text,
    is_correct = excluded.is_correct,
    sort_order = excluded.sort_order;

-- ============================================================
-- docs\mvp3-ai-tutor-migration.sql
-- ============================================================

-- PMLE Pathfinder MVP3 Gemini AI tutor migration
-- Apply after docs/supabase.sql and docs/mvp2-migration.sql.

create table if not exists public.ai_chat_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete set null,
  title text not null default 'AI Tutor Chat',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_chat_messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.ai_chat_sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.saved_ai_explanations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid references public.ai_chat_sessions(id) on delete set null,
  message_id uuid references public.ai_chat_messages(id) on delete set null,
  lesson_id uuid references public.lessons(id) on delete set null,
  title text not null default 'AI Explanation',
  content text not null,
  source_question text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ai_chat_sessions_user_updated on public.ai_chat_sessions(user_id, updated_at desc);
create index if not exists idx_ai_chat_messages_session_created on public.ai_chat_messages(session_id, created_at);
create index if not exists idx_saved_ai_explanations_user_updated on public.saved_ai_explanations(user_id, updated_at desc);

drop trigger if exists set_ai_chat_sessions_updated_at on public.ai_chat_sessions;
create trigger set_ai_chat_sessions_updated_at before update on public.ai_chat_sessions
for each row execute function public.set_updated_at();

drop trigger if exists set_saved_ai_explanations_updated_at on public.saved_ai_explanations;
create trigger set_saved_ai_explanations_updated_at before update on public.saved_ai_explanations
for each row execute function public.set_updated_at();

alter table public.ai_chat_sessions enable row level security;
alter table public.ai_chat_messages enable row level security;
alter table public.saved_ai_explanations enable row level security;

drop policy if exists "ai sessions select own" on public.ai_chat_sessions;
create policy "ai sessions select own" on public.ai_chat_sessions
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "ai sessions insert own" on public.ai_chat_sessions;
create policy "ai sessions insert own" on public.ai_chat_sessions
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "ai sessions update own" on public.ai_chat_sessions;
create policy "ai sessions update own" on public.ai_chat_sessions
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "ai sessions delete own" on public.ai_chat_sessions;
create policy "ai sessions delete own" on public.ai_chat_sessions
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "ai messages select own" on public.ai_chat_messages;
create policy "ai messages select own" on public.ai_chat_messages
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "ai messages insert own" on public.ai_chat_messages;
create policy "ai messages insert own" on public.ai_chat_messages
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "saved ai explanations select own" on public.saved_ai_explanations;
create policy "saved ai explanations select own" on public.saved_ai_explanations
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "saved ai explanations insert own" on public.saved_ai_explanations;
create policy "saved ai explanations insert own" on public.saved_ai_explanations
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "saved ai explanations update own" on public.saved_ai_explanations;
create policy "saved ai explanations update own" on public.saved_ai_explanations
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "saved ai explanations delete own" on public.saved_ai_explanations;
create policy "saved ai explanations delete own" on public.saved_ai_explanations
for delete to authenticated using (auth.uid() = user_id);

-- ============================================================
-- docs\mvp4-coding-lab-migration.sql
-- ============================================================

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

-- ============================================================
-- docs\mvp5-ml-course-migration.sql
-- ============================================================

-- PMLE Pathfinder MVP5 Machine Learning course migration
-- Apply after MVP1-MVP4 migrations.

create table if not exists public.ml_concept_map (
  id uuid primary key default gen_random_uuid(),
  source_concept text not null,
  target_concept text not null,
  relation text not null,
  description text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.ml_concept_map enable row level security;

drop policy if exists "ml concept map read authenticated" on public.ml_concept_map;
create policy "ml concept map read authenticated" on public.ml_concept_map
for select to authenticated using (true);

insert into public.modules (id, title, description, sort_order)
values
  (
    '10000000-0000-4000-8000-000000000005',
    'Machine Learning',
    'Learn supervised learning, unsupervised learning, regression, classification, overfitting, metrics, and Scikit-learn.',
    5
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    sort_order = excluded.sort_order;

insert into public.lessons (id, module_id, slug, title, objective, concept, example_code, summary, sort_order)
values
  (
    '24000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000005',
    'ml-supervised-learning',
    'Supervised Learning',
    'Learn how models train from labeled examples.',
    $concept$Supervised learning uses examples that include both input data and the correct answer. The model learns a rule that maps inputs to labels.

Common supervised learning tasks include regression and classification.$concept$,
    $code$X = [[1], [2], [3]]
y = [60, 75, 90]

print("inputs:", X)
print("labels:", y)$code$,
    $summary$- Supervised learning uses labeled data.
- Regression predicts numbers.
- Classification predicts categories.$summary$,
    20
  ),
  (
    '24000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000005',
    'ml-unsupervised-learning',
    'Unsupervised Learning',
    'Find patterns without labeled answers.',
    $concept$Unsupervised learning works with input data only. It tries to discover structure, groups, or patterns without a correct label.

Clustering customers by behavior is a common example.$concept$,
    $code$X = [[1, 2], [1, 3], [9, 8]]

print("find patterns from data")$code$,
    $summary$- Unsupervised learning has no labels.
- Clustering and dimensionality reduction are common examples.
- It is useful for pattern discovery.$summary$,
    21
  ),
  (
    '24000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000005',
    'ml-regression',
    'Regression',
    'Predict continuous numeric values.',
    $concept$Regression predicts numbers. Examples include predicting a test score, house price, sales amount, or delivery time.

If the answer is a continuous number, think regression.$concept$,
    $code$from sklearn.linear_model import LinearRegression

X = [[1], [2], [3]]
y = [60, 75, 90]

model = LinearRegression()
model.fit(X, y)
print(model.predict([[4]]))$code$,
    $summary$- Regression predicts numeric values.
- Linear regression is a common first model.
- The prediction is continuous.$summary$,
    22
  ),
  (
    '24000000-0000-4000-8000-000000000004',
    '10000000-0000-4000-8000-000000000005',
    'ml-classification',
    'Classification',
    'Predict categories or labels.',
    $concept$Classification predicts a category. Examples include spam or not spam, pass or fail, churn or stay, and dog or cat.

If the answer is a label, think classification.$concept$,
    $code$from sklearn.tree import DecisionTreeClassifier

X = [[1], [2], [8], [9]]
y = ["low", "low", "high", "high"]

model = DecisionTreeClassifier()
model.fit(X, y)
print(model.predict([[7]]))$code$,
    $summary$- Classification predicts labels.
- Output is a class or category.
- Accuracy is a common metric.$summary$,
    23
  ),
  (
    '24000000-0000-4000-8000-000000000005',
    '10000000-0000-4000-8000-000000000005',
    'ml-overfitting',
    'Overfitting',
    'Understand when a model memorizes training data too closely.',
    $concept$Overfitting happens when a model performs well on training data but poorly on new data. It is like memorizing practice questions instead of learning the concept.

Validation data helps detect overfitting.$concept$,
    $code$train_score = 0.99
test_score = 0.62

if train_score > 0.95 and test_score < 0.7:
    print("overfitting risk")$code$,
    $summary$- Overfitting means training performance is misleadingly high.
- Poor test performance is a warning sign.
- Validation helps control it.$summary$,
    24
  ),
  (
    '24000000-0000-4000-8000-000000000006',
    '10000000-0000-4000-8000-000000000005',
    'ml-metrics',
    'Evaluation Metrics',
    'Measure model performance based on the problem type.',
    $concept$Evaluation metrics show how well a model works. Regression uses error metrics such as MAE or RMSE. Classification uses metrics such as accuracy, precision, recall, and F1.

Choose a metric that matches the business goal.$concept$,
    $code$from sklearn.metrics import accuracy_score

y_true = [1, 0, 1, 1]
y_pred = [1, 0, 0, 1]

print(accuracy_score(y_true, y_pred))$code$,
    $summary$- Metrics measure performance.
- Regression and classification use different metrics.
- Business goals should guide metric choice.$summary$,
    25
  ),
  (
    '24000000-0000-4000-8000-000000000007',
    '10000000-0000-4000-8000-000000000005',
    'ml-scikit-learn',
    'Scikit-learn',
    'Practice the basic ML workflow in Python.',
    $concept$Scikit-learn is a Python library for machine learning practice. The common workflow is prepare data, split train/test data, create a model, fit it, predict, and evaluate.

This workflow helps connect coding practice with PMLE concepts.$concept$,
    $code$from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

X_train, X_test, y_train, y_test = train_test_split(X, y)
model = LinearRegression()
model.fit(X_train, y_train)
predictions = model.predict(X_test)$code$,
    $summary$- fit trains the model.
- predict creates predictions.
- train/test split checks generalization.$summary$,
    26
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
  ('34000000-0000-4000-8000-000000000001', '24000000-0000-4000-8000-000000000001', 'What is the key trait of supervised learning?', 'Supervised learning uses labeled examples.', 1),
  ('34000000-0000-4000-8000-000000000002', '24000000-0000-4000-8000-000000000002', 'What does unsupervised learning look for?', 'It looks for patterns without labels.', 1),
  ('34000000-0000-4000-8000-000000000003', '24000000-0000-4000-8000-000000000003', 'What does regression predict?', 'Regression predicts continuous numeric values.', 1),
  ('34000000-0000-4000-8000-000000000004', '24000000-0000-4000-8000-000000000004', 'What does classification predict?', 'Classification predicts categories or labels.', 1),
  ('34000000-0000-4000-8000-000000000005', '24000000-0000-4000-8000-000000000005', 'What is a sign of overfitting?', 'High training score but low test score suggests overfitting.', 1),
  ('34000000-0000-4000-8000-000000000006', '24000000-0000-4000-8000-000000000006', 'Which metric is common for classification?', 'Accuracy is a common classification metric.', 1),
  ('34000000-0000-4000-8000-000000000007', '24000000-0000-4000-8000-000000000007', 'Which Scikit-learn method trains a model?', 'fit trains the model on data.', 1)
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    question = excluded.question,
    explanation = excluded.explanation,
    sort_order = excluded.sort_order;

insert into public.quiz_options (id, quiz_id, option_text, is_correct, sort_order)
values
  ('54000000-0000-4000-8000-000000000001', '34000000-0000-4000-8000-000000000001', 'It has correct labels', true, 1),
  ('54000000-0000-4000-8000-000000000002', '34000000-0000-4000-8000-000000000001', 'It has no data', false, 2),
  ('54000000-0000-4000-8000-000000000003', '34000000-0000-4000-8000-000000000001', 'It only changes colors', false, 3),
  ('54000000-0000-4000-8000-000000000004', '34000000-0000-4000-8000-000000000002', 'Patterns without labels', true, 1),
  ('54000000-0000-4000-8000-000000000005', '34000000-0000-4000-8000-000000000002', 'Only labeled answers', false, 2),
  ('54000000-0000-4000-8000-000000000006', '34000000-0000-4000-8000-000000000002', 'Only code length', false, 3),
  ('54000000-0000-4000-8000-000000000007', '34000000-0000-4000-8000-000000000003', 'A number', true, 1),
  ('54000000-0000-4000-8000-000000000008', '34000000-0000-4000-8000-000000000003', 'A class label only', false, 2),
  ('54000000-0000-4000-8000-000000000009', '34000000-0000-4000-8000-000000000003', 'A file name only', false, 3),
  ('54000000-0000-4000-8000-000000000010', '34000000-0000-4000-8000-000000000004', 'A category', true, 1),
  ('54000000-0000-4000-8000-000000000011', '34000000-0000-4000-8000-000000000004', 'A continuous price only', false, 2),
  ('54000000-0000-4000-8000-000000000012', '34000000-0000-4000-8000-000000000004', 'A folder path', false, 3),
  ('54000000-0000-4000-8000-000000000013', '34000000-0000-4000-8000-000000000005', 'High train score and low test score', true, 1),
  ('54000000-0000-4000-8000-000000000014', '34000000-0000-4000-8000-000000000005', 'Perfect generalization', false, 2),
  ('54000000-0000-4000-8000-000000000015', '34000000-0000-4000-8000-000000000005', 'No training data', false, 3),
  ('54000000-0000-4000-8000-000000000016', '34000000-0000-4000-8000-000000000006', 'Accuracy', true, 1),
  ('54000000-0000-4000-8000-000000000017', '34000000-0000-4000-8000-000000000006', 'File size', false, 2),
  ('54000000-0000-4000-8000-000000000018', '34000000-0000-4000-8000-000000000006', 'Screen width', false, 3),
  ('54000000-0000-4000-8000-000000000019', '34000000-0000-4000-8000-000000000007', 'fit', true, 1),
  ('54000000-0000-4000-8000-000000000020', '34000000-0000-4000-8000-000000000007', 'paint', false, 2),
  ('54000000-0000-4000-8000-000000000021', '34000000-0000-4000-8000-000000000007', 'rename', false, 3)
on conflict (id) do update
set quiz_id = excluded.quiz_id,
    option_text = excluded.option_text,
    is_correct = excluded.is_correct,
    sort_order = excluded.sort_order;

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
    '61000000-0000-4000-8000-000000000001',
    '24000000-0000-4000-8000-000000000003',
    'Create regression inputs and labels',
    'Practice building X and y for a supervised regression problem.',
    'Create X as [[1], [2], [3]] and y as [60, 75, 90]. Print labels: and y.',
    'X = []\ny = []\n\nprint("labels:", y)',
    'labels: [60, 75, 90]',
    array['X', 'y', 'print'],
    'X\\s*=\\s*\\[\\s*\\[\\s*1\\s*\\]\\s*,\\s*\\[\\s*2\\s*\\]\\s*,\\s*\\[\\s*3\\s*\\]\\s*\\].*y\\s*=\\s*\\[\\s*60\\s*,\\s*75\\s*,\\s*90\\s*\\].*print\\s*\\(\\s*["'']labels:["'']\\s*,\\s*y\\s*\\)',
    'easy',
    40
  ),
  (
    '61000000-0000-4000-8000-000000000002',
    '24000000-0000-4000-8000-000000000007',
    'Use fit and predict names',
    'Practice the basic Scikit-learn vocabulary without executing code.',
    'Write simple placeholder lines that mention fit and predict, then print workflow.',
    'workflow = ""\nprint(workflow)',
    'fit predict',
    array['fit', 'predict', 'print'],
    'fit.*predict.*print|predict.*fit.*print',
    'medium',
    41
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

insert into public.ml_concept_map (id, source_concept, target_concept, relation, description, sort_order)
values
  ('70000000-0000-4000-8000-000000000001', 'Supervised Learning', 'Regression', 'includes', 'Regression is a supervised learning task for numeric prediction.', 1),
  ('70000000-0000-4000-8000-000000000002', 'Supervised Learning', 'Classification', 'includes', 'Classification is a supervised learning task for category prediction.', 2),
  ('70000000-0000-4000-8000-000000000003', 'Overfitting', 'Evaluation Metrics', 'detected by', 'Metrics on validation or test data help reveal overfitting.', 3),
  ('70000000-0000-4000-8000-000000000004', 'Scikit-learn', 'Machine Learning Workflow', 'implements', 'Scikit-learn uses fit, predict, and evaluate as a common workflow.', 4)
on conflict (id) do update
set source_concept = excluded.source_concept,
    target_concept = excluded.target_concept,
    relation = excluded.relation,
    description = excluded.description,
    sort_order = excluded.sort_order;

-- ============================================================
-- docs\mvp6-gcp-vertex-migration.sql
-- ============================================================

-- PMLE Pathfinder MVP6 GCP + Vertex AI course migration
-- Apply after MVP1-MVP5 migrations.

create table if not exists public.exam_domains (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  weight_percent integer,
  exam_points text[] not null default '{}',
  practical_points text[] not null default '{}',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.service_comparisons (
  id uuid primary key default gen_random_uuid(),
  service_name text not null,
  category text not null,
  best_for text not null default '',
  avoid_when text not null default '',
  exam_point text not null default '',
  practical_point text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.scenario_questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references public.lessons(id) on delete set null,
  title text not null,
  scenario text not null,
  options jsonb not null default '[]'::jsonb,
  correct_option_index integer not null default 0,
  explanation text not null default '',
  exam_point text not null default '',
  practical_point text not null default '',
  difficulty text not null default 'medium' check (difficulty in ('easy', 'medium', 'hard')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.exam_domains enable row level security;
alter table public.service_comparisons enable row level security;
alter table public.scenario_questions enable row level security;

drop policy if exists "exam domains read authenticated" on public.exam_domains;
create policy "exam domains read authenticated" on public.exam_domains
for select to authenticated using (true);

drop policy if exists "service comparisons read authenticated" on public.service_comparisons;
create policy "service comparisons read authenticated" on public.service_comparisons
for select to authenticated using (true);

drop policy if exists "scenario questions read authenticated" on public.scenario_questions;
create policy "scenario questions read authenticated" on public.scenario_questions
for select to authenticated using (true);

insert into public.modules (id, title, description, sort_order)
values
  (
    '10000000-0000-4000-8000-000000000006',
    'GCP + Vertex AI',
    'Learn the Google Cloud and Vertex AI foundations needed for PMLE: cloud basics, IAM, storage, analytics, compute, serverless, model training, registry, endpoints, and monitoring.',
    6
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    sort_order = excluded.sort_order;

insert into public.lessons (id, module_id, slug, title, objective, concept, example_code, summary, sort_order)
values
  (
    '25000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000006',
    'gcp-cloud-fundamentals',
    'Cloud Fundamentals',
    'Understand projects, regions, APIs, billing, and the basic Google Cloud resource model.',
    $concept$Google Cloud organizes work around projects. A project is the main container for resources, IAM, APIs, and billing. Regions and zones decide where resources run, which affects latency, availability, compliance, and cost.

For PMLE scenarios, first identify the business goal, data location, latency target, security requirement, and whether a managed service can reduce operational work.$concept$,
    $code$gcloud projects list
gcloud config set project my-project
gcloud services enable aiplatform.googleapis.com$code$,
    $summary$- Projects are the basic management and billing unit.
- APIs must be enabled before services can be used.
- Region choice affects latency, cost, security, and availability.$summary$,
    30
  ),
  (
    '25000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000006',
    'gcp-iam',
    'IAM',
    'Control who can access which Google Cloud resources and what they can do.',
    $concept$IAM connects members, roles, and resources. A member can be a user, group, or service account. A role is a set of permissions. A resource is the thing being accessed.

For ML systems, service accounts are often the identity used by training jobs, pipelines, and deployed services. The safest default is least privilege: grant only the roles needed for the task.$concept$,
    $code$gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:trainer@my-project.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"$code$,
    $summary$- IAM is built from member, role, and resource.
- Service accounts are identities for applications and workloads.
- Least privilege is a common exam and production requirement.$summary$,
    31
  ),
  (
    '25000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000006',
    'gcp-storage',
    'Storage',
    'Use Cloud Storage as a data and model artifact store.',
    $concept$Cloud Storage stores objects inside buckets. It is a good fit for files such as CSVs, images, training data, model artifacts, and exported assets.

Vertex AI jobs often read input data from Cloud Storage and write model artifacts back to Cloud Storage.$concept$,
    $code$gsutil mb gs://my-ml-bucket
gsutil cp data.csv gs://my-ml-bucket/data/data.csv$code$,
    $summary$- Cloud Storage is object storage.
- Bucket names must be globally unique.
- It is often used for training data and model artifacts.$summary$,
    32
  ),
  (
    '25000000-0000-4000-8000-000000000004',
    '10000000-0000-4000-8000-000000000006',
    'gcp-bigquery',
    'BigQuery',
    'Analyze large tabular datasets and understand when BigQuery ML is useful.',
    $concept$BigQuery is a serverless data warehouse for large-scale SQL analytics. It is useful when data is already tabular and the team needs fast analysis, feature exploration, or SQL-based machine learning through BigQuery ML.

PMLE questions often ask whether a workload is analytics-first, storage-first, or model-serving-first.$concept$,
    $code$SELECT
  AVG(score) AS avg_score
FROM `project.dataset.training_data`;$code$,
    $summary$- BigQuery is best for large-scale SQL analytics.
- BigQuery ML supports SQL-based model training.
- It is useful for feature exploration and data preparation.$summary$,
    33
  ),
  (
    '25000000-0000-4000-8000-000000000005',
    '10000000-0000-4000-8000-000000000006',
    'gcp-compute-engine',
    'Compute Engine',
    'Recognize when a managed VM is appropriate for ML work.',
    $concept$Compute Engine provides virtual machines. It gives deep control over OS, machine type, GPUs, disks, and networking, but it also adds operational responsibility.

For PMLE, Compute Engine can be correct when the scenario requires custom infrastructure, special GPU setup, or direct VM control. It is usually not the first choice for managed ML workflows.$concept$,
    $code$gcloud compute instances create ml-vm \
  --machine-type=n1-standard-4 \
  --zone=us-central1-a$code$,
    $summary$- Compute Engine is VM-based compute.
- It gives control but increases operations work.
- Consider it for special environments or GPU experiments.$summary$,
    34
  ),
  (
    '25000000-0000-4000-8000-000000000006',
    '10000000-0000-4000-8000-000000000006',
    'gcp-cloud-functions',
    'Cloud Functions',
    'Use serverless functions for small event-driven automation.',
    $concept$Cloud Functions runs small pieces of code in response to events such as file uploads, messages, or HTTP requests. It is useful for glue logic and lightweight automation.

For ML, Cloud Functions can trigger a workflow or process a small event. It is not a good fit for long-running training jobs.$concept$,
    $code$def hello_gcs(event, context):
    print("file uploaded:", event["name"])$code$,
    $summary$- Cloud Functions is event-driven serverless compute.
- It is useful for small automation tasks.
- It is not ideal for heavy training workloads.$summary$,
    35
  ),
  (
    '25000000-0000-4000-8000-000000000007',
    '10000000-0000-4000-8000-000000000006',
    'gcp-vertex-ai',
    'Vertex AI',
    'Understand Vertex AI as Google Cloud''s managed ML platform.',
    $concept$Vertex AI is Google Cloud's unified ML platform. It connects datasets, training, experiments, model registry, deployment, prediction, and monitoring.

For PMLE, you must compare AutoML, custom training, endpoints, batch prediction, model registry, and monitoring based on business requirements.$concept$,
    $code$from google.cloud import aiplatform

aiplatform.init(project="my-project", location="us-central1")$code$,
    $summary$- Vertex AI manages the ML workflow.
- It supports AutoML and custom training.
- It connects model deployment and monitoring.$summary$,
    36
  ),
  (
    '25000000-0000-4000-8000-000000000008',
    '10000000-0000-4000-8000-000000000006',
    'gcp-automl',
    'AutoML',
    'Choose AutoML when a fast low-code model baseline is appropriate.',
    $concept$AutoML trains models with less manual model design. It is useful when the learner or team has labeled data and needs a fast baseline for tabular, image, text, or similar tasks.

If the scenario needs deep algorithm control, special training code, or custom architecture, custom training is usually a better fit.$concept$,
    $code$training_method = "AutoML"
print(training_method)$code$,
    $summary$- AutoML is a low-code training approach.
- It is useful for fast baselines.
- Use custom training when model control matters.$summary$,
    37
  ),
  (
    '25000000-0000-4000-8000-000000000009',
    '10000000-0000-4000-8000-000000000006',
    'gcp-model-registry',
    'Model Registry',
    'Track model versions, metadata, and deployment status.',
    $concept$Model Registry is the place to register and manage models. It helps teams compare model versions, track metadata, and connect model governance to deployment.

In production, it matters who trained a model, what data was used, what version is deployed, and how rollback will work.$concept$,
    $code$model_name = "churn-model"
version = "v1"
print(model_name, version)$code$,
    $summary$- Model Registry manages model versions.
- It supports traceability and deployment governance.
- It is important for MLOps and rollback planning.$summary$,
    38
  ),
  (
    '25000000-0000-4000-8000-000000000010',
    '10000000-0000-4000-8000-000000000006',
    'gcp-endpoints',
    'Endpoints',
    'Serve online predictions from deployed Vertex AI models.',
    $concept$A Vertex AI endpoint is the online entry point for prediction requests. Applications send inputs to the endpoint and receive prediction results.

PMLE scenarios may ask about online prediction, batch prediction, autoscaling, traffic split, public access, private access, and latency requirements.$concept$,
    $code$endpoint = "projects/.../locations/us-central1/endpoints/123"
print("send prediction request to", endpoint)$code$,
    $summary$- Endpoints serve online predictions.
- Traffic split can route traffic across model versions.
- Latency, scaling, and security must be considered.$summary$,
    39
  ),
  (
    '25000000-0000-4000-8000-000000000011',
    '10000000-0000-4000-8000-000000000006',
    'gcp-monitoring',
    'Monitoring',
    'Monitor model and service health after deployment.',
    $concept$Monitoring checks whether the deployed model and service are still healthy. It can include latency, error rates, prediction volume, data drift, skew, and alerts.

Operational ML is not finished at deployment. A production model needs feedback loops, alerts, and review processes.$concept$,
    $code$metrics = ["latency", "errors", "drift"]
for metric in metrics:
    print("monitor", metric)$code$,
    $summary$- Monitoring tracks service and model health.
- Drift and skew are ML-specific risks.
- Alerts and review processes are part of MLOps.$summary$,
    40
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
  ('35000000-0000-4000-8000-000000000001', '25000000-0000-4000-8000-000000000001', 'What is the main container for Google Cloud resources and billing?', 'A project is the main resource and billing container in Google Cloud.', 1),
  ('35000000-0000-4000-8000-000000000002', '25000000-0000-4000-8000-000000000002', 'Which identity type is commonly used by workloads and training jobs?', 'Service accounts are identities for applications and workloads.', 1),
  ('35000000-0000-4000-8000-000000000003', '25000000-0000-4000-8000-000000000003', 'What does Cloud Storage store inside buckets?', 'Cloud Storage stores objects such as files, images, training data, and artifacts.', 1),
  ('35000000-0000-4000-8000-000000000004', '25000000-0000-4000-8000-000000000004', 'Which service is best for large-scale SQL analytics?', 'BigQuery is a serverless data warehouse built for large-scale SQL analytics.', 1),
  ('35000000-0000-4000-8000-000000000005', '25000000-0000-4000-8000-000000000005', 'Which service provides managed virtual machines?', 'Compute Engine provides virtual machines.', 1),
  ('35000000-0000-4000-8000-000000000006', '25000000-0000-4000-8000-000000000006', 'Which service is best for small event-driven functions?', 'Cloud Functions runs small code units in response to events.', 1),
  ('35000000-0000-4000-8000-000000000007', '25000000-0000-4000-8000-000000000007', 'Which Google Cloud platform manages ML training, deployment, prediction, and monitoring?', 'Vertex AI is Google Cloud''s unified ML platform.', 1),
  ('35000000-0000-4000-8000-000000000008', '25000000-0000-4000-8000-000000000008', 'Which Vertex AI approach is useful for fast low-code model baselines?', 'AutoML is useful for fast low-code training.', 1),
  ('35000000-0000-4000-8000-000000000009', '25000000-0000-4000-8000-000000000009', 'Which feature tracks model versions and deployment status?', 'Model Registry tracks registered models, versions, metadata, and deployment state.', 1),
  ('35000000-0000-4000-8000-000000000010', '25000000-0000-4000-8000-000000000010', 'Which Vertex AI resource receives online prediction requests?', 'An endpoint receives online prediction requests for deployed models.', 1),
  ('35000000-0000-4000-8000-000000000011', '25000000-0000-4000-8000-000000000011', 'Which practice tracks latency, errors, drift, and skew after deployment?', 'Monitoring tracks operational and ML health after deployment.', 1)
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    question = excluded.question,
    explanation = excluded.explanation,
    sort_order = excluded.sort_order;

insert into public.quiz_options (id, quiz_id, option_text, is_correct, sort_order)
values
  ('55000000-0000-4000-8000-000000000001', '35000000-0000-4000-8000-000000000001', 'Project', true, 1),
  ('55000000-0000-4000-8000-000000000002', '35000000-0000-4000-8000-000000000001', 'Training file', false, 2),
  ('55000000-0000-4000-8000-000000000003', '35000000-0000-4000-8000-000000000001', 'Model parameter', false, 3),
  ('55000000-0000-4000-8000-000000000004', '35000000-0000-4000-8000-000000000002', 'Service account', true, 1),
  ('55000000-0000-4000-8000-000000000005', '35000000-0000-4000-8000-000000000002', 'CSV header', false, 2),
  ('55000000-0000-4000-8000-000000000006', '35000000-0000-4000-8000-000000000002', 'Local variable', false, 3),
  ('55000000-0000-4000-8000-000000000007', '35000000-0000-4000-8000-000000000003', 'Objects', true, 1),
  ('55000000-0000-4000-8000-000000000008', '35000000-0000-4000-8000-000000000003', 'Endpoints only', false, 2),
  ('55000000-0000-4000-8000-000000000009', '35000000-0000-4000-8000-000000000003', 'IAM roles only', false, 3),
  ('55000000-0000-4000-8000-000000000010', '35000000-0000-4000-8000-000000000004', 'BigQuery', true, 1),
  ('55000000-0000-4000-8000-000000000011', '35000000-0000-4000-8000-000000000004', 'Cloud Functions', false, 2),
  ('55000000-0000-4000-8000-000000000012', '35000000-0000-4000-8000-000000000004', 'IAM', false, 3),
  ('55000000-0000-4000-8000-000000000013', '35000000-0000-4000-8000-000000000005', 'Compute Engine', true, 1),
  ('55000000-0000-4000-8000-000000000014', '35000000-0000-4000-8000-000000000005', 'Model Registry', false, 2),
  ('55000000-0000-4000-8000-000000000015', '35000000-0000-4000-8000-000000000005', 'BigQuery ML', false, 3),
  ('55000000-0000-4000-8000-000000000016', '35000000-0000-4000-8000-000000000006', 'Cloud Functions', true, 1),
  ('55000000-0000-4000-8000-000000000017', '35000000-0000-4000-8000-000000000006', 'Cloud Storage bucket', false, 2),
  ('55000000-0000-4000-8000-000000000018', '35000000-0000-4000-8000-000000000006', 'IAM role', false, 3),
  ('55000000-0000-4000-8000-000000000019', '35000000-0000-4000-8000-000000000007', 'Vertex AI', true, 1),
  ('55000000-0000-4000-8000-000000000020', '35000000-0000-4000-8000-000000000007', 'Cloud DNS', false, 2),
  ('55000000-0000-4000-8000-000000000021', '35000000-0000-4000-8000-000000000007', 'Cloud Billing', false, 3),
  ('55000000-0000-4000-8000-000000000022', '35000000-0000-4000-8000-000000000008', 'AutoML', true, 1),
  ('55000000-0000-4000-8000-000000000023', '35000000-0000-4000-8000-000000000008', 'Compute Engine only', false, 2),
  ('55000000-0000-4000-8000-000000000024', '35000000-0000-4000-8000-000000000008', 'Cloud Logging', false, 3),
  ('55000000-0000-4000-8000-000000000025', '35000000-0000-4000-8000-000000000009', 'Model Registry', true, 1),
  ('55000000-0000-4000-8000-000000000026', '35000000-0000-4000-8000-000000000009', 'Cloud Shell', false, 2),
  ('55000000-0000-4000-8000-000000000027', '35000000-0000-4000-8000-000000000009', 'VPC firewall', false, 3),
  ('55000000-0000-4000-8000-000000000028', '35000000-0000-4000-8000-000000000010', 'Endpoint', true, 1),
  ('55000000-0000-4000-8000-000000000029', '35000000-0000-4000-8000-000000000010', 'Dataset', false, 2),
  ('55000000-0000-4000-8000-000000000030', '35000000-0000-4000-8000-000000000010', 'Bucket', false, 3),
  ('55000000-0000-4000-8000-000000000031', '35000000-0000-4000-8000-000000000011', 'Monitoring', true, 1),
  ('55000000-0000-4000-8000-000000000032', '35000000-0000-4000-8000-000000000011', 'Label encoding', false, 2),
  ('55000000-0000-4000-8000-000000000033', '35000000-0000-4000-8000-000000000011', 'One-hot encoding', false, 3)
on conflict (id) do update
set quiz_id = excluded.quiz_id,
    option_text = excluded.option_text,
    is_correct = excluded.is_correct,
    sort_order = excluded.sort_order;

insert into public.exam_domains (id, title, description, weight_percent, exam_points, practical_points, sort_order)
values
  (
    '80000000-0000-4000-8000-000000000001',
    'Architect low-code AI solutions',
    'Choose the right managed or low-code AI approach for a business problem.',
    null,
    array['Choose between AutoML, BigQuery ML, ML APIs, and custom training', 'Identify the data type and business goal before choosing a service'],
    array['Start with managed services when speed and simplicity matter', 'Move to custom training when model control is required'],
    1
  ),
  (
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'Design storage, preprocessing, model versioning, and traceability.',
    null,
    array['Separate Cloud Storage and BigQuery use cases', 'Use Model Registry for model version tracking'],
    array['Design for data location, permissions, lineage, and lifecycle', 'Track deployed model versions for rollback and audits'],
    2
  ),
  (
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'Deploy models, serve predictions, and monitor production health.',
    null,
    array['Choose online prediction or batch prediction', 'Understand endpoints, traffic split, drift, skew, and alerts'],
    array['Balance latency, cost, security, and reliability', 'Use monitoring to catch data and model quality changes'],
    3
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    weight_percent = excluded.weight_percent,
    exam_points = excluded.exam_points,
    practical_points = excluded.practical_points,
    sort_order = excluded.sort_order;

insert into public.service_comparisons (id, service_name, category, best_for, avoid_when, exam_point, practical_point, sort_order)
values
  ('81000000-0000-4000-8000-000000000001', 'Cloud Storage', 'Storage', 'Files, images, training data, and model artifacts', 'SQL analytics is the main goal', 'Distinguish object storage from analytics storage', 'Design bucket IAM, region, lifecycle, and naming carefully', 1),
  ('81000000-0000-4000-8000-000000000002', 'BigQuery', 'Analytics', 'Large tabular analytics, feature exploration, and BigQuery ML', 'Simple file storage is the main goal', 'Common choice for analytics, feature engineering, and BigQuery ML scenarios', 'Use partitioning and clustering to manage performance and cost', 2),
  ('81000000-0000-4000-8000-000000000003', 'Compute Engine', 'Compute', 'VM control, custom GPU setup, and special runtime environments', 'Managed ML services already satisfy the requirement', 'Recognize the trade-off between control and operations burden', 'VMs require patching, security, cost, and lifecycle management', 3),
  ('81000000-0000-4000-8000-000000000004', 'Cloud Functions', 'Serverless', 'Small event-driven automation such as file upload triggers', 'Long-running training or complex ML pipelines', 'Use for lightweight event-driven glue code', 'Keep functions small and focused on short tasks', 4),
  ('81000000-0000-4000-8000-000000000005', 'Vertex AI AutoML', 'ML Training', 'Fast low-code model baselines with labeled data', 'The team needs full algorithm or architecture control', 'Important low-code AI solution choice', 'Compare baseline quality with later custom training needs', 5),
  ('81000000-0000-4000-8000-000000000006', 'Vertex AI Model Registry', 'MLOps', 'Model version, metadata, and deployment state tracking', 'Only a quick local experiment is needed', 'Model governance and version tracking are common scenario themes', 'Use it to support approvals, rollback, and traceability', 6),
  ('81000000-0000-4000-8000-000000000007', 'Vertex AI Endpoints', 'Serving', 'Online predictions, traffic split, and autoscaling', 'Large asynchronous batch scoring is the main goal', 'Separate online prediction from batch prediction', 'Design for latency, scaling, traffic routing, and access control', 7),
  ('81000000-0000-4000-8000-000000000008', 'Vertex AI Monitoring', 'Operations', 'Drift, skew, prediction quality, and service health monitoring', 'The model has not been deployed yet', 'Monitoring after deployment is essential in PMLE scenarios', 'Define alert thresholds and review ownership before production', 8)
on conflict (id) do update
set service_name = excluded.service_name,
    category = excluded.category,
    best_for = excluded.best_for,
    avoid_when = excluded.avoid_when,
    exam_point = excluded.exam_point,
    practical_point = excluded.practical_point,
    sort_order = excluded.sort_order;

insert into public.scenario_questions (id, lesson_id, title, scenario, options, correct_option_index, explanation, exam_point, practical_point, difficulty, sort_order)
values
  (
    '82000000-0000-4000-8000-000000000001',
    '25000000-0000-4000-8000-000000000004',
    'Large tabular analytics',
    'A team has millions of customer transaction rows and needs SQL analysis plus feature exploration before model training. Which service should they consider first?',
    '["BigQuery", "Cloud Functions", "Compute Engine only"]'::jsonb,
    0,
    'BigQuery is the best first choice for large tabular SQL analysis and feature exploration.',
    'Choose the service based on data shape and access pattern.',
    'Use partitioning and query scope controls to manage cost.',
    'easy',
    1
  ),
  (
    '82000000-0000-4000-8000-000000000002',
    '25000000-0000-4000-8000-000000000008',
    'Fast baseline model',
    'A small team has labeled tabular data and wants a fast baseline classifier without writing custom model training code. Which option fits best?',
    '["Vertex AI AutoML", "Write every algorithm on a VM", "Use Cloud Storage only"]'::jsonb,
    0,
    'Vertex AI AutoML is appropriate for a fast low-code baseline.',
    'AutoML is a key low-code solution choice.',
    'After the baseline, compare quality and decide whether custom training is needed.',
    'medium',
    2
  ),
  (
    '82000000-0000-4000-8000-000000000003',
    '25000000-0000-4000-8000-000000000010',
    'Online prediction service',
    'A mobile app needs real-time prediction results from a deployed model. Which Vertex AI resource receives those requests?',
    '["Endpoint", "Dataset only", "Cloud Billing"]'::jsonb,
    0,
    'A Vertex AI endpoint receives online prediction requests for deployed models.',
    'Distinguish online prediction from batch prediction.',
    'Plan latency, autoscaling, traffic split, and access control.',
    'medium',
    3
  ),
  (
    '82000000-0000-4000-8000-000000000004',
    '25000000-0000-4000-8000-000000000011',
    'Deployed model quality change',
    'A model has been deployed for two weeks. Input data distribution appears to be changing and prediction quality may be falling. What should be used?',
    '["Model Monitoring", "Rename a bucket", "Delete all IAM roles"]'::jsonb,
    0,
    'Model monitoring helps detect drift, skew, and production quality risks.',
    'Production monitoring is an important PMLE topic.',
    'Define alert rules, review owners, and response processes.',
    'medium',
    4
  ),
  (
    '82000000-0000-4000-8000-000000000005',
    '25000000-0000-4000-8000-000000000002',
    'Least privilege',
    'A training service account only needs to read training data and start Vertex AI training jobs. Which IAM principle matters most?',
    '["Grant only the required roles", "Give Owner to everyone", "Publish credentials publicly"]'::jsonb,
    0,
    'Least privilege means granting only the permissions needed for the task.',
    'IAM questions often test member, role, resource, and least privilege.',
    'Separate service account roles and review them regularly.',
    'easy',
    5
  )
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    title = excluded.title,
    scenario = excluded.scenario,
    options = excluded.options,
    correct_option_index = excluded.correct_option_index,
    explanation = excluded.explanation,
    exam_point = excluded.exam_point,
    practical_point = excluded.practical_point,
    difficulty = excluded.difficulty,
    sort_order = excluded.sort_order;

-- ============================================================
-- docs\mvp7-mock-exams-migration.sql
-- ============================================================

-- PMLE Pathfinder MVP7 mock exam migration
-- Apply after MVP1-MVP6 migrations.

create table if not exists public.mock_exams (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  duration_minutes integer not null default 20 check (duration_minutes > 0),
  question_count integer not null default 10 check (question_count > 0),
  passing_score integer not null default 70 check (passing_score >= 0 and passing_score <= 100),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mock_exam_questions (
  id uuid primary key default gen_random_uuid(),
  mock_exam_id uuid not null references public.mock_exams(id) on delete cascade,
  exam_domain_id uuid references public.exam_domains(id) on delete set null,
  domain_title text not null default '',
  question text not null,
  scenario text not null default '',
  options jsonb not null default '[]'::jsonb,
  correct_option_index integer not null default 0 check (correct_option_index >= 0),
  explanation text not null default '',
  difficulty text not null default 'medium' check (difficulty in ('easy', 'medium', 'hard')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.mock_exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mock_exam_id uuid not null references public.mock_exams(id) on delete cascade,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  total_questions integer not null default 0 check (total_questions >= 0),
  answered_count integer not null default 0 check (answered_count >= 0),
  correct_count integer not null default 0 check (correct_count >= 0),
  score_percent numeric(5,2) not null default 0 check (score_percent >= 0 and score_percent <= 100),
  status text not null default 'completed' check (status in ('in_progress', 'completed', 'timed_out')),
  created_at timestamptz not null default now()
);

create table if not exists public.mock_exam_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.mock_exam_attempts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid references public.mock_exam_questions(id) on delete set null,
  domain_title text not null default '',
  question_snapshot text not null,
  scenario_snapshot text not null default '',
  options_snapshot jsonb not null default '[]'::jsonb,
  explanation_snapshot text not null default '',
  selected_option_index integer check (selected_option_index is null or selected_option_index >= 0),
  correct_option_index integer not null check (correct_option_index >= 0),
  is_correct boolean not null default false,
  answered_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.exam_domain_scores (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.mock_exam_attempts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  domain_title text not null,
  total_questions integer not null default 0 check (total_questions >= 0),
  answered_count integer not null default 0 check (answered_count >= 0),
  correct_count integer not null default 0 check (correct_count >= 0),
  score_percent numeric(5,2) not null default 0 check (score_percent >= 0 and score_percent <= 100),
  created_at timestamptz not null default now(),
  unique (attempt_id, domain_title)
);

create index if not exists idx_mock_exam_questions_exam on public.mock_exam_questions(mock_exam_id, sort_order);
create index if not exists idx_mock_exam_attempts_user on public.mock_exam_attempts(user_id, created_at desc);
create index if not exists idx_mock_exam_answers_attempt on public.mock_exam_answers(user_id, attempt_id);
create index if not exists idx_exam_domain_scores_attempt on public.exam_domain_scores(user_id, attempt_id);

drop trigger if exists set_mock_exams_updated_at on public.mock_exams;
create trigger set_mock_exams_updated_at before update on public.mock_exams
for each row execute function public.set_updated_at();

alter table public.mock_exams enable row level security;
alter table public.mock_exam_questions enable row level security;
alter table public.mock_exam_attempts enable row level security;
alter table public.mock_exam_answers enable row level security;
alter table public.exam_domain_scores enable row level security;

drop policy if exists "mock exams read authenticated" on public.mock_exams;
create policy "mock exams read authenticated" on public.mock_exams
for select to authenticated using (true);

drop policy if exists "mock exam questions read authenticated" on public.mock_exam_questions;
create policy "mock exam questions read authenticated" on public.mock_exam_questions
for select to authenticated using (true);

drop policy if exists "mock attempts select own" on public.mock_exam_attempts;
create policy "mock attempts select own" on public.mock_exam_attempts
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "mock attempts insert own" on public.mock_exam_attempts;
create policy "mock attempts insert own" on public.mock_exam_attempts
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "mock attempts update own" on public.mock_exam_attempts;
create policy "mock attempts update own" on public.mock_exam_attempts
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "mock answers select own" on public.mock_exam_answers;
create policy "mock answers select own" on public.mock_exam_answers
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "mock answers insert own" on public.mock_exam_answers;
create policy "mock answers insert own" on public.mock_exam_answers
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "domain scores select own" on public.exam_domain_scores;
create policy "domain scores select own" on public.exam_domain_scores
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "domain scores insert own" on public.exam_domain_scores;
create policy "domain scores insert own" on public.exam_domain_scores
for insert to authenticated with check (auth.uid() = user_id);

insert into public.mock_exams (id, title, description, duration_minutes, question_count, passing_score, is_active, sort_order)
values
  (
    '90000000-0000-4000-8000-000000000001',
    'PMLE Readiness Mini Mock Exam',
    'Timed randomized practice for GCP, Vertex AI, model serving, monitoring, and managed ML decision scenarios.',
    20,
    10,
    70,
    true,
    1
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    duration_minutes = excluded.duration_minutes,
    question_count = excluded.question_count,
    passing_score = excluded.passing_score,
    is_active = excluded.is_active,
    sort_order = excluded.sort_order;

insert into public.mock_exam_questions (
  id,
  mock_exam_id,
  exam_domain_id,
  domain_title,
  question,
  scenario,
  options,
  correct_option_index,
  explanation,
  difficulty,
  sort_order
)
values
  (
    '91000000-0000-4000-8000-000000000001',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'Architect low-code AI solutions',
    'A business team wants a fast baseline image classifier with labeled examples and minimal code. What should be considered first?',
    'The team has limited ML engineering support and needs a quick prototype before deciding whether to invest in custom training.',
    '["Vertex AI AutoML", "Compute Engine only", "Cloud Storage lifecycle rule", "Cloud DNS"]'::jsonb,
    0,
    'AutoML is a good first choice for fast low-code baselines when labeled data is available.',
    'easy',
    1
  ),
  (
    '91000000-0000-4000-8000-000000000002',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'Which service is the best fit for large tabular SQL analytics before feature engineering?',
    'A dataset contains millions of customer transaction rows. Analysts need SQL queries and feature exploration.',
    '["BigQuery", "Cloud Functions", "Vertex AI Endpoint", "Cloud Monitoring"]'::jsonb,
    0,
    'BigQuery is designed for large-scale SQL analytics and is a common feature exploration choice.',
    'easy',
    2
  ),
  (
    '91000000-0000-4000-8000-000000000003',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'A mobile app needs low-latency online predictions from a deployed model. Which Vertex AI resource should receive requests?',
    'The app sends one user event at a time and expects a prediction immediately.',
    '["Endpoint", "Dataset", "Model Registry only", "Cloud Billing"]'::jsonb,
    0,
    'Vertex AI endpoints receive online prediction requests for deployed models.',
    'easy',
    3
  ),
  (
    '91000000-0000-4000-8000-000000000004',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'A deployed model starts receiving input data with a distribution different from training data. What should help detect this?',
    'The operations team suspects production data drift after a marketing campaign changed user behavior.',
    '["Model monitoring", "Bucket rename", "IAM delete all", "Region list"]'::jsonb,
    0,
    'Model monitoring can track drift, skew, and production quality risks.',
    'medium',
    4
  ),
  (
    '91000000-0000-4000-8000-000000000005',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'What is the safest IAM principle for a training service account?',
    'The service account needs to read one training bucket and start Vertex AI training jobs.',
    '["Grant only required roles", "Grant Owner to all users", "Store keys in public code", "Disable authentication"]'::jsonb,
    0,
    'Least privilege reduces risk by granting only the permissions required for the workload.',
    'easy',
    5
  ),
  (
    '91000000-0000-4000-8000-000000000006',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'Architect low-code AI solutions',
    'When is custom training more appropriate than AutoML?',
    'A team needs a special neural network architecture and custom loss function for research-grade model behavior.',
    '["When model architecture control is required", "When no code should ever be written", "When only DNS routing is needed", "When storing static images only"]'::jsonb,
    0,
    'Custom training is appropriate when the scenario requires algorithm, architecture, or training-code control.',
    'medium',
    6
  ),
  (
    '91000000-0000-4000-8000-000000000007',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'Which Vertex AI feature helps track model versions and deployment status?',
    'The team needs to know which model version is approved, deployed, and available for rollback.',
    '["Model Registry", "Cloud DNS", "Cloud Storage uniform bucket-level access only", "Cloud Shell history"]'::jsonb,
    0,
    'Model Registry supports model version tracking, metadata, deployment state, and governance.',
    'medium',
    7
  ),
  (
    '91000000-0000-4000-8000-000000000008',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'Which deployment technique can gradually move online prediction traffic from an old model to a new model?',
    'A team wants to reduce risk while validating a new model version in production.',
    '["Traffic split on an endpoint", "Delete the old model first", "Disable logs", "Use a billing export only"]'::jsonb,
    0,
    'Traffic splitting lets an endpoint route portions of prediction traffic to different deployed model versions.',
    'medium',
    8
  ),
  (
    '91000000-0000-4000-8000-000000000009',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'Architect low-code AI solutions',
    'A company has tabular data in BigQuery and wants SQL-based model training for a quick baseline. What should be considered?',
    'The data team is comfortable with SQL but has limited Python ML experience.',
    '["BigQuery ML", "Cloud DNS", "Cloud Armor only", "Manual VM patching"]'::jsonb,
    0,
    'BigQuery ML can train models using SQL when the data is already in BigQuery.',
    'medium',
    9
  ),
  (
    '91000000-0000-4000-8000-000000000010',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'Where are training files and model artifacts often stored for Vertex AI jobs?',
    'The workflow reads CSV files and writes exported model artifacts after training.',
    '["Cloud Storage", "Cloud DNS", "Endpoint only", "IAM policy only"]'::jsonb,
    0,
    'Cloud Storage is object storage commonly used for training data and model artifacts.',
    'easy',
    10
  ),
  (
    '91000000-0000-4000-8000-000000000011',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'Which prediction pattern is better for scoring a large file of records overnight?',
    'The business does not need immediate responses. It needs all predictions ready by morning.',
    '["Batch prediction", "Online endpoint request per record only", "Disable prediction", "Use Cloud DNS"]'::jsonb,
    0,
    'Batch prediction is appropriate for asynchronous large-volume scoring when low-latency response is not required.',
    'medium',
    11
  ),
  (
    '91000000-0000-4000-8000-000000000012',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'Architect low-code AI solutions',
    'Which question should be answered before choosing an ML service?',
    'A stakeholder asks for AI but has not described the data, target, latency, or business outcome.',
    '["What business problem and data type are involved?", "Which logo color is used?", "How many DNS records exist?", "Can all permissions be public?"]'::jsonb,
    0,
    'Service choice starts with the problem, data type, target, latency, security, and operations requirements.',
    'easy',
    12
  ),
  (
    '91000000-0000-4000-8000-000000000013',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'Why is model lineage useful in production ML?',
    'An incident happens and the team must identify the model version, training data, and deployment path.',
    '["It supports traceability and rollback", "It removes the need for monitoring", "It makes all data public", "It replaces IAM"]'::jsonb,
    0,
    'Lineage helps teams trace model versions, data, decisions, and rollback paths.',
    'hard',
    13
  ),
  (
    '91000000-0000-4000-8000-000000000014',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'A production model has increasing latency and error rate. What should the team review first?',
    'Customers report slow predictions after traffic increases during a promotion.',
    '["Endpoint metrics, autoscaling, and logs", "Only the bucket name", "Only DNS comments", "Ignore monitoring until next month"]'::jsonb,
    0,
    'Operational metrics and logs help diagnose serving health, latency, errors, and scaling issues.',
    'medium',
    14
  ),
  (
    '91000000-0000-4000-8000-000000000015',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'What should be considered when choosing the region for data and training?',
    'The organization has compliance requirements and users in a specific geographic area.',
    '["Latency, compliance, cost, and data location", "Only the project name length", "Only UI color", "Whether the model name is short"]'::jsonb,
    0,
    'Region choice affects latency, compliance, cost, availability, and data residency.',
    'medium',
    15
  ),
  (
    '91000000-0000-4000-8000-000000000016',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000001',
    'Architect low-code AI solutions',
    'Which option best describes Cloud Functions in an ML workflow?',
    'A file upload should trigger a small notification and metadata update.',
    '["Small event-driven automation", "Full long-running GPU training", "Model version registry", "Online prediction endpoint"]'::jsonb,
    0,
    'Cloud Functions is useful for small event-driven tasks, not long-running model training.',
    'easy',
    16
  ),
  (
    '91000000-0000-4000-8000-000000000017',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'When might Compute Engine be chosen in an ML scenario?',
    'A team needs direct VM control, a special GPU setup, and a custom runtime environment.',
    '["When direct VM and environment control is required", "When only no-code training is allowed", "When only SQL analytics is needed", "When model drift must be monitored"]'::jsonb,
    0,
    'Compute Engine gives VM-level control but adds operational responsibility.',
    'hard',
    17
  ),
  (
    '91000000-0000-4000-8000-000000000018',
    '90000000-0000-4000-8000-000000000001',
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'Which result suggests the model should be reviewed after deployment?',
    'Monitoring shows that prediction input distribution is shifting and accuracy proxy metrics are declining.',
    '["Data drift and quality degradation", "A new bucket label only", "A shorter project name", "A disabled dashboard theme"]'::jsonb,
    0,
    'Drift and quality degradation indicate that production model behavior should be reviewed.',
    'hard',
    18
  )
on conflict (id) do update
set mock_exam_id = excluded.mock_exam_id,
    exam_domain_id = excluded.exam_domain_id,
    domain_title = excluded.domain_title,
    question = excluded.question,
    scenario = excluded.scenario,
    options = excluded.options,
    correct_option_index = excluded.correct_option_index,
    explanation = excluded.explanation,
    difficulty = excluded.difficulty,
    sort_order = excluded.sort_order;

-- ============================================================
-- docs\mvp8-career-os-migration.sql
-- ============================================================

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

-- ============================================================
-- docs\korean-localization.sql
-- ============================================================

-- PMLE Pathfinder Korean localization patch
-- Run this after docs/supabase-complete.sql if your seeded content appears in English.
-- Technical product names such as Python, NumPy, Pandas, GCP, Vertex AI, BigQuery, and Scikit-learn stay in English.

update public.modules
set title = 'Python ê¸°ì´ˆ',
    description = $ko$?„ë¡œê·¸ëž˜ë°ì´ ì²˜ìŒ???™ìŠµ?ë? ?„í•œ Python ì²??¨ê³„?…ë‹ˆ?? ë³€?? ?ë£Œ?? ì¡°ê±´ë¬? ë°˜ë³µë¬¸ì„ ?µíž™?ˆë‹¤.$ko$
where id = '10000000-0000-4000-8000-000000000001';

update public.modules
set title = 'Python ?¬í™”',
    description = $ko$?¨ìˆ˜, ë¦¬ìŠ¤?? ?•ì…”?ˆë¦¬, ?Œì¼?…ì¶œ?? ?ˆì™¸ì²˜ë¦¬ë¥?ë°°ì›Œ ?‘ì? ?„ë¡œê·¸ëž¨???¤ìŠ¤ë¡?êµ¬ì„±?©ë‹ˆ??$ko$
where id = '10000000-0000-4000-8000-000000000002';

update public.modules
set title = '?°ì´??ë¶„ì„',
    description = $ko$NumPy, Pandas, CSV, ê²°ì¸¡ì¹? ?°ì´???œê°?”ë? ?µí•´ ë¨¸ì‹ ?¬ë‹ ???°ì´???¤ë£¨ê¸?ê¸°ì´ˆë¥??µíž™?ˆë‹¤.$ko$
where id = '10000000-0000-4000-8000-000000000003';

update public.modules
set title = '?µê³„',
    description = $ko$?‰ê· , ë¶„ì‚°, ?œì??¸ì°¨, ?•ë¥ , ?ê?ê´€ê³„ë? ?¬ìš´ ?ˆì‹œë¡??µížˆê³?ML ?´ì„??ê¸°ì´ˆë¥?ë§Œë“­?ˆë‹¤.$ko$
where id = '10000000-0000-4000-8000-000000000004';

update public.modules
set description = $ko$ì§€?„í•™?? ë¹„ì??„í•™?? ?Œê?, ë¶„ë¥˜, ê³¼ì ?? ?‰ê? ì§€?? Scikit-learn??PMLE ê´€?ì—???™ìŠµ?©ë‹ˆ??$ko$
where id = '10000000-0000-4000-8000-000000000005';

update public.modules
set description = $ko$GCP ê¸°ë³¸ ?œë¹„?¤ì? Vertex AI???™ìŠµ, ë°°í¬, ëª¨ë‹ˆ?°ë§ ?ë¦„??PMLE ?œí—˜ê³??¤ë¬´ ê´€?ì—???µíž™?ˆë‹¤.$ko$
where id = '10000000-0000-4000-8000-000000000006';

update public.lessons
set title = 'ë³€??,
    objective = $ko$ê°’ì— ?´ë¦„??ë¶™ì—¬ ?¤ì‹œ ?¬ìš©?˜ëŠ” ë°©ë²•??ë°°ì›?ˆë‹¤.$ko$,
    concept = $ko$ë³€?˜ëŠ” ê°’ì— ë¶™ì´???´ë¦„?œìž…?ˆë‹¤. ?ˆë? ?¤ì–´ goal?´ë¼???´ë¦„?œì— "AI Engineer"?¼ëŠ” ê°’ì„ ë¶™ì´ë©? ?´í›„?ëŠ” goal?´ë¼ê³?ë¶€ë¥??Œë§ˆ??ê·?ê°’ì„ ?¤ì‹œ ?¬ìš©?????ˆìŠµ?ˆë‹¤. ë¹„ì „ê³µìž?ê²Œ ë³€?˜ëŠ” "ë©”ëª¨ì§€ ?´ë¦„"ì²˜ëŸ¼ ?´í•´?˜ë©´ ?½ìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- ë³€?˜ëŠ” ê°’ì„ ?´ëŠ” ?´ë¦„?…ë‹ˆ??
- = ???¤ë¥¸ìª?ê°’ì„ ?¼ìª½ ?´ë¦„???€?¥í•©?ˆë‹¤.
- ì¢‹ì? ë³€?˜ëª…?€ ì½”ë“œ???˜ë?ë¥??½ê²Œ ë³´ì—¬ì¤ë‹ˆ??$ko$
where slug = 'python-variables';

update public.lessons
set title = '?ë£Œ??,
    objective = $ko$ë¬¸ìž, ?«ìž, ì°?ê±°ì§“ì²˜ëŸ¼ ê°’ì˜ ì¢…ë¥˜ë¥?êµ¬ë¶„?©ë‹ˆ??$ko$,
    concept = $ko$?ë£Œ?•ì? Python??ê°’ì„ ?´ì„?˜ëŠ” ë°©ì‹?…ë‹ˆ?? ê¸€?ëŠ” string, ?•ìˆ˜??integer, ?Œìˆ˜??float, ì°?ê±°ì§“?€ boolean?…ë‹ˆ?? ê°™ì? 3?´ë¼???«ìž 3ê³?ê¸€??"3"?€ Python ?…ìž¥?ì„œ ?¤ë¥´ê²??¤ë£¹?ˆë‹¤.$ko$,
    summary = $ko$- str?€ ë¬¸ìž?´ìž…?ˆë‹¤.
- int?€ float???«ìž?…ë‹ˆ??
- bool?€ True ?ëŠ” False?…ë‹ˆ??
- ?ë£Œ?•ì„ ?Œë©´ ?ëŸ¬ë¥?ì¤„ì¼ ???ˆìŠµ?ˆë‹¤.$ko$
where slug = 'python-data-types';

update public.lessons
set title = 'ì¡°ê±´ë¬?,
    objective = $ko$?í™©???°ë¼ ?¤ë¥¸ ì½”ë“œë¥??¤í–‰?˜ëŠ” ë°©ë²•??ë°°ì›?ˆë‹¤.$ko$,
    concept = $ko$ì¡°ê±´ë¬¸ì? "ë§Œì•½ ~?¼ë©´"?´ë¼???ë‹¨?…ë‹ˆ?? ?ìˆ˜ê°€ 80???´ìƒ?´ë©´ ?µê³¼, ?„ë‹ˆë©?ë³µìŠµì²˜ëŸ¼ ?„ë¡œê·¸ëž¨???í™©??ë§žê²Œ ? íƒ?˜ë„ë¡?ë§Œë“­?ˆë‹¤. if, elif, else ?œì„œë¡?ì¡°ê±´???•ì¸?©ë‹ˆ??$ko$,
    summary = $ko$- if??ì²?ì¡°ê±´??ê²€?¬í•©?ˆë‹¤.
- elif??ì¶”ê? ì¡°ê±´??ê²€?¬í•©?ˆë‹¤.
- else????ì¡°ê±´??ëª¨ë‘ ?„ë‹ ???¤í–‰?©ë‹ˆ??$ko$
where slug = 'python-conditionals';

update public.lessons
set title = 'ë°˜ë³µë¬?,
    objective = $ko$ê°™ì? ?‘ì—…???¬ëŸ¬ ë²?ë°˜ë³µ?˜ëŠ” ë°©ë²•??ë°°ì›?ˆë‹¤.$ko$,
    concept = $ko$ë°˜ë³µë¬¸ì? ê°™ì? ?¼ì„ ?ë™?¼ë¡œ ?¬ëŸ¬ ë²??˜ê²Œ ??ì¤ë‹ˆ?? ë¦¬ìŠ¤???ˆì˜ ?ìˆ˜?¤ì„ ?˜ë‚˜??ì¶œë ¥?˜ê±°?? ?¬ëŸ¬ ?Œì¼??ì°¨ë??€ë¡?ì²˜ë¦¬?????¬ìš©?©ë‹ˆ?? for???•í•´ì§?ë¬¶ìŒ???œì„œ?€ë¡??????ì£¼ ?ë‹ˆ??$ko$,
    summary = $ko$- for???¬ëŸ¬ ê°’ì„ ?˜ë‚˜??êº¼ëƒ…?ˆë‹¤.
- ë°˜ë³µë¬¸ì? ì¤‘ë³µ ì½”ë“œë¥?ì¤„ìž…?ˆë‹¤.
- ?°ì´??ë¶„ì„ê³?ML ì½”ë“œ?ì„œ ë§¤ìš° ?ì£¼ ?¬ìš©?©ë‹ˆ??$ko$
where slug = 'python-loops';

update public.lessons
set title = '?¨ìˆ˜',
    objective = $ko$ë°˜ë³µ?˜ëŠ” ?‘ì—…???´ë¦„??ë¶™ì—¬ ?¬ì‚¬?©í•©?ˆë‹¤.$ko$,
    concept = $ko$?¨ìˆ˜???‘ì? ?‘ì—… ?¨ìœ„?…ë‹ˆ?? ì»¤í”¼ ë¨¸ì‹  ë²„íŠ¼ì²˜ëŸ¼ ?…ë ¥???£ìœ¼ë©??•í•´ì§??¼ì„ ?˜ê³  ê²°ê³¼ë¥??Œë ¤ì¤ë‹ˆ?? defë¡??¨ìˆ˜ë¥?ë§Œë“¤ê³?return?¼ë¡œ ê²°ê³¼ë¥??´ë³´?…ë‹ˆ??$ko$,
    summary = $ko$- def???¨ìˆ˜ë¥?ë§Œë“­?ˆë‹¤.
- ë§¤ê°œë³€?˜ëŠ” ?¨ìˆ˜???£ëŠ” ê°’ìž…?ˆë‹¤.
- return?€ ê²°ê³¼ë¥??Œë ¤ì¤ë‹ˆ??$ko$
where slug = 'python-functions';

update public.lessons
set title = 'ë¦¬ìŠ¤??,
    objective = $ko$?¬ëŸ¬ ê°’ì„ ?œì„œ?€ë¡??€?¥í•˜ê³?êº¼ë‚´??ë°©ë²•??ë°°ì›?ˆë‹¤.$ko$,
    concept = $ko$ë¦¬ìŠ¤?¸ëŠ” ?¬ëŸ¬ ê°’ì„ ??ì¤„ë¡œ ë¬¶ì–´ ???ìž?…ë‹ˆ?? ?ìˆ˜ ëª©ë¡, ?¨ì–´ ëª©ë¡, ?Œì¼ ëª©ë¡ì²˜ëŸ¼ ?œì„œê°€ ?ˆëŠ” ?°ì´?°ë? ?¤ë£° ???ë‹ˆ?? ?¸ë±?¤ëŠ” 0ë¶€???œìž‘?©ë‹ˆ??$ko$,
    summary = $ko$- ë¦¬ìŠ¤?¸ëŠ” ?¬ëŸ¬ ê°’ì„ ?€?¥í•©?ˆë‹¤.
- ?¸ë±?¤ëŠ” 0ë¶€???œìž‘?©ë‹ˆ??
- appendë¡?ê°’ì„ ì¶”ê??????ˆìŠµ?ˆë‹¤.$ko$
where slug = 'python-lists';

update public.lessons
set title = '?•ì…”?ˆë¦¬',
    objective = $ko$key-value êµ¬ì¡°ë¡??˜ë? ?ˆëŠ” ?°ì´?°ë? ?€?¥í•©?ˆë‹¤.$ko$,
    concept = $ko$?•ì…”?ˆë¦¬???´ë¦„?œì? ê°’ì„ ì§ìœ¼ë¡??€?¥í•©?ˆë‹¤. ?ˆë? ?¤ì–´ name?€ "PMLE", hours??7ì²˜ëŸ¼ ?˜ë? ?ˆëŠ” ?¼ë²¨ë¡?ê°’ì„ ì°¾ì„ ???ˆìŠµ?ˆë‹¤. JSONê³?API ?°ì´?°ë? ?´í•´????ë§¤ìš° ì¤‘ìš”?©ë‹ˆ??$ko$,
    summary = $ko$- ?•ì…”?ˆë¦¬??key?€ valueë¥??€?¥í•©?ˆë‹¤.
- keyë¡?valueë¥?ì°¾ìŠµ?ˆë‹¤.
- API?€ ?¤ì • ?°ì´?°ì—???ì£¼ ë³´ìž…?ˆë‹¤.$ko$
where slug = 'python-dictionaries';

update public.lessons
set title = '?Œì¼?…ì¶œ??,
    objective = $ko$Python?¼ë¡œ ?Œì¼???½ê³  ?°ëŠ” ê¸°ë³¸ ?ë¦„???µíž™?ˆë‹¤.$ko$,
    concept = $ko$?Œì¼?…ì¶œ?¥ì? ?„ë¡œê·¸ëž¨ ë°–ì˜ ?Œì¼ê³??°ì´?°ë? ì£¼ê³ ë°›ëŠ” ë°©ë²•?…ë‹ˆ?? ?™ìŠµ ë©”ëª¨ë¥??€?¥í•˜ê±°ë‚˜ CSVë¥??½ëŠ” ?‘ì—…??ê¸°ì´ˆ?…ë‹ˆ?? with open êµ¬ë¬¸?€ ?Œì¼???ˆì „?˜ê²Œ ?´ê³  ?«ê²Œ ??ì¤ë‹ˆ??$ko$,
    summary = $ko$- w???°ê¸° ëª¨ë“œ?…ë‹ˆ??
- r?€ ?½ê¸° ëª¨ë“œ?…ë‹ˆ??
- with???Œì¼???ˆì „?˜ê²Œ ?«ì•„ ì¤ë‹ˆ??$ko$
where slug = 'python-file-io';

update public.lessons
set title = '?ˆì™¸ì²˜ë¦¬',
    objective = $ko$?ëŸ¬ê°€ ?˜ë„ ?„ë¡œê·¸ëž¨??ë©ˆì¶”ì§€ ?Šê²Œ ì²˜ë¦¬?©ë‹ˆ??$ko$,
    concept = $ko$?ˆì™¸ì²˜ë¦¬??ë¬¸ì œê°€ ?ê¸¸ ???ˆëŠ” ì½”ë“œë¥??ˆì „?˜ê²Œ ê°ì‹¸??ë°©ë²•?…ë‹ˆ?? ?¬ìš©???…ë ¥, ?Œì¼ ?½ê¸°, API ?¸ì¶œì²˜ëŸ¼ ?¤íŒ¨?????ˆëŠ” ?‘ì—…?ì„œ ì¤‘ìš”?©ë‹ˆ?? try?ì„œ ?œë„?˜ê³  except?ì„œ ë¬¸ì œë¥?ì²˜ë¦¬?©ë‹ˆ??$ko$,
    summary = $ko$- try???„í—˜?????ˆëŠ” ì½”ë“œë¥??¤í–‰?©ë‹ˆ??
- except???ëŸ¬ê°€ ?¬ì„ ???¤í–‰?©ë‹ˆ??
- ?ˆì •?ì¸ ?„ë¡œê·¸ëž¨??ë§Œë“œ??ê¸°ì´ˆ?…ë‹ˆ??$ko$
where slug = 'python-exceptions';

update public.lessons
set title = 'NumPy',
    objective = $ko$ë°°ì—´ ê¸°ë°˜ ?«ìž ê³„ì‚°??ê¸°ë³¸??ë°°ì›?ˆë‹¤.$ko$,
    concept = $ko$NumPy???«ìž ?°ì´?°ë? ë¹ ë¥´ê²??¤ë£¨??Python ?¼ì´ë¸ŒëŸ¬ë¦¬ìž…?ˆë‹¤. ë¨¸ì‹ ?¬ë‹ ?°ì´?°ëŠ” ?œë‚˜ ë°°ì—´ ?•íƒœê°€ ë§Žê¸° ?Œë¬¸??NumPy ê°ê°???µížˆë©??´í›„ ëª¨ë¸ ?™ìŠµ ì½”ë“œë¥??´í•´?˜ê¸° ?¬ì›Œì§‘ë‹ˆ??$ko$,
    summary = $ko$- NumPy???«ìž ë°°ì—´ ê³„ì‚°??ê°•í•©?ˆë‹¤.
- ?‰ê· , ?©ê³„ ê°™ì? ê³„ì‚°??ê°„ë‹¨??ì²˜ë¦¬?©ë‹ˆ??
- ML ?°ì´?°ì˜ ê¸°ë³¸ ?•íƒœë¥??´í•´?˜ëŠ” ???„ì????©ë‹ˆ??$ko$
where slug = 'data-numpy';

update public.lessons
set title = 'Pandas',
    objective = $ko$???•íƒœ???°ì´?°ë? ?½ê³  ?”ì•½?©ë‹ˆ??$ko$,
    concept = $ko$Pandas???‘ì? ?œì²˜???‰ê³¼ ?´ì´ ?ˆëŠ” ?°ì´?°ë? ?¤ë£¨???„êµ¬?…ë‹ˆ?? DataFrame?€ ?°ì´??ë¶„ì„?ì„œ ê°€???ì£¼ ë§Œë‚˜??êµ¬ì¡°?…ë‹ˆ?? CSVë¥??½ê³ , ?´ì„ ? íƒ?˜ê³ , ?”ì•½ ?µê³„ë¥?ë³´ëŠ” ???¬ìš©?©ë‹ˆ??$ko$,
    summary = $ko$- DataFrame?€ ???•íƒœ ?°ì´?°ìž…?ˆë‹¤.
- headë¡??žë?ë¶„ì„ ?•ì¸?©ë‹ˆ??
- describeë¡??”ì•½ ?µê³„ë¥?ë³????ˆìŠµ?ˆë‹¤.$ko$
where slug = 'data-pandas';

update public.lessons
set title = 'CSV',
    objective = $ko$CSV ?Œì¼??ë¶ˆëŸ¬?€ ?°ì´??ë¶„ì„???œìž‘?©ë‹ˆ??$ko$,
    concept = $ko$CSV???¼í‘œë¡?êµ¬ë¶„???ìŠ¤???°ì´???Œì¼?…ë‹ˆ?? ?°ì´??ë¶„ì„ê³?ë¨¸ì‹ ?¬ë‹ ?ˆì œ?ì„œ ê°€???”ížˆ ?°ëŠ” ?Œì¼ ?•ì‹ ì¤??˜ë‚˜?…ë‹ˆ?? Pandas??read_csvë¡??½ê²Œ ë¶ˆëŸ¬?????ˆìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- CSV?????°ì´?°ë? ?€?¥í•˜???”í•œ ?Œì¼ ?•ì‹?…ë‹ˆ??
- read_csvë¡??Œì¼???½ìŠµ?ˆë‹¤.
- headë¡??°ì´?°ê? ???¤ì–´?”ëŠ”ì§€ ?•ì¸?©ë‹ˆ??$ko$
where slug = 'data-csv';

update public.lessons
set title = 'ê²°ì¸¡ì¹?,
    objective = $ko$ë¹„ì–´ ?ˆëŠ” ?°ì´?°ë? ì°¾ê³  ì²˜ë¦¬?©ë‹ˆ??$ko$,
    concept = $ko$ê²°ì¸¡ì¹˜ëŠ” ë¹„ì–´ ?ˆê±°???????†ëŠ” ê°’ìž…?ˆë‹¤. ë¶„ì„ ?„ì— ê²°ì¸¡ì¹˜ë? ì§€?¸ì?, ?‰ê·  ê°™ì? ê°’ìœ¼ë¡?ì±„ìš¸ì§€, ?ì¸?????•ì¸? ì? ê²°ì •?´ì•¼ ?©ë‹ˆ?? ê²°ì¸¡ì¹˜ë? ë¬´ì‹œ?˜ë©´ ëª¨ë¸ ?ˆì§ˆ???˜ë¹ ì§????ˆìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- isna??ê²°ì¸¡ì¹˜ë? ì°¾ìŠµ?ˆë‹¤.
- fillna??ê²°ì¸¡ì¹˜ë? ì±„ì›?ˆë‹¤.
- ê²°ì¸¡ì¹?ì²˜ë¦¬??ë¶„ì„ ???„ìˆ˜ ?ê??…ë‹ˆ??$ko$
where slug = 'data-missing-values';

update public.lessons
set title = '?°ì´???œê°??,
    objective = $ko$ì°¨íŠ¸ë¡??°ì´?°ì˜ ?¨í„´???•ì¸?©ë‹ˆ??$ko$,
    concept = $ko$?œê°?”ëŠ” ?«ìž ?œë§Œ ë³????“ì¹˜ê¸??¬ìš´ ?¨í„´, ì¶”ì„¸, ?´ìƒì¹˜ë? ?ˆìœ¼ë¡??•ì¸?˜ê²Œ ??ì¤ë‹ˆ?? ë¶„ì„ ê²°ê³¼ë¥??¤ë¥¸ ?¬ëžŒ?ê²Œ ?¤ëª…???Œë„ ë§¤ìš° ì¤‘ìš”?©ë‹ˆ??$ko$,
    summary = $ko$- ??ê·¸ëž˜?„ëŠ” ì¶”ì„¸ë¥?ë³´ê¸° ì¢‹ìŠµ?ˆë‹¤.
- ë§‰ë? ê·¸ëž˜?„ëŠ” ê°’ì„ ë¹„êµ?˜ê¸° ì¢‹ìŠµ?ˆë‹¤.
- ?œê°?”ëŠ” ë¶„ì„ ê²°ê³¼ ?¤ëª…???„ì????©ë‹ˆ??$ko$
where slug = 'data-visualization';

update public.lessons
set title = '?‰ê· ',
    objective = $ko$?°ì´?°ì˜ ?€?œê°’???‰ê· ??ê³„ì‚°?˜ê³  ?´ì„?©ë‹ˆ??$ko$,
    concept = $ko$?‰ê· ?€ ëª¨ë“  ê°’ì„ ?”í•œ ??ê°œìˆ˜ë¡??˜ëˆˆ ê°’ìž…?ˆë‹¤. ?°ì´?°ì˜ ì¤‘ì‹¬??ë¹ ë¥´ê²?ë³´ì—¬ ì£¼ì?ë§? ê·¹ë‹¨?ìœ¼ë¡???ê°’ì´???‘ì? ê°’ì— ?í–¥??ë°›ì„ ???ˆìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- ?‰ê· ?€ ?©ê³„ë¥?ê°œìˆ˜ë¡??˜ëˆˆ ê°’ìž…?ˆë‹¤.
- ?°ì´??ì¤‘ì‹¬??ë¹ ë¥´ê²??Œì•…?©ë‹ˆ??
- ?´ìƒì¹˜ê? ?ˆìœ¼ë©??´ì„??ì£¼ì˜?´ì•¼ ?©ë‹ˆ??$ko$
where slug = 'stats-mean';

update public.lessons
set title = 'ë¶„ì‚°',
    objective = $ko$ê°’ë“¤???‰ê· ?ì„œ ?¼ë§ˆ???¼ì ¸ ?ˆëŠ”ì§€ ?´í•´?©ë‹ˆ??$ko$,
    concept = $ko$ë¶„ì‚°?€ ê°’ë“¤???‰ê· ?ì„œ ?¼ë§ˆ???¨ì–´???ˆëŠ”ì§€ë¥??˜í??…ë‹ˆ?? ë¶„ì‚°???¬ë©´ ?°ì´?°ê? ?“ê²Œ ?¼ì ¸ ?ˆê³ , ?‘ìœ¼ë©?ê°’ë“¤???‰ê·  ì£¼ë???ëª¨ì—¬ ?ˆë‹¤???»ìž…?ˆë‹¤.$ko$,
    summary = $ko$- ë¶„ì‚°?€ ?¼ì§ ?•ë„ë¥??˜í??…ë‹ˆ??
- ê°’ì´ ?´ìˆ˜ë¡??°ì´?°ê? ???©ì–´???ˆìŠµ?ˆë‹¤.
- ?œì??¸ì°¨ë¥??´í•´?˜ëŠ” ê¸°ì´ˆ?…ë‹ˆ??$ko$
where slug = 'stats-variance';

update public.lessons
set title = '?œì??¸ì°¨',
    objective = $ko$ë¶„ì‚°?????´ì„?˜ê¸° ?¬ìš´ ?¨ìœ„ë¡??´í•´?©ë‹ˆ??$ko$,
    concept = $ko$?œì??¸ì°¨??ë¶„ì‚°???œê³±ê·¼ìž…?ˆë‹¤. ?ëž˜ ?°ì´?°ì? ë¹„ìŠ·???¨ìœ„ë¡??¼ì§ ?•ë„ë¥?ë³´ì—¬ ì£¼ê¸° ?Œë¬¸??ë¶„ì‚°ë³´ë‹¤ ì§ê??ìœ¼ë¡??´ì„?˜ê¸° ?½ìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- ?œì??¸ì°¨??ë¶„ì‚°???œê³±ê·¼ìž…?ˆë‹¤.
- ?°ì´?°ê? ?‰ê·  ì£¼ë????¼ë§ˆ???¼ì¡Œ?”ì? ë³´ì—¬ ì¤ë‹ˆ??
- ?‘ì„?˜ë¡ ê°’ë“¤???‰ê· ??ê°€ê¹ìŠµ?ˆë‹¤.$ko$
where slug = 'stats-standard-deviation';

update public.lessons
set title = '?•ë¥ ',
    objective = $ko$?´ë–¤ ?¼ì´ ?¼ì–´??ê°€?¥ì„±???«ìžë¡??œí˜„?©ë‹ˆ??$ko$,
    concept = $ko$?•ë¥ ?€ ?´ë–¤ ?¬ê±´???¼ì–´??ê°€?¥ì„±??0ê³?1 ?¬ì´ ?«ìžë¡??œí˜„?©ë‹ˆ?? ë¶„ë¥˜ ëª¨ë¸?€ ì¢…ì¢… "???´ë©”?¼ì´ ?¤íŒ¸???•ë¥ "ì²˜ëŸ¼ ?•ë¥  ?•íƒœ??ì¶œë ¥???…ë‹ˆ??$ko$,
    summary = $ko$- ?•ë¥ ?€ 0?ì„œ 1 ?¬ì´ ê°’ìž…?ˆë‹¤.
- 1??ê°€ê¹Œìš¸?˜ë¡ ?¼ì–´??ê°€?¥ì„±???½ë‹ˆ??
- ë¶„ë¥˜ ëª¨ë¸ ?´ì„??ì¤‘ìš”?©ë‹ˆ??$ko$
where slug = 'stats-probability';

update public.lessons
set title = '?ê?ê´€ê³?,
    objective = $ko$??ë³€?˜ê? ?¨ê»˜ ?€ì§ì´???•ë„ë¥??´í•´?©ë‹ˆ??$ko$,
    concept = $ko$?ê?ê´€ê³„ëŠ” ??ë³€?˜ê? ?¨ê»˜ ì¦ê??˜ê±°??ê°ì†Œ?˜ëŠ” ê²½í–¥???˜í??…ë‹ˆ?? ?‘ì˜ ?ê?ê´€ê³„ëŠ” ?¨ê»˜ ì¦ê??˜ëŠ” ê²½í–¥, ?Œì˜ ?ê?ê´€ê³„ëŠ” ?œìª½??ì¦ê??????¤ë¥¸ ìª½ì´ ê°ì†Œ?˜ëŠ” ê²½í–¥?…ë‹ˆ?? ?? ?ê?ê´€ê³„ëŠ” ?¸ê³¼ê´€ê³„ê? ?„ë‹™?ˆë‹¤.$ko$,
    summary = $ko$- ?ê?ê´€ê³„ëŠ” ?¨ê»˜ ?€ì§ì´???•ë„?…ë‹ˆ??
- ?‘ìˆ˜??ê°™ì? ë°©í–¥, ?Œìˆ˜??ë°˜ë? ë°©í–¥?…ë‹ˆ??
- ?ê?ê´€ê³„ë§Œ?¼ë¡œ ?ì¸???¨ì •?˜ë©´ ???©ë‹ˆ??$ko$
where slug = 'stats-correlation';

update public.lessons
set title = 'ì§€?„í•™??,
    objective = $ko$?•ë‹µ ?¼ë²¨???ˆëŠ” ?°ì´?°ë¡œ ëª¨ë¸???™ìŠµ?˜ëŠ” ë°©ì‹???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$ì§€?„í•™?µì? ?…ë ¥ê³??•ë‹µ???¨ê»˜ ë³´ì—¬ ì£¼ë©° ëª¨ë¸???ˆë ¨?˜ëŠ” ë°©ì‹?…ë‹ˆ?? ?ˆë? ?¤ì–´ ì§‘ì˜ ?¬ê¸°?€ ê°€ê²? ?´ë©”???´ìš©ê³??¤íŒ¸ ?¬ë?ì²˜ëŸ¼ ?•ë‹µ???ˆëŠ” ?ˆì œë¡??™ìŠµ?©ë‹ˆ?? ?Œê??€ ë¶„ë¥˜ê°€ ?€?œì ??ì§€?„í•™?µìž…?ˆë‹¤.$ko$,
    summary = $ko$- ì§€?„í•™?µì? ?•ë‹µ ?¼ë²¨???ˆìŠµ?ˆë‹¤.
- ?Œê????«ìžë¥??ˆì¸¡?©ë‹ˆ??
- ë¶„ë¥˜??ë²”ì£¼ë¥??ˆì¸¡?©ë‹ˆ??$ko$
where slug = 'ml-supervised-learning';

update public.lessons
set title = 'ë¹„ì??„í•™??,
    objective = $ko$?•ë‹µ ?¼ë²¨ ?†ì´ ?°ì´?°ì˜ êµ¬ì¡°ë¥?ì°¾ëŠ” ë°©ì‹???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$ë¹„ì??„í•™?µì? ?•ë‹µ ?†ì´ ?°ì´???ˆì˜ ?¨í„´?´ë‚˜ ê·¸ë£¹??ì°¾ìŠµ?ˆë‹¤. ê³ ê°??ë¹„ìŠ·???‰ë™ë³„ë¡œ ë¬¶ê±°?? ?°ì´?°ì˜ ?¨ì? êµ¬ì¡°ë¥??ìƒ‰?????¬ìš©?©ë‹ˆ??$ko$,
    summary = $ko$- ë¹„ì??„í•™?µì? ?•ë‹µ ?¼ë²¨???†ìŠµ?ˆë‹¤.
- êµ°ì§‘?”ëŠ” ë¹„ìŠ·???°ì´?°ë? ë¬¶ìŠµ?ˆë‹¤.
- ?ìƒ‰??ë¶„ì„???ì£¼ ?¬ìš©?©ë‹ˆ??$ko$
where slug = 'ml-unsupervised-learning';

update public.lessons
set title = '?Œê?',
    objective = $ko$?°ì†?ì¸ ?«ìž ê°’ì„ ?ˆì¸¡?˜ëŠ” ë¬¸ì œë¥??´í•´?©ë‹ˆ??$ko$,
    concept = $ko$?Œê???ê°€ê²? ë§¤ì¶œ, ?¨ë„ì²˜ëŸ¼ ?«ìžë¥??ˆì¸¡?˜ëŠ” ë¬¸ì œ?…ë‹ˆ?? ?µì´ ?°ì†?ì¸ ?«ìž?¼ë©´ ?Œê?ë¥?ë¨¼ì? ? ì˜¬ë¦¬ë©´ ?©ë‹ˆ?? ? í˜•?Œê???ê°€??ê¸°ë³¸?ì¸ ?Œê? ëª¨ë¸?…ë‹ˆ??$ko$,
    summary = $ko$- ?Œê????«ìžë¥??ˆì¸¡?©ë‹ˆ??
- MAE, RMSE ê°™ì? ?¤ì°¨ ì§€?œë? ?¬ìš©?©ë‹ˆ??
- ? í˜•?Œê????€?œì ??ì²?ëª¨ë¸?…ë‹ˆ??$ko$
where slug = 'ml-regression';

update public.lessons
set title = 'ë¶„ë¥˜',
    objective = $ko$?•í•´ì§?ë²”ì£¼???¼ë²¨???ˆì¸¡?˜ëŠ” ë¬¸ì œë¥??´í•´?©ë‹ˆ??$ko$,
    concept = $ko$ë¶„ë¥˜???¤íŒ¸/?•ìƒ, ?©ê²©/ë¶ˆí•©ê²? ê³ ì–‘??ê°•ì•„ì§€ì²˜ëŸ¼ ë²”ì£¼ë¥??ˆì¸¡?˜ëŠ” ë¬¸ì œ?…ë‹ˆ?? ?µì´ ?´ë¦„?œë¼ë©?ë¶„ë¥˜ ë¬¸ì œë¡?ë³????ˆìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- ë¶„ë¥˜??ë²”ì£¼ë¥??ˆì¸¡?©ë‹ˆ??
- ?•í™•?? ?•ë??? ?¬í˜„?? F1???ì£¼ ë´…ë‹ˆ??
- ?•ë¥  ì¶œë ¥???¨ê»˜ ?´ì„?????ˆìŠµ?ˆë‹¤.$ko$
where slug = 'ml-classification';

update public.lessons
set title = 'ê³¼ì ??,
    objective = $ko$?™ìŠµ ?°ì´?°ë§Œ ?ˆë¬´ ??ë§žì¶”???„í—˜???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$ê³¼ì ?©ì? ëª¨ë¸???™ìŠµ ?°ì´?°ì˜ ?¸ë??¬í•­ê¹Œì? ?¸ì›Œ???ˆë¡œ???°ì´?°ì—???½í•´ì§€???íƒœ?…ë‹ˆ?? ?œí—˜ ë¬¸ì œë¥??´í•´?˜ì? ?Šê³  ?µì•ˆì§€ë§??¸ìš´ ê²ƒê³¼ ë¹„ìŠ·?©ë‹ˆ?? ê²€ì¦??°ì´?°ë¡œ ê³¼ì ?©ì„ ?•ì¸?©ë‹ˆ??$ko$,
    summary = $ko$- ê³¼ì ?©ì? ?™ìŠµ ?°ì´?°ì—ë§?ì§€?˜ì¹˜ê²???ë§žëŠ” ?íƒœ?…ë‹ˆ??
- ê²€ì¦??ŒìŠ¤???±ëŠ¥????œ¼ë©??˜ì‹¬?©ë‹ˆ??
- ëª¨ë¸ ?¨ìˆœ?? ?°ì´??ì¶”ê?, ?•ê·œ?”ê? ?„ì????©ë‹ˆ??$ko$
where slug = 'ml-overfitting';

update public.lessons
set title = '?‰ê? ì§€??,
    objective = $ko$ëª¨ë¸ ?±ëŠ¥??ë¬¸ì œ ? í˜•??ë§žê²Œ ì¸¡ì •?©ë‹ˆ??$ko$,
    concept = $ko$?‰ê? ì§€?œëŠ” ëª¨ë¸???¼ë§ˆ?????‘ë™?˜ëŠ”ì§€ ë³´ì—¬ ì£¼ëŠ” ?ìˆ˜?ìž…?ˆë‹¤. ?Œê????¤ì°¨ë¥?ë³´ê³ , ë¶„ë¥˜???•í™•?? ?•ë??? ?¬í˜„?? F1 ?±ì„ ë´…ë‹ˆ?? ë¬¸ì œ ëª©ì ??ë§žëŠ” ì§€??? íƒ??ì¤‘ìš”?©ë‹ˆ??$ko$,
    summary = $ko$- ?Œê??€ ë¶„ë¥˜??ì§€?œê? ?¤ë¦…?ˆë‹¤.
- ?•í™•?„ë§Œ?¼ë¡œ ì¶©ë¶„?˜ì? ?Šì„ ?Œê? ë§ŽìŠµ?ˆë‹¤.
- PMLE?ì„œ??ì§€??? íƒ ?´ìœ ê°€ ì¤‘ìš”?©ë‹ˆ??$ko$
where slug = 'ml-metrics';

update public.lessons
set title = 'Scikit-learn',
    objective = $ko$ê¸°ë³¸ ML ì½”ë“œ ?ë¦„??fitê³?predictë¥??µíž™?ˆë‹¤.$ko$,
    concept = $ko$Scikit-learn?€ Python???€?œì ??ë¨¸ì‹ ?¬ë‹ ?¼ì´ë¸ŒëŸ¬ë¦¬ìž…?ˆë‹¤. ë³´í†µ ?°ì´?°ë? ì¤€ë¹„í•˜ê³? ëª¨ë¸??ë§Œë“¤ê³? fit?¼ë¡œ ?™ìŠµ?˜ê³ , predictë¡??ˆì¸¡?©ë‹ˆ?? ???ë¦„?€ ?´í›„ Vertex AI ?™ìŠµ ê°œë…ê³¼ë„ ?°ê²°?©ë‹ˆ??$ko$,
    summary = $ko$- fit?€ ëª¨ë¸???™ìŠµ?©ë‹ˆ??
- predict???ˆì¸¡?©ë‹ˆ??
- train/test split?¼ë¡œ ?±ëŠ¥???•ì¸?©ë‹ˆ??$ko$
where slug = 'ml-scikit-learn';

update public.lessons
set title = 'Cloud Fundamentals',
    objective = $ko$GCP ?„ë¡œ?íŠ¸, ë¦¬ì „, ì¡? API, ë¹„ìš©??ê¸°ë³¸ êµ¬ì¡°ë¥??´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Google Cloud???„ë¡œ?íŠ¸ë¥?ì¤‘ì‹¬?¼ë¡œ ë¦¬ì†Œ?¤ë? ê´€ë¦¬í•©?ˆë‹¤. ?„ë¡œ?íŠ¸??IAM, API, ê³¼ê¸ˆ, ë¦¬ì†Œ?¤ë? ë¬¶ëŠ” ???´ë”?…ë‹ˆ?? ë¦¬ì „ê³?ì¡´ì? ë¦¬ì†Œ?¤ê? ?¤í–‰?˜ëŠ” ?„ì¹˜ë¥??•í•˜ë©?ì§€?°ì‹œê°? ê°€?©ì„±, ê·œì •, ë¹„ìš©???í–¥??ì¤ë‹ˆ??$ko$,
    summary = $ko$- ?„ë¡œ?íŠ¸??GCP ë¦¬ì†Œ?¤ì˜ ê¸°ë³¸ ?¨ìœ„?…ë‹ˆ??
- ë¦¬ì „ê³?ì¡´ì? ?„ì¹˜?€ ê°€?©ì„±???í–¥??ì¤ë‹ˆ??
- PMLE ë¬¸ì œ?ì„œ??ë¹„ìš©, ë³´ì•ˆ, ?´ì˜ ì¡°ê±´???¨ê»˜ ë´…ë‹ˆ??$ko$
where slug = 'gcp-cloud-fundamentals';

update public.lessons
set title = 'IAM',
    objective = $ko$?„ê? ?´ë–¤ ë¦¬ì†Œ?¤ì— ?´ë–¤ ê¶Œí•œ??ê°–ëŠ”ì§€ ?´í•´?©ë‹ˆ??$ko$,
    concept = $ko$IAM?€ member, role, resource??ê´€ê³„ìž…?ˆë‹¤. member???¬ìš©?ë‚˜ ?œë¹„??ê³„ì •, role?€ ê¶Œí•œ ë¬¶ìŒ, resource???‘ê·¼ ?€?ìž…?ˆë‹¤. PMLE?ì„œ??ìµœì†Œ ê¶Œí•œ ?ì¹™???ì£¼ ?±ìž¥?©ë‹ˆ??$ko$,
    summary = $ko$- IAM?€ member, role, resourceë¡??´í•´?©ë‹ˆ??
- ?œë¹„??ê³„ì •?€ ?„ë¡œê·¸ëž¨???¬ìš©?˜ëŠ” ? ë¶„?…ë‹ˆ??
- ?„ìš”??ê¶Œí•œë§?ì£¼ëŠ” ìµœì†Œ ê¶Œí•œ??ì¤‘ìš”?©ë‹ˆ??$ko$
where slug = 'gcp-iam';

update public.lessons
set title = 'Storage',
    objective = $ko$Cloud Storageë¥??°ì´?°ì? ëª¨ë¸ ?°ì¶œë¬??€?¥ì†Œë¡??´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Cloud Storage???Œì¼??bucket ?ˆì— objectë¡??€?¥í•©?ˆë‹¤. CSV, ?´ë?ì§€, ?™ìŠµ ?°ì´?? ëª¨ë¸ artifact ê°™ì? ?Œì¼ ?€?¥ì— ?í•©?©ë‹ˆ?? Vertex AI ?™ìŠµ ?‘ì—…?€ ?…ë ¥ ?°ì´?°ë? Cloud Storage?ì„œ ?½ê³  ê²°ê³¼ artifactë¥??¤ì‹œ ?€?¥í•˜??ê²½ìš°ê°€ ë§ŽìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- Cloud Storage??ê°ì²´ ?€?¥ì†Œ?…ë‹ˆ??
- ?™ìŠµ ?°ì´?°ì? ëª¨ë¸ artifact ?€?¥ì— ?ì£¼ ?ë‹ˆ??
- ?„ì¹˜, ê¶Œí•œ, lifecycle ?¤ì •???¨ê»˜ ê³ ë ¤?©ë‹ˆ??$ko$
where slug = 'gcp-storage';

update public.lessons
set title = 'BigQuery',
    objective = $ko$?€ê·œëª¨ ???°ì´??ë¶„ì„ê³?BigQuery ML ?¬ìš© ?í™©???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$BigQuery???œë²„ë¦¬ìŠ¤ ?°ì´???¨ì–´?˜ìš°?¤ìž…?ˆë‹¤. SQLë¡??????°ì´?°ë? ë¹ ë¥´ê²?ë¶„ì„?˜ê³ , ?¼ì²˜ ?ìƒ‰?´ë‚˜ BigQuery ML ëª¨ë¸ ?™ìŠµ?ë„ ?¬ìš©?????ˆìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- BigQuery???€ê·œëª¨ SQL ë¶„ì„???í•©?©ë‹ˆ??
- BigQuery ML?€ SQL ê¸°ë°˜ ëª¨ë¸ ?™ìŠµ??ì§€?í•©?ˆë‹¤.
- ?Œí‹°?”ë‹ê³??´ëŸ¬?¤í„°ë§ì? ë¹„ìš©ê³??±ëŠ¥??ì¤‘ìš”?©ë‹ˆ??$ko$
where slug = 'gcp-bigquery';

update public.lessons
set title = 'Compute Engine',
    objective = $ko$ì§ì ‘ ?œì–´ê°€ ?„ìš”??VM ?¬ìš© ?í™©???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Compute Engine?€ ê°€??ë¨¸ì‹ ?…ë‹ˆ?? ?´ì˜ì²´ì œ, ?¼ì´ë¸ŒëŸ¬ë¦? ?¤í–‰ ?˜ê²½??ì§ì ‘ ?µì œ?´ì•¼ ????? ìš©?˜ì?ë§?ê´€ë¦?ì±…ìž„??ì»¤ì§‘?ˆë‹¤. PMLE?ì„œ??managed service?€ VM ì¤?ë¬´ì—‡?????ì ˆ?œì? ë¬»ëŠ” ë¬¸ì œê°€ ?ì£¼ ?˜ì˜µ?ˆë‹¤.$ko$,
    summary = $ko$- Compute Engine?€ VM?…ë‹ˆ??
- ?µì œ?¥ì? ?’ì?ë§??´ì˜ ë¶€?´ë„ ?½ë‹ˆ??
- ê´€ë¦¬í˜• ?œë¹„?¤ê? ê°€?¥í•œì§€ ë¨¼ì? ê²€? í•©?ˆë‹¤.$ko$
where slug = 'gcp-compute-engine';

update public.lessons
set title = 'Cloud Functions',
    objective = $ko$?‘ì? ?´ë²¤??ê¸°ë°˜ ?ë™?”ì— serverless ?¨ìˆ˜ë¥??¬ìš©?˜ëŠ” ?í™©???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Cloud Functions???Œì¼ ?…ë¡œ?? ë©”ì‹œì§€, HTTP ?”ì²­ ê°™ì? ?´ë²¤?¸ì— ë°˜ì‘???‘ì? ì½”ë“œë¥??¤í–‰?©ë‹ˆ?? ê¸??™ìŠµ ?‘ì—…ë³´ë‹¤???Œë¦¼, ë©”í??°ì´???…ë°?´íŠ¸, ê°„ë‹¨??glue logic???í•©?©ë‹ˆ??$ko$,
    summary = $ko$- Cloud Functions???‘ì? ?´ë²¤??ê¸°ë°˜ ì½”ë“œ???í•©?©ë‹ˆ??
- ê¸??™ìŠµ ?‘ì—…?ëŠ” ë§žì? ?ŠìŠµ?ˆë‹¤.
- ?¸ë¦¬ê±°ì? ê¶Œí•œ ?¤ì •???¨ê»˜ ë´ì•¼ ?©ë‹ˆ??$ko$
where slug = 'gcp-cloud-functions';

update public.lessons
set title = 'Vertex AI',
    objective = $ko$Google Cloud??ê´€ë¦¬í˜• ML ?Œëž«????• ???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Vertex AI???°ì´?°ì…‹, ?™ìŠµ, ?¤í—˜, ëª¨ë¸ ?±ë¡, ë°°í¬, ?ˆì¸¡, ëª¨ë‹ˆ?°ë§???°ê²°?˜ëŠ” ?µí•© ML ?Œëž«?¼ìž…?ˆë‹¤. PMLE?ì„œ???¸ì œ Vertex AIë¥?? íƒ?´ì•¼ ?˜ëŠ”ì§€?€ ?´ì˜ ?ë¦„???´í•´?˜ëŠ” ê²ƒì´ ì¤‘ìš”?©ë‹ˆ??$ko$,
    summary = $ko$- Vertex AI??ML ?Œí¬?Œë¡œë¥?ê´€ë¦¬í•©?ˆë‹¤.
- ?™ìŠµë¶€??ë°°í¬, ëª¨ë‹ˆ?°ë§ê¹Œì? ?°ê²°?©ë‹ˆ??
- PMLE???µì‹¬ ?œë¹„?¤ìž…?ˆë‹¤.$ko$
where slug = 'gcp-vertex-ai';

update public.lessons
set title = 'AutoML',
    objective = $ko$ë¹ ë¥¸ low-code baseline ëª¨ë¸??ë§Œë“œ???í™©???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$AutoML?€ ì§ì ‘ ?Œê³ ë¦¬ì¦˜???¸ì„¸?˜ê²Œ êµ¬í˜„?˜ì? ?Šê³ ???¼ë²¨???ˆëŠ” ?°ì´?°ë¡œ ë¹ ë¥´ê²?ëª¨ë¸ baseline??ë§Œë“¤ ???ˆëŠ” ë°©ì‹?…ë‹ˆ?? ë¹ ë¥¸ ê²€ì¦ì—??ì¢‹ì?ë§? ?¹ìˆ˜??êµ¬ì¡°??custom lossê°€ ?„ìš”?˜ë©´ custom training?????í•©?©ë‹ˆ??$ko$,
    summary = $ko$- AutoML?€ ë¹ ë¥¸ baseline??ì¢‹ìŠµ?ˆë‹¤.
- ?¼ë²¨???ˆëŠ” ?°ì´?°ê? ?„ìš”?©ë‹ˆ??
- ?„ì „???œì–´ê°€ ?„ìš”?˜ë©´ custom training??ê³ ë ¤?©ë‹ˆ??$ko$
where slug = 'gcp-automl';

update public.lessons
set title = 'Model Registry',
    objective = $ko$ëª¨ë¸ ë²„ì „ê³?ë°°í¬ ?íƒœë¥?ì¶”ì ?˜ëŠ” ë°©ë²•???´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Model Registry??ëª¨ë¸ ë²„ì „, ë©”í??°ì´?? ë°°í¬ ?íƒœë¥?ê´€ë¦¬í•©?ˆë‹¤. ?¹ì¸, ë¡¤ë°±, ì¶”ì ??ê°™ì? MLOps ?”êµ¬?¬í•­?ì„œ ì¤‘ìš”?©ë‹ˆ??$ko$,
    summary = $ko$- Model Registry??ëª¨ë¸ ë²„ì „??ì¶”ì ?©ë‹ˆ??
- ë°°í¬ ?íƒœ?€ ë©”í??°ì´??ê´€ë¦¬ì— ?„ì??©ë‹ˆ??
- ?´ì˜ê³?ê°ì‚¬ ?”êµ¬?¬í•­??ì¤‘ìš”?©ë‹ˆ??$ko$
where slug = 'gcp-model-registry';

update public.lessons
set title = 'Endpoints',
    objective = $ko$ë°°í¬??ëª¨ë¸???¨ë¼???ˆì¸¡ ì§„ìž…?ì„ ?´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Vertex AI Endpoint???±ì´ ?¤ì‹œê°??ˆì¸¡ ?”ì²­??ë³´ë‚´???¨ë¼??ì§„ìž…?ìž…?ˆë‹¤. ??? ì§€?°ì‹œê°? traffic split, autoscaling, ?‘ê·¼ ?œì–´ë¥??¨ê»˜ ê³ ë ¤?´ì•¼ ?©ë‹ˆ??$ko$,
    summary = $ko$- Endpoint???¨ë¼???ˆì¸¡ ?”ì²­??ë°›ìŠµ?ˆë‹¤.
- ?¤ì‹œê°??ˆì¸¡?ëŠ” Endpointë¥??¬ìš©?©ë‹ˆ??
- batch predictionê³?êµ¬ë¶„?´ì•¼ ?©ë‹ˆ??$ko$
where slug = 'gcp-endpoints';

update public.lessons
set title = 'Monitoring',
    objective = $ko$ë°°í¬ ??ëª¨ë¸ê³??œë¹„???íƒœë¥?ê°ì‹œ?˜ëŠ” ?´ìœ ë¥??´í•´?©ë‹ˆ??$ko$,
    concept = $ko$Monitoring?€ ëª¨ë¸??ë°°í¬?????…ë ¥ ?°ì´??ë³€?? ?ˆì¸¡ ?ˆì§ˆ, ì§€?°ì‹œê°? ?¤ë¥˜, ?•ìž¥ ?íƒœë¥??•ì¸?˜ëŠ” ?´ì˜ ?œë™?…ë‹ˆ?? ?™ìŠµ ??ì¢‹ì•˜??ëª¨ë¸???¤ì œ ?°ì´?°ê? ë°”ë€Œë©´ ?±ëŠ¥???¨ì–´ì§????ˆìŠµ?ˆë‹¤.$ko$,
    summary = $ko$- ëª¨ë‹ˆ?°ë§?€ ë°°í¬ ???„ìˆ˜?…ë‹ˆ??
- drift, skew, latency, errorë¥??•ì¸?©ë‹ˆ??
- ?Œë¦¼ ê¸°ì?ê³??´ë‹¹?ë? ë¯¸ë¦¬ ?•í•´???©ë‹ˆ??$ko$
where slug = 'gcp-monitoring';

update public.coding_tasks
set title = 'ëª©í‘œ ë³€??ì¶œë ¥?˜ê¸°',
    description = $ko$ë¬¸ìž??ë³€?˜ë? ë§Œë“¤ê³?printë¡?ì¶œë ¥?©ë‹ˆ??$ko$,
    instructions = $ko$goal?´ë¼??ë³€?˜ì— AI Engineerë¥??€?¥í•˜ê³?printë¡?ì¶œë ¥?˜ì„¸?? ?ˆìƒ ì¶œë ¥?ëŠ” ?”ë©´??ë³´ì¼ ê°’ë§Œ ?ìŠµ?ˆë‹¤.$ko$
where id = '60000000-0000-4000-8000-000000000001';

update public.coding_tasks
set title = '?¨ìˆ˜ë¡??????”í•˜ê¸?,
    description = $ko$?¨ìˆ˜ë¥??•ì˜?˜ê³  return?¼ë¡œ ê²°ê³¼ë¥??Œë ¤ì£¼ëŠ” ?°ìŠµ?…ë‹ˆ??$ko$,
    instructions = $ko$add ?¨ìˆ˜ë¥??•ì˜????add(3, 5)??ê²°ê³¼ë¥?printë¡?ì¶œë ¥?˜ì„¸??$ko$
where id = '60000000-0000-4000-8000-000000000002';

update public.coding_tasks
set title = 'ë¦¬ìŠ¤???‰ê·  ê³„ì‚°?˜ê¸°',
    description = $ko$sumê³?len???¬ìš©???‰ê· ??ê³„ì‚°?©ë‹ˆ??$ko$,
    instructions = $ko$scores = [70, 80, 90]??ë§Œë“¤ê³??‰ê· ??ê³„ì‚°????ì¶œë ¥?˜ì„¸??$ko$
where id = '60000000-0000-4000-8000-000000000003';

update public.coding_tasks
set title = '?Œê? ?…ë ¥ê³??¼ë²¨ ë§Œë“¤ê¸?,
    description = $ko$ì§€?„í•™???Œê? ë¬¸ì œ?ì„œ X?€ yë¥?êµ¬ì„±?˜ëŠ” ?°ìŠµ?…ë‹ˆ??$ko$,
    instructions = $ko$Xë¥?[[1], [2], [3]]?¼ë¡œ, yë¥?[60, 75, 90]?¼ë¡œ ë§Œë“¤ê³?labels: ?€ yë¥??¨ê»˜ ì¶œë ¥?˜ì„¸??$ko$
where id = '61000000-0000-4000-8000-000000000001';

update public.coding_tasks
set title = 'fitê³?predict ?ë¦„ ?°ê¸°',
    description = $ko$?¤ì œ ?¤í–‰ ?†ì´ Scikit-learn??ê¸°ë³¸ ?©ì–´ë¥??°ìŠµ?©ë‹ˆ??$ko$,
    instructions = $ko$fitê³?predictê°€ ?¤ì–´ê°?ê°„ë‹¨???ë¦„ ë¬¸ìž?´ì„ ë§Œë“¤ê³?workflowë¥?ì¶œë ¥?˜ì„¸??$ko$
where id = '61000000-0000-4000-8000-000000000002';

update public.ml_concept_map
set source_concept = 'ì§€?„í•™??,
    target_concept = '?Œê?',
    relation = '?¬í•¨',
    description = $ko$?Œê????«ìž ?ˆì¸¡???„í•œ ?€?œì ??ì§€?„í•™??ë¬¸ì œ?…ë‹ˆ??$ko$
where id = '70000000-0000-4000-8000-000000000001';

update public.ml_concept_map
set source_concept = 'ì§€?„í•™??,
    target_concept = 'ë¶„ë¥˜',
    relation = '?¬í•¨',
    description = $ko$ë¶„ë¥˜??ë²”ì£¼ ?ˆì¸¡???„í•œ ?€?œì ??ì§€?„í•™??ë¬¸ì œ?…ë‹ˆ??$ko$
where id = '70000000-0000-4000-8000-000000000002';

update public.ml_concept_map
set source_concept = 'ê³¼ì ??,
    target_concept = '?‰ê? ì§€??,
    relation = '?ì?',
    description = $ko$ê²€ì¦??ëŠ” ?ŒìŠ¤???°ì´?°ì˜ ?‰ê? ì§€?œëŠ” ê³¼ì ?©ì„ ë°œê²¬?˜ëŠ” ???„ì???ì¤ë‹ˆ??$ko$
where id = '70000000-0000-4000-8000-000000000003';

update public.mock_exams
set title = 'PMLE ì¤€ë¹„ë„ ë¯¸ë‹ˆ ëª¨ì˜ê³ ì‚¬',
    description = $ko$GCP, Vertex AI, ëª¨ë¸ ?œë¹™, ëª¨ë‹ˆ?°ë§, ê´€ë¦¬í˜• ML ? íƒ ?œë‚˜ë¦¬ì˜¤ë¥??œí•œ ?œê°„ ?ˆì— ?°ìŠµ?©ë‹ˆ??$ko$
where id = '90000000-0000-4000-8000-000000000001';

update public.exam_domains
set description = $ko$ë¹„ì¦ˆ?ˆìŠ¤ ëª©í‘œ, ?°ì´???•íƒœ, ê´€ë¦¬í˜• ?œë¹„??? íƒ ê¸°ì????°ê²°???ë‹¨?©ë‹ˆ??$ko$,
    exam_points = array['AutoML, BigQuery ML, ML API, custom training ì¤??ì ˆ??? íƒì§€ë¥?ê³ ë¦…?ˆë‹¤', '?°ì´???•íƒœ?€ ë¹„ì¦ˆ?ˆìŠ¤ ëª©í‘œë¥?ë¨¼ì? ?•ì¸?©ë‹ˆ??],
    practical_points = array['ë¹ ë¥¸ baseline???„ìš”?œì?, ?„ì „???œì–´ê°€ ?„ìš”?œì? êµ¬ë¶„?©ë‹ˆ??, '?œë¹„??? íƒ ?´ìœ ë¥??¤ëª…?????ˆì–´???©ë‹ˆ??]
where id = '80000000-0000-4000-8000-000000000001';

update public.exam_domains
set description = $ko$?°ì´???€?? ?¼ì²˜ ?ìƒ‰, ëª¨ë¸ ë²„ì „ ê´€ë¦? ë°°í¬ ì¤€ë¹??ë¦„???´í•´?©ë‹ˆ??$ko$,
    exam_points = array['Cloud Storage?€ BigQuery ?¬ìš© ?í™©??êµ¬ë¶„?©ë‹ˆ??, 'Model Registryê°€ ëª¨ë¸ ë²„ì „ ì¶”ì ???°ìž„???´í•´?©ë‹ˆ??],
    practical_points = array['?°ì´???„ì¹˜, ê¶Œí•œ, ë¹„ìš©, ?±ëŠ¥???¨ê»˜ ?¤ê³„?©ë‹ˆ??, 'ëª¨ë¸ ?¹ì¸, ë¡¤ë°±, ì¶”ì ?±ì„ ?´ì˜ ê´€?ì—??ë´…ë‹ˆ??]
where id = '80000000-0000-4000-8000-000000000002';

update public.exam_domains
set description = $ko$?¨ë¼???ˆì¸¡, batch prediction, ëª¨ë‹ˆ?°ë§, drift ?€?‘ì„ PMLE ?œë‚˜ë¦¬ì˜¤ë¡??ë‹¨?©ë‹ˆ??$ko$,
    exam_points = array['Endpoint?€ batch prediction??êµ¬ë¶„?©ë‹ˆ??, 'ëª¨ë‹ˆ?°ë§?€ ë°°í¬ ???´ì˜???µì‹¬?…ë‹ˆ??],
    practical_points = array['ì§€?°ì‹œê°? ì²˜ë¦¬?? ë¹„ìš©, ?´ì˜ ì±…ìž„???¨ê»˜ ê³ ë ¤?©ë‹ˆ??, '?Œë¦¼ ê¸°ì?ê³??€???ˆì°¨ë¥?ë¯¸ë¦¬ ?•í•©?ˆë‹¤']
where id = '80000000-0000-4000-8000-000000000003';

update public.service_comparisons
set category = 'Storage',
    best_for = $ko$?Œì¼, ?´ë?ì§€, ?™ìŠµ ?°ì´?? ëª¨ë¸ artifact ?€??ko$,
    avoid_when = $ko$SQL ë¶„ì„??ì£¼ëœ ëª©í‘œ????ko$,
    exam_point = $ko$ê°ì²´ ?€?¥ì†Œ?€ ë¶„ì„ ?€?¥ì†Œë¥?êµ¬ë¶„?©ë‹ˆ??$ko$,
    practical_point = $ko$bucket IAM, ë¦¬ì „, lifecycle, naming??? ì¤‘???¤ê³„?©ë‹ˆ??$ko$
where id = '81000000-0000-4000-8000-000000000001';

update public.service_comparisons
set category = 'Analytics',
    best_for = $ko$?€ê·œëª¨ ???°ì´??ë¶„ì„, ?¼ì²˜ ?ìƒ‰, BigQuery ML$ko$,
    avoid_when = $ko$?¨ìˆœ ?Œì¼ ?€?¥ì´ ì£¼ëœ ëª©í‘œ????ko$,
    exam_point = $ko$ë¶„ì„ê³?feature engineering ?œë‚˜ë¦¬ì˜¤?ì„œ ?ì£¼ ? íƒ?©ë‹ˆ??$ko$,
    practical_point = $ko$?Œí‹°?”ë‹ê³??´ëŸ¬?¤í„°ë§ìœ¼ë¡??±ëŠ¥ê³?ë¹„ìš©??ê´€ë¦¬í•©?ˆë‹¤.$ko$
where id = '81000000-0000-4000-8000-000000000002';

update public.service_comparisons
set category = 'ML Training',
    best_for = $ko$?¼ë²¨ ?°ì´?°ë¡œ ë¹ ë¥¸ low-code baseline ëª¨ë¸ ë§Œë“¤ê¸?ko$,
    avoid_when = $ko$?Œê³ ë¦¬ì¦˜?´ë‚˜ ?„í‚¤?ì²˜ë¥??„ì „???œì–´?´ì•¼ ????ko$,
    exam_point = $ko$ë¹ ë¥¸ ê´€ë¦¬í˜• AI ?”ë£¨??? íƒì§€ë¡??ì£¼ ?±ìž¥?©ë‹ˆ??$ko$,
    practical_point = $ko$baseline ?ˆì§ˆ???•ì¸????custom training ?„ìš”?±ì„ ë¹„êµ?©ë‹ˆ??$ko$
where id = '81000000-0000-4000-8000-000000000005';

update public.service_comparisons
set category = 'MLOps',
    best_for = $ko$ëª¨ë¸ ë²„ì „, ë©”í??°ì´?? ë°°í¬ ?íƒœ ì¶”ì $ko$,
    avoid_when = $ko$?¨ìˆœ??ë¡œì»¬ ?¤í—˜ë§??„ìš”??ê²½ìš°$ko$,
    exam_point = $ko$ëª¨ë¸ ê±°ë²„?ŒìŠ¤?€ ë²„ì „ ì¶”ì  ?œë‚˜ë¦¬ì˜¤?ì„œ ì¤‘ìš”?©ë‹ˆ??$ko$,
    practical_point = $ko$?¹ì¸, ë¡¤ë°±, ì¶”ì ?±ì„ ì§€?í•˜?????¬ìš©?©ë‹ˆ??$ko$
where id = '81000000-0000-4000-8000-000000000006';

update public.service_comparisons
set category = 'Serving',
    best_for = $ko$?¨ë¼???ˆì¸¡, traffic split, autoscaling$ko$,
    avoid_when = $ko$?€???Œì¼??ë°¤ìƒˆ ë¹„ë™ê¸°ë¡œ scoring?˜ëŠ” ê²ƒì´ ëª©í‘œ????ko$,
    exam_point = $ko$?¨ë¼???ˆì¸¡ê³?batch prediction??êµ¬ë¶„?©ë‹ˆ??$ko$,
    practical_point = $ko$ì§€?°ì‹œê°? ?•ìž¥, ?¸ëž˜???¼ìš°?? ?‘ê·¼ ?œì–´ë¥??¤ê³„?©ë‹ˆ??$ko$
where id = '81000000-0000-4000-8000-000000000007';

update public.service_comparisons
set category = 'Operations',
    best_for = $ko$drift, skew, ?ˆì¸¡ ?ˆì§ˆ, ?œë¹„???íƒœ ëª¨ë‹ˆ?°ë§$ko$,
    avoid_when = $ko$ëª¨ë¸???„ì§ ë°°í¬?˜ì? ?Šì? ê²½ìš°$ko$,
    exam_point = $ko$ë°°í¬ ??ëª¨ë‹ˆ?°ë§?€ PMLE ?œë‚˜ë¦¬ì˜¤???µì‹¬?…ë‹ˆ??$ko$,
    practical_point = $ko$?´ì˜ ??alert ê¸°ì?ê³??´ë‹¹?ë? ?•í•©?ˆë‹¤.$ko$
where id = '81000000-0000-4000-8000-000000000008';

update public.quizzes
set question = case id
  when '30000000-0000-4000-8000-000000000001' then $ko$ë³€?˜ë? ë§Œë“¤ ???¬ìš©?˜ëŠ” ê¸°í˜¸??ë¬´ì—‡?¸ê???$ko$
  when '30000000-0000-4000-8000-000000000002' then $ko$ë¬¸ìž ?°ì´?°ë? ?˜í??´ëŠ” ?ë£Œ?•ì? ë¬´ì—‡?¸ê???$ko$
  when '30000000-0000-4000-8000-000000000003' then $ko$ì¡°ê±´ë¬¸ì„ ?œìž‘?????¬ìš©?˜ëŠ” ?¤ì›Œ?œëŠ” ë¬´ì—‡?¸ê???$ko$
  when '30000000-0000-4000-8000-000000000004' then $ko$ë¦¬ìŠ¤?¸ì˜ ê°’ì„ ?˜ë‚˜??êº¼ë‚¼ ???ì£¼ ?¬ìš©?˜ëŠ” ë°˜ë³µë¬¸ì? ë¬´ì—‡?¸ê???$ko$
  else question
end,
explanation = case id
  when '30000000-0000-4000-8000-000000000001' then $ko$= ê¸°í˜¸???¤ë¥¸ìª?ê°’ì„ ?¼ìª½ ë³€?˜ëª…???€?¥í•©?ˆë‹¤.$ko$
  when '30000000-0000-4000-8000-000000000002' then $ko$ë¬¸ìž ?°ì´?°ëŠ” string?´ë©° Python?ì„œ??str?´ë¼ê³?ë¶€ë¦…ë‹ˆ??$ko$
  when '30000000-0000-4000-8000-000000000003' then $ko$if??ì¡°ê±´ë¬¸ì„ ?œìž‘?˜ëŠ” ?¤ì›Œ?œìž…?ˆë‹¤.$ko$
  when '30000000-0000-4000-8000-000000000004' then $ko$for ë°˜ë³µë¬¸ì? ë¦¬ìŠ¤??ê°™ì? ë¬¶ìŒ?ì„œ ê°’ì„ ?˜ë‚˜??êº¼ë‚¼ ???ì£¼ ?ë‹ˆ??$ko$
  else explanation
end
where id in (
  '30000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000002',
  '30000000-0000-4000-8000-000000000003',
  '30000000-0000-4000-8000-000000000004'
);

update public.quizzes
set question = case id
  when '31000000-0000-4000-8000-000000000001' then $ko$?¨ìˆ˜ë¥?ë§Œë“¤ ???¬ìš©?˜ëŠ” ?¤ì›Œ?œëŠ” ë¬´ì—‡?¸ê???$ko$
  when '31000000-0000-4000-8000-000000000002' then $ko$ë¦¬ìŠ¤???ì— ê°’ì„ ì¶”ê??????ì£¼ ?°ëŠ” ë©”ì„œ?œëŠ” ë¬´ì—‡?¸ê???$ko$
  when '31000000-0000-4000-8000-000000000003' then $ko$key-value ?ìœ¼ë¡??°ì´?°ë? ?€?¥í•˜??êµ¬ì¡°??ë¬´ì—‡?¸ê???$ko$
  when '31000000-0000-4000-8000-000000000004' then $ko$?Œì¼???½ê¸° ëª¨ë“œë¡??????¬ìš©?˜ëŠ” ëª¨ë“œ??ë¬´ì—‡?¸ê???$ko$
  when '31000000-0000-4000-8000-000000000005' then $ko$try?ì„œ ?ëŸ¬ê°€ ë°œìƒ?ˆì„ ??ì²˜ë¦¬?˜ëŠ” ?¤ì›Œ?œëŠ” ë¬´ì—‡?¸ê???$ko$
  when '32000000-0000-4000-8000-000000000001' then $ko$NumPy?ì„œ ë°°ì—´??ë§Œë“¤ ???ì£¼ ?°ëŠ” ?¨ìˆ˜??ë¬´ì—‡?¸ê???$ko$
  when '32000000-0000-4000-8000-000000000002' then $ko$Pandas?ì„œ ???•íƒœ ?°ì´?°ë? ?€?œí•˜??êµ¬ì¡°??ë¬´ì—‡?¸ê???$ko$
  when '32000000-0000-4000-8000-000000000003' then $ko$CSV ?Œì¼??ë¶ˆëŸ¬?¤ëŠ” Pandas ?¨ìˆ˜??ë¬´ì—‡?¸ê???$ko$
  when '32000000-0000-4000-8000-000000000004' then $ko$ê²°ì¸¡ì¹˜ë? ì°¾ëŠ” ???°ëŠ” ?¨ìˆ˜??ë¬´ì—‡?¸ê???$ko$
  when '32000000-0000-4000-8000-000000000005' then $ko$ê°’ì˜ ë³€?”ë? ? ìœ¼ë¡?ë³´ì—¬ ì£¼ëŠ” ì°¨íŠ¸??ë¬´ì—‡?¸ê???$ko$
  when '33000000-0000-4000-8000-000000000001' then $ko$?‰ê· ?€ ?´ë–»ê²?ê³„ì‚°?˜ë‚˜??$ko$
  when '33000000-0000-4000-8000-000000000002' then $ko$ë¶„ì‚°?€ ë¬´ì—‡??ì¸¡ì •?˜ë‚˜??$ko$
  when '33000000-0000-4000-8000-000000000003' then $ko$?œì??¸ì°¨??ë¬´ì—‡???œê³±ê·¼ì¸ê°€??$ko$
  when '33000000-0000-4000-8000-000000000004' then $ko$?•ë¥  ê°’ì˜ ë²”ìœ„???´ë””ë¶€???´ë””ê¹Œì??¸ê???$ko$
  when '33000000-0000-4000-8000-000000000005' then $ko$?ê?ê´€ê³??´ì„?ì„œ ì£¼ì˜???ì? ë¬´ì—‡?¸ê???$ko$
  else question
end,
explanation = case id
  when '31000000-0000-4000-8000-000000000001' then $ko$def??Python ?¨ìˆ˜ë¥?ë§Œë“œ???¤ì›Œ?œìž…?ˆë‹¤.$ko$
  when '31000000-0000-4000-8000-000000000002' then $ko$append??ë¦¬ìŠ¤???ì— ??ê°’ì„ ì¶”ê??©ë‹ˆ??$ko$
  when '31000000-0000-4000-8000-000000000003' then $ko$?•ì…”?ˆë¦¬??key?€ valueë¥?ì§ìœ¼ë¡??€?¥í•©?ˆë‹¤.$ko$
  when '31000000-0000-4000-8000-000000000004' then $ko$r?€ read ëª¨ë“œ?…ë‹ˆ??$ko$
  when '31000000-0000-4000-8000-000000000005' then $ko$except??try?ì„œ ë°œìƒ???ëŸ¬ë¥?ì²˜ë¦¬?©ë‹ˆ??$ko$
  when '32000000-0000-4000-8000-000000000001' then $ko$np.array??NumPy ë°°ì—´??ë§Œë“¤ ???¬ìš©?©ë‹ˆ??$ko$
  when '32000000-0000-4000-8000-000000000002' then $ko$DataFrame?€ Pandas???€?œì ?????•íƒœ ?°ì´??êµ¬ì¡°?…ë‹ˆ??$ko$
  when '32000000-0000-4000-8000-000000000003' then $ko$read_csv??CSV ?Œì¼???½ìŠµ?ˆë‹¤.$ko$
  when '32000000-0000-4000-8000-000000000004' then $ko$isna??ê²°ì¸¡ì¹˜ë? ì°¾ëŠ” ???¬ìš©?©ë‹ˆ??$ko$
  when '32000000-0000-4000-8000-000000000005' then $ko$line chart???œê°„ ?ë¦„?´ë‚˜ ?œì„œ???°ë¥¸ ë³€?”ë? ë³´ê¸° ì¢‹ìŠµ?ˆë‹¤.$ko$
  when '33000000-0000-4000-8000-000000000001' then $ko$?‰ê· ?€ ?©ê³„ë¥??°ì´??ê°œìˆ˜ë¡??˜ëˆ„??ê³„ì‚°?©ë‹ˆ??$ko$
  when '33000000-0000-4000-8000-000000000002' then $ko$ë¶„ì‚°?€ ?°ì´?°ê? ?‰ê· ?ì„œ ?¼ë§ˆ???¼ì ¸ ?ˆëŠ”ì§€ ?˜í??…ë‹ˆ??$ko$
  when '33000000-0000-4000-8000-000000000003' then $ko$?œì??¸ì°¨??ë¶„ì‚°???œê³±ê·¼ìž…?ˆë‹¤.$ko$
  when '33000000-0000-4000-8000-000000000004' then $ko$?•ë¥ ?€ 0ë¶€??1 ?¬ì´??ê°’ìž…?ˆë‹¤.$ko$
  when '33000000-0000-4000-8000-000000000005' then $ko$?ê?ê´€ê³„ëŠ” ?¸ê³¼ê´€ê³„ë? ?ë™?¼ë¡œ ?˜ë??˜ì? ?ŠìŠµ?ˆë‹¤.$ko$
  else explanation
end
where id::text like '31000000-%'
   or id::text like '32000000-%'
   or id::text like '33000000-%';

update public.quizzes
set question = case id
  when '34000000-0000-4000-8000-000000000001' then $ko$ì§€?„í•™?µì˜ ?µì‹¬ ?¹ì§•?€ ë¬´ì—‡?¸ê???$ko$
  when '34000000-0000-4000-8000-000000000002' then $ko$ë¹„ì??„í•™?µì? ë¬´ì—‡??ì°¾ë‚˜??$ko$
  when '34000000-0000-4000-8000-000000000003' then $ko$?Œê????´ë–¤ ê°’ì„ ?ˆì¸¡?˜ë‚˜??$ko$
  when '34000000-0000-4000-8000-000000000004' then $ko$ë¶„ë¥˜??ë¬´ì—‡???ˆì¸¡?˜ë‚˜??$ko$
  when '34000000-0000-4000-8000-000000000005' then $ko$ê³¼ì ?©ì˜ ?€?œì ??? í˜¸??ë¬´ì—‡?¸ê???$ko$
  when '34000000-0000-4000-8000-000000000006' then $ko$ë¶„ë¥˜ ë¬¸ì œ?ì„œ ?ì£¼ ?°ëŠ” ?‰ê? ì§€?œëŠ” ë¬´ì—‡?¸ê???$ko$
  when '34000000-0000-4000-8000-000000000007' then $ko$Scikit-learn?ì„œ ëª¨ë¸???™ìŠµ?????ì£¼ ?°ëŠ” ë©”ì„œ?œëŠ” ë¬´ì—‡?¸ê???$ko$
  else question
end,
explanation = case id
  when '34000000-0000-4000-8000-000000000001' then $ko$ì§€?„í•™?µì? ?•ë‹µ ?¼ë²¨???ˆëŠ” ?ˆì œë¡??™ìŠµ?©ë‹ˆ??$ko$
  when '34000000-0000-4000-8000-000000000002' then $ko$ë¹„ì??„í•™?µì? ?¼ë²¨ ?†ì´ ?¨í„´?´ë‚˜ ê·¸ë£¹??ì°¾ìŠµ?ˆë‹¤.$ko$
  when '34000000-0000-4000-8000-000000000003' then $ko$?Œê????°ì†?ì¸ ?«ìž ê°’ì„ ?ˆì¸¡?©ë‹ˆ??$ko$
  when '34000000-0000-4000-8000-000000000004' then $ko$ë¶„ë¥˜??ë²”ì£¼???¼ë²¨???ˆì¸¡?©ë‹ˆ??$ko$
  when '34000000-0000-4000-8000-000000000005' then $ko$?™ìŠµ ?ìˆ˜???’ì????ŒìŠ¤???ìˆ˜ê°€ ??œ¼ë©?ê³¼ì ?©ì„ ?˜ì‹¬?©ë‹ˆ??$ko$
  when '34000000-0000-4000-8000-000000000006' then $ko$accuracy??ë¶„ë¥˜?ì„œ ?ì£¼ ?°ëŠ” ê¸°ë³¸ ì§€?œìž…?ˆë‹¤.$ko$
  when '34000000-0000-4000-8000-000000000007' then $ko$fit?€ ëª¨ë¸???™ìŠµ?????¬ìš©?˜ëŠ” ?€??ë©”ì„œ?œìž…?ˆë‹¤.$ko$
  else explanation
end
where id::text like '34000000-%';

update public.quizzes
set question = case id
  when '35000000-0000-4000-8000-000000000001' then $ko$GCP?ì„œ ë¦¬ì†Œ?¤ì? ê³¼ê¸ˆ??ë¬¶ëŠ” ê¸°ë³¸ ?¨ìœ„??ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000002' then $ko$IAM??êµ¬ì„±?˜ëŠ” ?µì‹¬ ?”ì†Œ ì¡°í•©?€ ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000003' then $ko$Cloud Storage bucket ?ˆì—??ë¬´ì—‡???€?¥í•˜?˜ìš”?$ko$
  when '35000000-0000-4000-8000-000000000004' then $ko$?€ê·œëª¨ SQL ë¶„ì„??ê°€???í•©???œë¹„?¤ëŠ” ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000005' then $ko$ì§ì ‘ ?œì–´ê°€ ?„ìš”??VM ?œë¹„?¤ëŠ” ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000006' then $ko$?‘ì? ?´ë²¤??ê¸°ë°˜ ?¨ìˆ˜ë¥??¤í–‰?˜ê¸° ì¢‹ì? ?œë¹„?¤ëŠ” ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000007' then $ko$ML ?™ìŠµ, ë°°í¬, ?ˆì¸¡, ëª¨ë‹ˆ?°ë§??ê´€ë¦¬í•˜??Google Cloud ?Œëž«?¼ì? ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000008' then $ko$ë¹ ë¥¸ low-code baseline ëª¨ë¸??? ìš©??Vertex AI ë°©ì‹?€ ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000009' then $ko$ëª¨ë¸ ë²„ì „ê³?ë°°í¬ ?íƒœë¥?ì¶”ì ?˜ëŠ” ê¸°ëŠ¥?€ ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000010' then $ko$?¨ë¼???ˆì¸¡ ?”ì²­??ë°›ëŠ” Vertex AI ë¦¬ì†Œ?¤ëŠ” ë¬´ì—‡?¸ê???$ko$
  when '35000000-0000-4000-8000-000000000011' then $ko$ë°°í¬ ??drift?€ ?œë¹„???íƒœë¥??•ì¸?˜ëŠ” ê¸°ëŠ¥?€ ë¬´ì—‡?¸ê???$ko$
  else question
end,
explanation = case id
  when '35000000-0000-4000-8000-000000000001' then $ko$?„ë¡œ?íŠ¸??GCP ë¦¬ì†Œ?? API, IAM, ê³¼ê¸ˆ??ë¬¶ëŠ” ê¸°ë³¸ ?¨ìœ„?…ë‹ˆ??$ko$
  when '35000000-0000-4000-8000-000000000002' then $ko$IAM?€ member, role, resource??ê´€ê³„ë¡œ ?´í•´?©ë‹ˆ??$ko$
  when '35000000-0000-4000-8000-000000000003' then $ko$Cloud Storage???Œì¼, ?´ë?ì§€, ?™ìŠµ ?°ì´?? ëª¨ë¸ artifact ê°™ì? ê°ì²´ë¥??€?¥í•©?ˆë‹¤.$ko$
  when '35000000-0000-4000-8000-000000000004' then $ko$BigQuery???€ê·œëª¨ SQL ë¶„ì„???í•©???œë²„ë¦¬ìŠ¤ ?°ì´???¨ì–´?˜ìš°?¤ìž…?ˆë‹¤.$ko$
  when '35000000-0000-4000-8000-000000000005' then $ko$Compute Engine?€ VM??ì§ì ‘ ë§Œë“¤ê³??œì–´?˜ëŠ” ?œë¹„?¤ìž…?ˆë‹¤.$ko$
  when '35000000-0000-4000-8000-000000000006' then $ko$Cloud Functions???´ë²¤?¸ì— ë°˜ì‘?˜ëŠ” ?‘ì? ì½”ë“œ ?¤í–‰???í•©?©ë‹ˆ??$ko$
  when '35000000-0000-4000-8000-000000000007' then $ko$Vertex AI??Google Cloud???µí•© ML ?Œëž«?¼ìž…?ˆë‹¤.$ko$
  when '35000000-0000-4000-8000-000000000008' then $ko$AutoML?€ ë¹ ë¥¸ low-code ?™ìŠµ??? ìš©?©ë‹ˆ??$ko$
  when '35000000-0000-4000-8000-000000000009' then $ko$Model Registry??ëª¨ë¸ ë²„ì „ê³?ë°°í¬ ?íƒœë¥?ì¶”ì ?©ë‹ˆ??$ko$
  when '35000000-0000-4000-8000-000000000010' then $ko$Endpoint??ë°°í¬??ëª¨ë¸???¨ë¼???ˆì¸¡ ?”ì²­??ë°›ìŠµ?ˆë‹¤.$ko$
  when '35000000-0000-4000-8000-000000000011' then $ko$Model Monitoring?€ drift, skew, latency, error ê°™ì? ?´ì˜ ? í˜¸ë¥??•ì¸?©ë‹ˆ??$ko$
  else explanation
end
where id::text like '35000000-%';
