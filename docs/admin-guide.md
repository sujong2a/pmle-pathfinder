# Admin Guide

## Purpose

PMLE Pathfinder is a learning operating system for Python beginners moving toward AI engineering and PMLE readiness. Admin work is mainly database setup, environment configuration, security review, and deployment verification.

## Required Environment Variables

```env
GEMINI_API_KEY=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

Rules:

- `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` can be used in browser code.
- `GEMINI_API_KEY` must only be used by server routes.
- `SUPABASE_SERVICE_ROLE_KEY` must never be used in browser code.
- Do not add OpenAI keys or OpenAI SDKs.

## Database Installation

Run SQL files in this order:

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`
4. `docs/mvp4-coding-lab-migration.sql`
5. `docs/mvp5-ml-course-migration.sql`
6. `docs/mvp6-gcp-vertex-migration.sql`
7. `docs/mvp7-mock-exams-migration.sql`
8. `docs/mvp8-career-os-migration.sql`
9. `docs/korean-localization.sql`

For a single combined file, use:

```text
docs/supabase-complete.sql
```

## RLS Review

Content tables are readable by authenticated users:

- `modules`
- `lessons`
- `quizzes`
- `quiz_options`
- `coding_tasks`
- `ml_concept_map`
- `exam_domains`
- `service_comparisons`
- `scenario_questions`
- `mock_exams`
- `mock_exam_questions`

User-owned tables must use `auth.uid() = user_id` policies:

- `user_progress`
- `quiz_attempts`
- `wrong_notes`
- `learning_notes`
- `learning_journal`
- `concept_mastery`
- `review_schedule`
- `ai_chat_sessions`
- `ai_chat_messages`
- `saved_ai_explanations`
- `coding_submissions`
- `coding_feedback`
- `mock_exam_attempts`
- `mock_exam_answers`
- `exam_domain_scores`
- `portfolio_projects`
- `project_steps`
- `resume_bullets`
- `interview_questions`

## Security Checklist

- Confirm no secrets are committed in `.env`, `README.md`, or SQL.
- Confirm `GEMINI_API_KEY` appears only in server-side code.
- Confirm all protected pages call `useRequiredUser`.
- Confirm Supabase RLS is enabled on all user-owned tables.
- Confirm generated career content is saved only for the authenticated user.
- Confirm Netlify environment variables are configured in the Netlify UI, not committed to `netlify.toml`.

## Operational Checks

Run before deployment:

```bash
npm run typecheck
npm run build
```

Smoke test:

- Sign up.
- Complete a lesson quiz.
- Save a learning note.
- Create a portfolio project.
- Generate README, resume bullet, and interview questions.
- Start and submit a mock exam.
- Confirm `/career` readiness scores update.
