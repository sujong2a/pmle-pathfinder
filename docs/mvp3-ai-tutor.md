# PMLE Pathfinder MVP3 Gemini AI Tutor

## 구현 범위

- AI 질문하기
- AI 튜터 답변 생성
- AI 대화 세션 저장
- AI 대화 메시지 저장
- AI 설명 저장
- 사용자 진도, 오답노트, 취약개념, 최근 학습일지를 참고한 맞춤형 답변

## Gemini 코드

- `lib/ai/provider.ts`
- `lib/ai/gemini.ts`

구조:

- `provider.ts`: 교체 가능한 AI provider 인터페이스와 튜터 시스템 프롬프트
- `gemini.ts`: Gemini REST API 구현체

Gemini 호출은 서버에서만 실행됩니다.

## API 코드

- `app/api/ai-tutor/route.ts`

지원 기능:

- `GET /api/ai-tutor`: AI 세션, 선택 세션 메시지, 저장된 설명 조회
- `POST /api/ai-tutor` with `action: "send_message"`: 질문 전송, Gemini 답변 생성, 메시지 저장
- `POST /api/ai-tutor` with `action: "save_explanation"`: AI 설명 저장

## UI 코드

- `components/ai-tutor-client.tsx`
- `app/ai-tutor/page.tsx`
- `components/app-shell.tsx`

화면 구성:

- 대화 세션 목록
- AI 질문 입력
- 대화 기록
- AI 설명 저장 버튼
- 저장한 AI 설명 목록
- AI 학습 도우미 안내

## DB 저장 로직

추가 테이블:

- `ai_chat_sessions`
- `ai_chat_messages`
- `saved_ai_explanations`

마이그레이션 SQL:

- `docs/mvp3-ai-tutor-migration.sql`

적용 순서:

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`

모든 AI 기록 테이블은 RLS를 사용하며, 사용자는 자기 데이터만 조회/저장할 수 있습니다.

## 환경변수

`.env.local`:

```env
GEMINI_API_KEY=사용자가_제공한_키
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
```

중요:

- `GEMINI_API_KEY`에는 `NEXT_PUBLIC_`을 붙이지 않습니다.
- Gemini 키는 클라이언트 코드에서 읽지 않습니다.
- Netlify에서는 Site settings > Environment variables에 `GEMINI_API_KEY`를 추가합니다.

## AI 튜터 규칙

시스템 프롬프트는 다음 규칙을 강제합니다.

- 사용자는 비전공자이며 Python 초보
- 쉬운 한국어
- 비유 사용
- 단계별 설명
- 힌트 우선 제공
- 사고 유도
- 진도, 오답노트, 취약개념, 최근 학습일지 반영

## Gemini API 참고

공식 Gemini API 문서의 `generateContent` REST 엔드포인트를 사용합니다.

- `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- API key는 `x-goog-api-key` 헤더로 전달

## 테스트 체크리스트

- [ ] Supabase에서 `docs/mvp3-ai-tutor-migration.sql`이 오류 없이 실행된다.
- [ ] `ai_chat_sessions`, `ai_chat_messages`, `saved_ai_explanations` 테이블이 생성된다.
- [ ] `.env.local`에 `GEMINI_API_KEY`가 설정되어 있다.
- [ ] 로그인하지 않은 사용자는 `/ai-tutor` 접근 시 `/auth`로 이동한다.
- [ ] AI 튜터 화면에서 새 질문을 보낼 수 있다.
- [ ] 질문 후 `ai_chat_sessions`에 세션이 저장된다.
- [ ] 질문과 답변이 `ai_chat_messages`에 저장된다.
- [ ] 기존 세션을 클릭하면 대화 기록이 다시 표시된다.
- [ ] AI 답변의 저장 버튼을 누르면 `saved_ai_explanations`에 저장된다.
- [ ] 저장한 AI 설명 목록에 설명이 표시된다.
- [ ] 오답노트나 취약개념이 있는 사용자의 질문에 해당 맥락이 반영된다.
- [ ] 브라우저 HTML과 클라이언트 번들에 `GEMINI_API_KEY` 값이 노출되지 않는다.
- [ ] `npm run typecheck`가 통과한다.
- [ ] `npm run build`가 통과한다.
