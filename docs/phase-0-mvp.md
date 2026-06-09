# PMLE Pathfinder Phase 0 MVP

## 프로젝트 폴더 구조

```txt
app/
  auth/page.tsx
  curriculum/page.tsx
  dashboard/page.tsx
  learn/[lessonId]/page.tsx
  wrong-notes/page.tsx
  globals.css
  layout.tsx
  page.tsx
components/
  app-shell.tsx
  auth-form.tsx
  curriculum-client.tsx
  dashboard-client.tsx
  lesson-client.tsx
  wrong-notes-client.tsx
lib/
  supabase/client.ts
  supabase/profile.ts
  supabase/use-required-user.ts
  types.ts
docs/
  phase-0-mvp.md
  supabase.sql
netlify.toml
.env.example
```

## 구현 범위

- 회원가입
- 로그인
- 대시보드
- 커리큘럼 화면
- 학습 페이지
- 객관식 퀴즈
- 정답/오답 처리
- 진행률 저장
- 오답노트 자동 저장
- 학습 메모 저장

이번 단계에서는 AI 기능을 구현하지 않습니다. 외부 AI 모델 호출은 모두 제외했습니다.

## Supabase SQL

Supabase SQL editor에서 [docs/supabase.sql](./supabase.sql)을 실행합니다.

생성 테이블:

- `users`
- `modules`
- `lessons`
- `quizzes`
- `quiz_options`
- `user_progress`
- `quiz_attempts`
- `wrong_notes`
- `learning_notes`

SQL에는 RLS 정책과 Python 기초 시드 데이터가 포함되어 있습니다.

## 설치 명령어

```bash
npm install
```

이미 의존성이 설치되어 있다면 아래 명령만 필요합니다.

```bash
npm install @supabase/supabase-js
```

## 환경변수 설정

`.env.local` 파일을 만들고 아래 값을 설정합니다.

```env
GEMINI_API_KEY=
NEXT_PUBLIC_SUPABASE_URL=your-supabase-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=
```

이번 MVP에서는 AI 기능을 쓰지 않으므로 `GEMINI_API_KEY`는 비워도 됩니다.

`SUPABASE_SERVICE_ROLE_KEY`는 이번 단계 코드에서 사용하지 않습니다. 브라우저에는 절대 노출하지 마세요.

## 로컬 실행 방법

```bash
npm run dev
```

브라우저에서 아래 주소를 엽니다.

```txt
http://localhost:3000
```

## Netlify 배포 방법

1. Netlify에서 새 사이트를 만들고 Git 저장소를 연결합니다.
2. Build command를 `npm run build`로 설정합니다.
3. Publish directory를 `.next`로 설정합니다.
4. Netlify Environment variables에 아래 값을 등록합니다.
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `GEMINI_API_KEY`는 이번 단계 미사용
   - `SUPABASE_SERVICE_ROLE_KEY`는 이번 단계 미사용
5. Deploy를 실행합니다.

`netlify.toml`에 기본 빌드 설정이 포함되어 있습니다.

## 테스트 체크리스트

- [ ] Supabase SQL 실행 후 `modules`, `lessons`, `quizzes`, `quiz_options`에 Python 기초 데이터가 들어간다.
- [ ] 회원가입이 가능하다.
- [ ] 로그인이 가능하다.
- [ ] 로그인하지 않은 상태에서 `/dashboard` 접근 시 `/auth`로 이동한다.
- [ ] 대시보드에 전체 진행률, 완료 단원 수, 최근 학습, 최근 메모, 누적 오답 수가 표시된다.
- [ ] 커리큘럼 화면에 변수, 자료형, 조건문, 반복문 단원이 보인다.
- [ ] 학습 페이지에서 개념 설명, 예제, 핵심 요약, 퀴즈, 메모 입력창이 보인다.
- [ ] 학습 페이지 진입 시 `user_progress`에 학습 중 상태가 저장된다.
- [ ] 모든 퀴즈를 맞히면 단원이 완료 처리된다.
- [ ] 퀴즈를 틀리면 `wrong_notes`에 자동 저장된다.
- [ ] 오답노트에서 틀린 문제와 정답을 확인할 수 있다.
- [ ] 오답노트의 다시 풀기 버튼이 원래 학습 페이지로 이동한다.
- [ ] 학습 메모 저장 후 대시보드 최근 메모에 표시된다.
- [ ] 다른 계정으로 로그인하면 진행률, 오답노트, 메모가 분리되어 보인다.
