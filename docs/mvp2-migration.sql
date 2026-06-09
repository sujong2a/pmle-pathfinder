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
