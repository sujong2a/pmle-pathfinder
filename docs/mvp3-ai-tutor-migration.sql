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
