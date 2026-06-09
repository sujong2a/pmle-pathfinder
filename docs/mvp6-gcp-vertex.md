# PMLE Pathfinder MVP6 - GCP + Vertex AI

## Scope

MVP6 extends the MVP5 platform with a GCP + Vertex AI course for PMLE preparation.

Added course lessons:

- Cloud Fundamentals
- IAM
- Storage
- BigQuery
- Compute Engine
- Cloud Functions
- Vertex AI
- AutoML
- Model Registry
- Endpoints
- Monitoring

Added product features:

- GCP + Vertex AI dashboard at `/gcp-dashboard`
- Service comparison table
- Exam point cards
- Practical point cards
- Scenario quiz UI
- GCP lesson progress via the existing learning page
- GCP quiz and wrong-note support through the existing quiz flow

## Files Changed

- `app/gcp-dashboard/page.tsx`
- `components/gcp-dashboard-client.tsx`
- `components/app-shell.tsx`
- `lib/types.ts`
- `docs/mvp6-gcp-vertex-migration.sql`

## Database Migration

Run the SQL in this order:

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`
4. `docs/mvp4-coding-lab-migration.sql`
5. `docs/mvp5-ml-course-migration.sql`
6. `docs/mvp6-gcp-vertex-migration.sql`

MVP6 creates these tables:

- `exam_domains`
- `service_comparisons`
- `scenario_questions`

The migration also inserts the GCP + Vertex AI module, 11 lessons, lesson quizzes, quiz options, exam point data, service comparison data, and scenario quiz data.

## Local Run

```bash
npm install
npm run dev
```

Open:

```text
http://localhost:3000
```

Required environment variables:

```env
GEMINI_API_KEY=your_gemini_api_key
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

Do not expose `GEMINI_API_KEY` in client components.

## Netlify Deploy

Build command:

```bash
npm run build
```

Publish directory:

```text
.next
```

Set the same environment variables in Netlify Site settings.

## Test Checklist

- Sign up and log in with a Supabase Auth user.
- Confirm the top navigation shows the `GCP` tab.
- Open `/gcp-dashboard`.
- Confirm the GCP + Vertex AI course summary renders.
- Confirm 11 lessons appear in the curriculum list.
- Open each GCP lesson from the dashboard.
- Complete one GCP lesson and confirm dashboard progress changes.
- Answer a GCP lesson quiz incorrectly and confirm the existing wrong-note flow stores it.
- Confirm the service comparison table shows Cloud Storage, BigQuery, Compute Engine, Cloud Functions, Vertex AI AutoML, Model Registry, Endpoints, and Monitoring.
- Confirm exam points and practical points render.
- Answer each scenario quiz option and confirm correct/incorrect feedback appears.
- Run `npm run typecheck`.
- Run `npm run build`.
