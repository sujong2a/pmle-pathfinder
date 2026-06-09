# Deployment Guide

## Platform

PMLE Pathfinder is configured for Netlify.

Current `netlify.toml`:

```toml
[build]
  command = "npm run build"
  publish = ".next"

[build.environment]
  NODE_VERSION = "22"

[dev]
  command = "npm run dev"
  targetPort = 3000
  port = 8888
  framework = "#auto"
```

## Required Netlify Environment Variables

Set these in Netlify Site settings:

```env
GEMINI_API_KEY=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

Do not put secret values in `netlify.toml`.

## Pre-Deploy Checklist

Run locally:

```bash
npm run typecheck
npm run build
```

Confirm:

- Supabase SQL migrations have been applied.
- Supabase Auth is enabled.
- RLS policies are active.
- Gemini key is set only as a server environment variable.
- No OpenAI packages or keys are used.
- `/auth`, `/dashboard`, `/curriculum`, `/mock-exams`, and `/career` render locally.

## Git-Based Netlify Deploy

1. Push the repository to GitHub.
2. Create a new Netlify site from the GitHub repository.
3. Confirm build settings:
   - Build command: `npm run build`
   - Publish directory: `.next`
4. Add environment variables.
5. Deploy.

## Netlify CLI Deploy

Install and log in:

```bash
npm install -g netlify-cli
netlify login
```

Link or create the site:

```bash
netlify link
```

Build:

```bash
npm run build
```

Deploy preview:

```bash
netlify deploy
```

Deploy production:

```bash
netlify deploy --prod
```

## Post-Deploy Smoke Test

- Open the deployed URL.
- Sign up or log in.
- Save a learning note.
- Submit a quiz.
- Start and submit a mock exam.
- Create a portfolio project.
- Generate a README, resume bullet, and interview questions.
- Confirm `/career` scores and reports update.
