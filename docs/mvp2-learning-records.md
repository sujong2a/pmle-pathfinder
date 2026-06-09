# PMLE Pathfinder MVP2 학습 기록 확장

## 변경 코드

주요 변경 파일:

- `components/dashboard-client.tsx`: 대시보드 지표 확장
- `components/lesson-client.tsx`: 학습일지, 이해도 평가, 취약개념 저장, 복습 일정 자동 생성
- `components/reviews-client.tsx`: 복습관리 화면 추가
- `components/curriculum-client.tsx`: 추가 커리큘럼 표시 구조 정리
- `components/app-shell.tsx`: 복습관리 내비게이션 추가
- `app/reviews/page.tsx`: 복습관리 라우트 추가
- `lib/types.ts`: 신규 테이블 타입 추가
- `docs/mvp2-migration.sql`: DB 마이그레이션 SQL

## 추가 커리큘럼

Python 심화:

- 함수
- 리스트
- 딕셔너리
- 파일입출력
- 예외처리

Data Analysis:

- NumPy
- Pandas
- CSV
- 결측치
- 데이터 시각화

Statistics:

- 평균
- 분산
- 표준편차
- 확률
- 상관관계

## 신규 Supabase 테이블

- `learning_journal`: 날짜별 학습일지, 학습시간, 이해도 점수
- `concept_mastery`: 단원별 이해도, 취약개념 여부, 취약점 메모
- `review_schedule`: 1일, 3일, 7일, 14일 복습 일정

## 마이그레이션 방법

1. Supabase SQL editor를 엽니다.
2. MVP1 초기 SQL을 아직 실행하지 않았다면 `docs/supabase.sql`을 먼저 실행합니다.
3. `docs/mvp2-migration.sql` 전체를 실행합니다.
4. 앱을 새로고침합니다.

마이그레이션 SQL은 `create table if not exists`와 `on conflict do update`를 사용하므로 같은 파일을 다시 실행해도 기존 사용자 기록은 유지됩니다.

## Gemini API 키 보관 방식

이번 단계에서는 AI 기능을 구현하지 않습니다. 사용자가 제공한 Gemini 키는 코드에 넣지 말고 아래 위치에만 저장하세요.

로컬:

```env
GEMINI_API_KEY=사용자가_제공한_키
```

Netlify:

- Site settings
- Environment variables
- `GEMINI_API_KEY` 추가

중요:

- `GEMINI_API_KEY`는 `NEXT_PUBLIC_` 접두사를 붙이지 않습니다.
- 클라이언트 컴포넌트에서 읽지 않습니다.
- 향후 AI 기능을 만들 때는 서버 Route Handler 또는 Server Action에서만 사용합니다.

## 로컬 실행

```bash
npm run dev
```

접속:

```txt
http://localhost:3000
```

## 테스트 체크리스트

- [ ] `docs/mvp2-migration.sql` 실행 후 `learning_journal`, `concept_mastery`, `review_schedule` 테이블이 생성된다.
- [ ] `modules`에 Python 심화, Data Analysis, Statistics가 추가된다.
- [ ] `lessons`에 총 15개 추가 단원이 보인다.
- [ ] 커리큘럼 화면에서 새 모듈과 단원이 표시된다.
- [ ] 학습 페이지에서 학습일지를 저장할 수 있다.
- [ ] 학습일지 저장 후 대시보드의 총 학습시간과 최근 학습일지가 갱신된다.
- [ ] 이해도 점수를 저장할 수 있다.
- [ ] 이해도 60점 이하 또는 취약개념 체크 시 대시보드 취약개념 TOP5에 표시된다.
- [ ] 퀴즈를 모두 맞혀 단원을 완료하면 `review_schedule`에 1일, 3일, 7일, 14일 복습 일정이 생성된다.
- [ ] 복습관리 화면에서 오늘 복습과 예정 복습이 표시된다.
- [ ] 복습 완료 버튼을 누르면 해당 복습 일정이 완료 처리된다.
- [ ] 로그인 계정을 바꾸면 학습일지, 취약개념, 복습 일정이 분리되어 보인다.
- [ ] `GEMINI_API_KEY`가 브라우저 코드나 HTML에 노출되지 않는다.
