# PMLE Pathfinder MVP4 Python 실습 과제 시스템

## 구현 범위

- 코드 에디터
- 실습 제출
- 자동 평가
- Gemini 기반 AI 피드백
- 제출 기록
- 재제출

## 평가 방식

실제 코드는 실행하지 않습니다.

평가 기준:

- 예상 출력 비교
- 필수 키워드 검사
- 정답 패턴 검사

평가 함수:

- `lib/coding/evaluator.ts`

점수 기준:

- 예상 출력 일치: 40점
- 필수 키워드 충족: 30점
- 정답 패턴 일치: 30점

## Gemini 피드백 로직

API Route에서 평가 결과를 만든 뒤 Gemini에 아래 정보를 전달합니다.

- 과제 제목
- 과제 설명
- 요구사항
- 기대 출력
- 사용자 예상 출력
- 사용자 코드
- 자동 평가 결과

Gemini는 다음 형식의 피드백을 생성합니다.

- 잘한 점
- 개선점
- 추천 학습
- 재제출 힌트

Gemini 호출은 서버에서만 실행됩니다.

## 주요 코드

- UI: `components/coding-lab-client.tsx`
- Page: `app/coding-lab/page.tsx`
- API: `app/api/coding-tasks/route.ts`
- 평가 함수: `lib/coding/evaluator.ts`
- 타입: `lib/types.ts`
- 내비게이션: `components/app-shell.tsx`

## 추가 테이블

- `coding_tasks`
- `coding_submissions`
- `coding_feedback`

SQL:

- `docs/mvp4-coding-lab-migration.sql`

## 마이그레이션 순서

Supabase SQL editor에서 아래 순서대로 실행합니다.

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`
4. `docs/mvp4-coding-lab-migration.sql`

## 환경변수

Gemini 피드백을 사용하려면 서버 환경변수에 아래 값을 설정합니다.

```env
GEMINI_API_KEY=사용자가_제공한_키
```

주의:

- `NEXT_PUBLIC_` 접두사를 붙이지 않습니다.
- 브라우저에서 읽지 않습니다.
- API Route에서만 사용합니다.

## 테스트 체크리스트

- [ ] `docs/mvp4-coding-lab-migration.sql`이 Supabase에서 오류 없이 실행된다.
- [ ] `coding_tasks`, `coding_submissions`, `coding_feedback` 테이블이 생성된다.
- [ ] `/coding-lab` 화면에 실습 과제 목록이 표시된다.
- [ ] 과제를 선택하면 starter code가 코드 에디터에 표시된다.
- [ ] 실제 코드 실행 버튼이 없다.
- [ ] 예상 출력을 입력하고 제출할 수 있다.
- [ ] 예상 출력이 틀리면 재제출 상태가 된다.
- [ ] 필수 키워드가 빠지면 개선점에 누락 키워드가 표시된다.
- [ ] 정답 패턴이 맞지 않으면 패턴 관련 개선점이 표시된다.
- [ ] 조건을 모두 만족하면 통과 상태가 된다.
- [ ] 제출할 때마다 `coding_submissions`에 기록된다.
- [ ] 제출할 때마다 `coding_feedback`에 피드백이 저장된다.
- [ ] Gemini 키가 설정되어 있으면 AI 피드백이 생성된다.
- [ ] Gemini 키가 없거나 호출 실패 시 규칙 기반 피드백이 저장된다.
- [ ] 같은 과제를 다시 제출하면 제출 기록에 새 attempt가 추가된다.
- [ ] 다른 사용자로 로그인하면 제출 기록과 피드백이 분리된다.
- [ ] `npm run typecheck`가 통과한다.
- [ ] `npm run build`가 통과한다.
