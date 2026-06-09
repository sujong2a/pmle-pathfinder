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
