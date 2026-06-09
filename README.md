# PMLE Pathfinder

PMLE Pathfinder is a web-based learning operating system for non-CS beginners who want to move from Python fundamentals to AI engineering and Google Cloud Professional Machine Learning Engineer readiness.

## What It Includes

- Supabase Auth signup and login
- Curriculum, lessons, notes, quizzes, progress tracking, and wrong notes
- Learning journal, review schedule, weak concept tracking, and understanding score
- Gemini-only AI tutor through server API routes
- Python coding practice with safe static evaluation
- Machine Learning, GCP, Vertex AI, and PMLE mock exam dashboards
- Portfolio project management
- GitHub README generation
- Resume bullet generation
- Interview question generation
- PMLE readiness score
- Career transition readiness score
- Weekly and monthly reports
- D-Day tracking

## Tech Stack

- Next.js
- TypeScript
- TailwindCSS
- Next.js API Routes
- Supabase
- Supabase Auth
- Gemini API
- Netlify

## Environment Variables

```env
GEMINI_API_KEY=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

`GEMINI_API_KEY` and `SUPABASE_SERVICE_ROLE_KEY` must never be exposed to client components.

## Local Setup

```bash
npm install
npm run dev
```

Open:

```text
http://localhost:3000
```

## Supabase Setup

Run the SQL files in this order:

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`
4. `docs/mvp4-coding-lab-migration.sql`
5. `docs/mvp5-ml-course-migration.sql`
6. `docs/mvp6-gcp-vertex-migration.sql`
7. `docs/mvp7-mock-exams-migration.sql`
8. `docs/mvp8-career-os-migration.sql`
9. `docs/korean-localization.sql`

The same SQL is also combined in:

```text
docs/supabase-complete.sql
```

## Key Routes

- `/auth`
- `/dashboard`
- `/curriculum`
- `/learn/[lessonId]`
- `/reviews`
- `/wrong-notes`
- `/ai-tutor`
- `/coding-lab`
- `/ml-dashboard`
- `/gcp-dashboard`
- `/mock-exams`
- `/career`

## Validation

```bash
npm run typecheck
npm run build
```

## Deployment

The project is configured for Netlify with:

- Build command: `npm run build`
- Publish directory: `.next`
- Node version: `22`

See `docs/deployment-guide.md`.
