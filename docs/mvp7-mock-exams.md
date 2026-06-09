# PMLE Pathfinder MVP7 - PMLE Mock Exam System

## Scope

MVP7 adds a PMLE mock exam system on top of MVP6.

Implemented features:

- Exam mode at `/mock-exams`
- Countdown timer
- Random question selection
- Score analysis
- Domain-level analysis
- Automatic wrong answer saving through `mock_exam_answers`
- Retake flow
- Exam attempt history

## Files Changed

- `app/mock-exams/page.tsx`
- `components/mock-exams-client.tsx`
- `components/app-shell.tsx`
- `lib/types.ts`
- `lib/mock-exams/grading.ts`
- `docs/mvp7-mock-exams-migration.sql`

## Database Migration

Run migrations in this order:

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`
4. `docs/mvp4-coding-lab-migration.sql`
5. `docs/mvp5-ml-course-migration.sql`
6. `docs/mvp6-gcp-vertex-migration.sql`
7. `docs/mvp7-mock-exams-migration.sql`

MVP7 creates these tables:

- `mock_exams`
- `mock_exam_questions`
- `mock_exam_attempts`
- `mock_exam_answers`
- `exam_domain_scores`

The migration also inserts one active mock exam and 18 PMLE-style questions. The exam randomly selects 10 questions per attempt.

## Scoring Logic

Scoring code is in:

```text
lib/mock-exams/grading.ts
```

The grading function calculates:

- total questions
- answered questions
- correct answers
- incorrect answers
- unanswered questions
- score percentage
- pass/fail result
- duration
- domain score breakdown

## Local Run

```bash
npm install
npm run dev
```

Open:

```text
http://localhost:3000/mock-exams
```

Required environment variables:

```env
GEMINI_API_KEY=your_gemini_api_key
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

MVP7 does not add AI behavior.

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

- Run the MVP7 SQL after MVP1-MVP6 migrations.
- Sign up or log in with a Supabase Auth user.
- Confirm the navigation shows `Mock Exam`.
- Open `/mock-exams`.
- Confirm the exam overview loads.
- Confirm the active exam shows duration, random question count, and passing score.
- Start the exam.
- Confirm the timer counts down.
- Confirm question navigation works.
- Select answers for several questions.
- Submit before the timer ends.
- Confirm an attempt row is saved in `mock_exam_attempts`.
- Confirm answer rows are saved in `mock_exam_answers`.
- Confirm domain score rows are saved in `exam_domain_scores`.
- Confirm score analysis shows total score and pass/fail.
- Confirm domain analysis shows weakest domains first.
- Confirm wrong answers show selected answer, correct answer, and explanation.
- Click `Retake` and confirm a new randomized attempt starts.
- Return to overview and confirm exam history shows the attempt.
- Run `npm run typecheck`.
- Run `npm run build`.
