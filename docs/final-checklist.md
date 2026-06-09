# Final Checklist

## Code

- Next.js app routes are present.
- TypeScript typecheck passes.
- Production build passes.
- Gemini API calls are server-only.
- No OpenAI SDK or API key is used.

## Supabase

- All migrations are applied in order.
- RLS is enabled on user-owned tables.
- Authenticated content tables are readable.
- User data is scoped by `auth.uid() = user_id`.
- Generated career artifacts are user-owned.

## Authentication

- Protected pages use `useRequiredUser`.
- Unauthenticated users are redirected to `/auth`.
- Browser client uses only Supabase anon key.

## Security

- `GEMINI_API_KEY` is not exposed to client code.
- `SUPABASE_SERVICE_ROLE_KEY` is not exposed to client code.
- Secrets are not stored in committed files.
- Career generation route checks authenticated user ownership.

## UI

- Main routes are reachable from navigation.
- Dashboards use responsive grid layouts.
- Forms show save/generate status.
- Errors are shown to the user.

## Netlify

- `netlify.toml` has build command `npm run build`.
- Publish directory is `.next`.
- Node version is configured as `22`.
- Environment variables are set in Netlify UI.

## Smoke Test

- Sign up.
- Log in.
- Complete a lesson quiz.
- Save a learning note.
- Save a journal entry.
- Ask AI tutor a question.
- Submit a coding task.
- Open ML dashboard.
- Open GCP dashboard.
- Submit a mock exam.
- Create a portfolio project.
- Generate README.
- Generate resume bullet.
- Generate interview questions.
- Confirm `/career` readiness scores update.
