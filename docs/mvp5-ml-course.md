# PMLE Pathfinder MVP5 Machine Learning 과정

## 구현 범위

추가 커리큘럼:

- 지도학습
- 비지도학습
- 회귀
- 분류
- 과적합
- 평가 지표
- Scikit-learn

추가 기능:

- ML 퀴즈
- ML 실습
- ML 오답노트
- ML 개념맵
- ML 학습 대시보드

## 커리큘럼 데이터

SQL 파일:

- `docs/mvp5-ml-course-migration.sql`

추가되는 데이터:

- `modules`: Machine Learning
- `lessons`: ML 7개 단원
- `quizzes`: ML 단원별 퀴즈
- `quiz_options`: ML 퀴즈 선택지
- `coding_tasks`: ML 실습 과제
- `ml_concept_map`: ML 개념 관계 데이터

## UI

추가 파일:

- `components/ml-dashboard-client.tsx`
- `app/ml-dashboard/page.tsx`
- `components/app-shell.tsx`

ML 대시보드 표시:

- ML 단원 진행률
- 완료 단원 수
- ML 미해결 오답 수
- ML 실습 진행률
- ML 커리큘럼
- ML 오답노트
- ML 실습 목록
- ML 개념맵

## DB 변경

신규 테이블:

- `ml_concept_map`

기존 테이블에 추가 데이터 삽입:

- `modules`
- `lessons`
- `quizzes`
- `quiz_options`
- `coding_tasks`

`ml_concept_map`은 인증된 사용자가 읽을 수 있는 RLS 정책을 사용합니다.

## 마이그레이션 순서

Supabase SQL editor에서 아래 순서대로 실행합니다.

1. `docs/supabase.sql`
2. `docs/mvp2-migration.sql`
3. `docs/mvp3-ai-tutor-migration.sql`
4. `docs/mvp4-coding-lab-migration.sql`
5. `docs/mvp5-ml-course-migration.sql`

## 테스트 체크리스트

- [ ] `docs/mvp5-ml-course-migration.sql`이 오류 없이 실행된다.
- [ ] `modules`에 `Machine Learning`이 추가된다.
- [ ] `lessons`에 ML 7개 단원이 추가된다.
- [ ] `quizzes`와 `quiz_options`에 ML 퀴즈가 추가된다.
- [ ] `coding_tasks`에 ML 실습 과제가 추가된다.
- [ ] `ml_concept_map` 테이블과 데이터가 생성된다.
- [ ] 커리큘럼 화면에서 Machine Learning 모듈이 보인다.
- [ ] ML 단원 학습 페이지에서 개념, 예제, 요약, 퀴즈가 보인다.
- [ ] ML 퀴즈를 틀리면 기존 오답노트에 저장된다.
- [ ] `/ml-dashboard`에서 ML 오답노트가 별도로 필터링되어 표시된다.
- [ ] `/ml-dashboard`에서 ML 개념맵이 표시된다.
- [ ] `/ml-dashboard`에서 ML 실습 진행률이 표시된다.
- [ ] `/coding-lab`에서 ML 실습 과제가 보인다.
- [ ] ML 실습 제출 시 실제 코드는 실행되지 않고 예상 출력/키워드/패턴만 평가된다.
- [ ] 사용자별 ML 오답과 실습 제출 기록이 분리된다.
- [ ] `npm run typecheck`가 통과한다.
- [ ] `npm run build`가 통과한다.
