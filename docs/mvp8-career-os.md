# PMLE Pathfinder MVP8 - Career Operating System

## Scope

MVP8 completes PMLE Pathfinder as an AI engineer transition platform.

Added features:

- Portfolio management
- Project steps
- GitHub README generation
- Resume bullet generation
- Interview question generation
- Learning statistics
- PMLE readiness score
- Career transition readiness score
- Weekly report
- Monthly report
- D-Day tracking
- Final readiness checks

## Files Added Or Changed

- `app/career/page.tsx`
- `app/api/career-tools/route.ts`
- `components/career-client.tsx`
- `components/app-shell.tsx`
- `lib/career/readiness.ts`
- `lib/types.ts`
- `docs/mvp8-career-os-migration.sql`
- `README.md`
- `docs/admin-guide.md`
- `docs/user-guide.md`
- `docs/deployment-guide.md`
- `docs/roadmap.md`
- `docs/final-checklist.md`

## New Tables

- `portfolio_projects`
- `project_steps`
- `resume_bullets`
- `interview_questions`

## Generation Rules

- Generation calls use `/api/career-tools`.
- The API route authenticates with Supabase Auth.
- The route only reads and writes the authenticated user's project data.
- Gemini is used only from server-side code.
- If `GEMINI_API_KEY` is unavailable or Gemini fails, deterministic templates are used.

## Readiness Scores

PMLE readiness uses:

- total lesson progress
- GCP + Vertex AI progress
- best mock exam score
- study consistency
- unresolved wrong-note penalty

Career readiness uses:

- completed portfolio projects
- started portfolio projects
- resume bullet count
- interview question count
- weekly study momentum
- PMLE readiness

## Migration Order

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`
4. `docs/mvp4-coding-lab-migration.sql`
5. `docs/mvp5-ml-course-migration.sql`
6. `docs/mvp6-gcp-vertex-migration.sql`
7. `docs/mvp7-mock-exams-migration.sql`
8. `docs/mvp8-career-os-migration.sql`

## Test Checklist

- Apply MVP8 SQL.
- Log in.
- Open `/career`.
- Create a portfolio project.
- Add project steps.
- Toggle a step complete.
- Generate a README.
- Generate a resume bullet.
- Generate interview questions.
- Confirm generated rows are saved in Supabase.
- Confirm PMLE readiness score renders.
- Confirm career readiness score renders.
- Confirm weekly report renders.
- Confirm monthly report renders.
- Confirm D-Day changes when target date is set.
- Run `npm run typecheck`.
- Run `npm run build`.
