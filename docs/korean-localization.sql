-- PMLE Pathfinder Korean localization patch
-- Run this after docs/supabase-complete.sql if your seeded content appears in English.
-- Technical product names such as Python, NumPy, Pandas, GCP, Vertex AI, BigQuery, and Scikit-learn stay in English.

update public.modules
set title = 'Python 기초',
    description = $ko$프로그래밍이 처음인 학습자를 위한 Python 첫 단계입니다. 변수, 자료형, 조건문, 반복문을 익힙니다.$ko$
where id = '10000000-0000-4000-8000-000000000001';

update public.modules
set title = 'Python 심화',
    description = $ko$함수, 리스트, 딕셔너리, 파일입출력, 예외처리를 배워 작은 프로그램을 스스로 구성합니다.$ko$
where id = '10000000-0000-4000-8000-000000000002';

update public.modules
set title = '데이터 분석',
    description = $ko$NumPy, Pandas, CSV, 결측치, 데이터 시각화를 통해 머신러닝 전 데이터 다루기 기초를 익힙니다.$ko$
where id = '10000000-0000-4000-8000-000000000003';

update public.modules
set title = '통계',
    description = $ko$평균, 분산, 표준편차, 확률, 상관관계를 쉬운 예시로 익히고 ML 해석의 기초를 만듭니다.$ko$
where id = '10000000-0000-4000-8000-000000000004';

update public.modules
set description = $ko$지도학습, 비지도학습, 회귀, 분류, 과적합, 평가 지표, Scikit-learn을 PMLE 관점에서 학습합니다.$ko$
where id = '10000000-0000-4000-8000-000000000005';

update public.modules
set description = $ko$GCP 기본 서비스와 Vertex AI의 학습, 배포, 모니터링 흐름을 PMLE 시험과 실무 관점에서 익힙니다.$ko$
where id = '10000000-0000-4000-8000-000000000006';

update public.lessons
set title = '변수',
    objective = $ko$값에 이름을 붙여 다시 사용하는 방법을 배웁니다.$ko$,
    concept = $ko$변수는 값에 붙이는 이름표입니다. 예를 들어 goal이라는 이름표에 "AI Engineer"라는 값을 붙이면, 이후에는 goal이라고 부를 때마다 그 값을 다시 사용할 수 있습니다. 비전공자에게 변수는 "메모지 이름"처럼 이해하면 쉽습니다.$ko$,
    summary = $ko$- 변수는 값을 담는 이름입니다.
- = 는 오른쪽 값을 왼쪽 이름에 저장합니다.
- 좋은 변수명은 코드의 의미를 쉽게 보여줍니다.$ko$
where slug = 'python-variables';

update public.lessons
set title = '자료형',
    objective = $ko$문자, 숫자, 참/거짓처럼 값의 종류를 구분합니다.$ko$,
    concept = $ko$자료형은 Python이 값을 해석하는 방식입니다. 글자는 string, 정수는 integer, 소수는 float, 참/거짓은 boolean입니다. 같은 3이라도 숫자 3과 글자 "3"은 Python 입장에서 다르게 다룹니다.$ko$,
    summary = $ko$- str은 문자열입니다.
- int와 float는 숫자입니다.
- bool은 True 또는 False입니다.
- 자료형을 알면 에러를 줄일 수 있습니다.$ko$
where slug = 'python-data-types';

update public.lessons
set title = '조건문',
    objective = $ko$상황에 따라 다른 코드를 실행하는 방법을 배웁니다.$ko$,
    concept = $ko$조건문은 "만약 ~라면"이라는 판단입니다. 점수가 80점 이상이면 통과, 아니면 복습처럼 프로그램이 상황에 맞게 선택하도록 만듭니다. if, elif, else 순서로 조건을 확인합니다.$ko$,
    summary = $ko$- if는 첫 조건을 검사합니다.
- elif는 추가 조건을 검사합니다.
- else는 앞 조건이 모두 아닐 때 실행됩니다.$ko$
where slug = 'python-conditionals';

update public.lessons
set title = '반복문',
    objective = $ko$같은 작업을 여러 번 반복하는 방법을 배웁니다.$ko$,
    concept = $ko$반복문은 같은 일을 자동으로 여러 번 하게 해 줍니다. 리스트 안의 점수들을 하나씩 출력하거나, 여러 파일을 차례대로 처리할 때 사용합니다. for는 정해진 묶음을 순서대로 돌 때 자주 씁니다.$ko$,
    summary = $ko$- for는 여러 값을 하나씩 꺼냅니다.
- 반복문은 중복 코드를 줄입니다.
- 데이터 분석과 ML 코드에서 매우 자주 사용됩니다.$ko$
where slug = 'python-loops';

update public.lessons
set title = '함수',
    objective = $ko$반복되는 작업에 이름을 붙여 재사용합니다.$ko$,
    concept = $ko$함수는 작은 작업 단위입니다. 커피 머신 버튼처럼 입력을 넣으면 정해진 일을 하고 결과를 돌려줍니다. def로 함수를 만들고 return으로 결과를 내보냅니다.$ko$,
    summary = $ko$- def는 함수를 만듭니다.
- 매개변수는 함수에 넣는 값입니다.
- return은 결과를 돌려줍니다.$ko$
where slug = 'python-functions';

update public.lessons
set title = '리스트',
    objective = $ko$여러 값을 순서대로 저장하고 꺼내는 방법을 배웁니다.$ko$,
    concept = $ko$리스트는 여러 값을 한 줄로 묶어 둔 상자입니다. 점수 목록, 단어 목록, 파일 목록처럼 순서가 있는 데이터를 다룰 때 씁니다. 인덱스는 0부터 시작합니다.$ko$,
    summary = $ko$- 리스트는 여러 값을 저장합니다.
- 인덱스는 0부터 시작합니다.
- append로 값을 추가할 수 있습니다.$ko$
where slug = 'python-lists';

update public.lessons
set title = '딕셔너리',
    objective = $ko$key-value 구조로 의미 있는 데이터를 저장합니다.$ko$,
    concept = $ko$딕셔너리는 이름표와 값을 짝으로 저장합니다. 예를 들어 name은 "PMLE", hours는 7처럼 의미 있는 라벨로 값을 찾을 수 있습니다. JSON과 API 데이터를 이해할 때 매우 중요합니다.$ko$,
    summary = $ko$- 딕셔너리는 key와 value를 저장합니다.
- key로 value를 찾습니다.
- API와 설정 데이터에서 자주 보입니다.$ko$
where slug = 'python-dictionaries';

update public.lessons
set title = '파일입출력',
    objective = $ko$Python으로 파일을 읽고 쓰는 기본 흐름을 익힙니다.$ko$,
    concept = $ko$파일입출력은 프로그램 밖의 파일과 데이터를 주고받는 방법입니다. 학습 메모를 저장하거나 CSV를 읽는 작업의 기초입니다. with open 구문은 파일을 안전하게 열고 닫게 해 줍니다.$ko$,
    summary = $ko$- w는 쓰기 모드입니다.
- r은 읽기 모드입니다.
- with는 파일을 안전하게 닫아 줍니다.$ko$
where slug = 'python-file-io';

update public.lessons
set title = '예외처리',
    objective = $ko$에러가 나도 프로그램이 멈추지 않게 처리합니다.$ko$,
    concept = $ko$예외처리는 문제가 생길 수 있는 코드를 안전하게 감싸는 방법입니다. 사용자 입력, 파일 읽기, API 호출처럼 실패할 수 있는 작업에서 중요합니다. try에서 시도하고 except에서 문제를 처리합니다.$ko$,
    summary = $ko$- try는 위험할 수 있는 코드를 실행합니다.
- except는 에러가 났을 때 실행됩니다.
- 안정적인 프로그램을 만드는 기초입니다.$ko$
where slug = 'python-exceptions';

update public.lessons
set title = 'NumPy',
    objective = $ko$배열 기반 숫자 계산의 기본을 배웁니다.$ko$,
    concept = $ko$NumPy는 숫자 데이터를 빠르게 다루는 Python 라이브러리입니다. 머신러닝 데이터는 표나 배열 형태가 많기 때문에 NumPy 감각을 익히면 이후 모델 학습 코드를 이해하기 쉬워집니다.$ko$,
    summary = $ko$- NumPy는 숫자 배열 계산에 강합니다.
- 평균, 합계 같은 계산을 간단히 처리합니다.
- ML 데이터의 기본 형태를 이해하는 데 도움이 됩니다.$ko$
where slug = 'data-numpy';

update public.lessons
set title = 'Pandas',
    objective = $ko$표 형태의 데이터를 읽고 요약합니다.$ko$,
    concept = $ko$Pandas는 엑셀 표처럼 행과 열이 있는 데이터를 다루는 도구입니다. DataFrame은 데이터 분석에서 가장 자주 만나는 구조입니다. CSV를 읽고, 열을 선택하고, 요약 통계를 보는 데 사용합니다.$ko$,
    summary = $ko$- DataFrame은 표 형태 데이터입니다.
- head로 앞부분을 확인합니다.
- describe로 요약 통계를 볼 수 있습니다.$ko$
where slug = 'data-pandas';

update public.lessons
set title = 'CSV',
    objective = $ko$CSV 파일을 불러와 데이터 분석을 시작합니다.$ko$,
    concept = $ko$CSV는 쉼표로 구분된 텍스트 데이터 파일입니다. 데이터 분석과 머신러닝 예제에서 가장 흔히 쓰는 파일 형식 중 하나입니다. Pandas의 read_csv로 쉽게 불러올 수 있습니다.$ko$,
    summary = $ko$- CSV는 표 데이터를 저장하는 흔한 파일 형식입니다.
- read_csv로 파일을 읽습니다.
- head로 데이터가 잘 들어왔는지 확인합니다.$ko$
where slug = 'data-csv';

update public.lessons
set title = '결측치',
    objective = $ko$비어 있는 데이터를 찾고 처리합니다.$ko$,
    concept = $ko$결측치는 비어 있거나 알 수 없는 값입니다. 분석 전에 결측치를 지울지, 평균 같은 값으로 채울지, 원인을 더 확인할지 결정해야 합니다. 결측치를 무시하면 모델 품질이 나빠질 수 있습니다.$ko$,
    summary = $ko$- isna는 결측치를 찾습니다.
- fillna는 결측치를 채웁니다.
- 결측치 처리는 분석 전 필수 점검입니다.$ko$
where slug = 'data-missing-values';

update public.lessons
set title = '데이터 시각화',
    objective = $ko$차트로 데이터의 패턴을 확인합니다.$ko$,
    concept = $ko$시각화는 숫자 표만 볼 때 놓치기 쉬운 패턴, 추세, 이상치를 눈으로 확인하게 해 줍니다. 분석 결과를 다른 사람에게 설명할 때도 매우 중요합니다.$ko$,
    summary = $ko$- 선 그래프는 추세를 보기 좋습니다.
- 막대 그래프는 값을 비교하기 좋습니다.
- 시각화는 분석 결과 설명에 도움이 됩니다.$ko$
where slug = 'data-visualization';

update public.lessons
set title = '평균',
    objective = $ko$데이터의 대표값인 평균을 계산하고 해석합니다.$ko$,
    concept = $ko$평균은 모든 값을 더한 뒤 개수로 나눈 값입니다. 데이터의 중심을 빠르게 보여 주지만, 극단적으로 큰 값이나 작은 값에 영향을 받을 수 있습니다.$ko$,
    summary = $ko$- 평균은 합계를 개수로 나눈 값입니다.
- 데이터 중심을 빠르게 파악합니다.
- 이상치가 있으면 해석에 주의해야 합니다.$ko$
where slug = 'stats-mean';

update public.lessons
set title = '분산',
    objective = $ko$값들이 평균에서 얼마나 퍼져 있는지 이해합니다.$ko$,
    concept = $ko$분산은 값들이 평균에서 얼마나 떨어져 있는지를 나타냅니다. 분산이 크면 데이터가 넓게 퍼져 있고, 작으면 값들이 평균 주변에 모여 있다는 뜻입니다.$ko$,
    summary = $ko$- 분산은 퍼짐 정도를 나타냅니다.
- 값이 클수록 데이터가 더 흩어져 있습니다.
- 표준편차를 이해하는 기초입니다.$ko$
where slug = 'stats-variance';

update public.lessons
set title = '표준편차',
    objective = $ko$분산을 더 해석하기 쉬운 단위로 이해합니다.$ko$,
    concept = $ko$표준편차는 분산의 제곱근입니다. 원래 데이터와 비슷한 단위로 퍼짐 정도를 보여 주기 때문에 분산보다 직관적으로 해석하기 쉽습니다.$ko$,
    summary = $ko$- 표준편차는 분산의 제곱근입니다.
- 데이터가 평균 주변에 얼마나 퍼졌는지 보여 줍니다.
- 작을수록 값들이 평균에 가깝습니다.$ko$
where slug = 'stats-standard-deviation';

update public.lessons
set title = '확률',
    objective = $ko$어떤 일이 일어날 가능성을 숫자로 표현합니다.$ko$,
    concept = $ko$확률은 어떤 사건이 일어날 가능성을 0과 1 사이 숫자로 표현합니다. 분류 모델은 종종 "이 이메일이 스팸일 확률"처럼 확률 형태의 출력을 냅니다.$ko$,
    summary = $ko$- 확률은 0에서 1 사이 값입니다.
- 1에 가까울수록 일어날 가능성이 큽니다.
- 분류 모델 해석에 중요합니다.$ko$
where slug = 'stats-probability';

update public.lessons
set title = '상관관계',
    objective = $ko$두 변수가 함께 움직이는 정도를 이해합니다.$ko$,
    concept = $ko$상관관계는 두 변수가 함께 증가하거나 감소하는 경향을 나타냅니다. 양의 상관관계는 함께 증가하는 경향, 음의 상관관계는 한쪽이 증가할 때 다른 쪽이 감소하는 경향입니다. 단, 상관관계는 인과관계가 아닙니다.$ko$,
    summary = $ko$- 상관관계는 함께 움직이는 정도입니다.
- 양수는 같은 방향, 음수는 반대 방향입니다.
- 상관관계만으로 원인을 단정하면 안 됩니다.$ko$
where slug = 'stats-correlation';

update public.lessons
set title = '지도학습',
    objective = $ko$정답 라벨이 있는 데이터로 모델을 학습하는 방식을 이해합니다.$ko$,
    concept = $ko$지도학습은 입력과 정답을 함께 보여 주며 모델을 훈련하는 방식입니다. 예를 들어 집의 크기와 가격, 이메일 내용과 스팸 여부처럼 정답이 있는 예제로 학습합니다. 회귀와 분류가 대표적인 지도학습입니다.$ko$,
    summary = $ko$- 지도학습은 정답 라벨이 있습니다.
- 회귀는 숫자를 예측합니다.
- 분류는 범주를 예측합니다.$ko$
where slug = 'ml-supervised-learning';

update public.lessons
set title = '비지도학습',
    objective = $ko$정답 라벨 없이 데이터의 구조를 찾는 방식을 이해합니다.$ko$,
    concept = $ko$비지도학습은 정답 없이 데이터 안의 패턴이나 그룹을 찾습니다. 고객을 비슷한 행동별로 묶거나, 데이터의 숨은 구조를 탐색할 때 사용합니다.$ko$,
    summary = $ko$- 비지도학습은 정답 라벨이 없습니다.
- 군집화는 비슷한 데이터를 묶습니다.
- 탐색적 분석에 자주 사용됩니다.$ko$
where slug = 'ml-unsupervised-learning';

update public.lessons
set title = '회귀',
    objective = $ko$연속적인 숫자 값을 예측하는 문제를 이해합니다.$ko$,
    concept = $ko$회귀는 가격, 매출, 온도처럼 숫자를 예측하는 문제입니다. 답이 연속적인 숫자라면 회귀를 먼저 떠올리면 됩니다. 선형회귀는 가장 기본적인 회귀 모델입니다.$ko$,
    summary = $ko$- 회귀는 숫자를 예측합니다.
- MAE, RMSE 같은 오차 지표를 사용합니다.
- 선형회귀는 대표적인 첫 모델입니다.$ko$
where slug = 'ml-regression';

update public.lessons
set title = '분류',
    objective = $ko$정해진 범주나 라벨을 예측하는 문제를 이해합니다.$ko$,
    concept = $ko$분류는 스팸/정상, 합격/불합격, 고양이/강아지처럼 범주를 예측하는 문제입니다. 답이 이름표라면 분류 문제로 볼 수 있습니다.$ko$,
    summary = $ko$- 분류는 범주를 예측합니다.
- 정확도, 정밀도, 재현율, F1을 자주 봅니다.
- 확률 출력도 함께 해석할 수 있습니다.$ko$
where slug = 'ml-classification';

update public.lessons
set title = '과적합',
    objective = $ko$학습 데이터만 너무 잘 맞추는 위험을 이해합니다.$ko$,
    concept = $ko$과적합은 모델이 학습 데이터의 세부사항까지 외워서 새로운 데이터에는 약해지는 상태입니다. 시험 문제를 이해하지 않고 답안지만 외운 것과 비슷합니다. 검증 데이터로 과적합을 확인합니다.$ko$,
    summary = $ko$- 과적합은 학습 데이터에만 지나치게 잘 맞는 상태입니다.
- 검증/테스트 성능이 낮으면 의심합니다.
- 모델 단순화, 데이터 추가, 정규화가 도움이 됩니다.$ko$
where slug = 'ml-overfitting';

update public.lessons
set title = '평가 지표',
    objective = $ko$모델 성능을 문제 유형에 맞게 측정합니다.$ko$,
    concept = $ko$평가 지표는 모델이 얼마나 잘 작동하는지 보여 주는 점수판입니다. 회귀는 오차를 보고, 분류는 정확도, 정밀도, 재현율, F1 등을 봅니다. 문제 목적에 맞는 지표 선택이 중요합니다.$ko$,
    summary = $ko$- 회귀와 분류는 지표가 다릅니다.
- 정확도만으로 충분하지 않을 때가 많습니다.
- PMLE에서는 지표 선택 이유가 중요합니다.$ko$
where slug = 'ml-metrics';

update public.lessons
set title = 'Scikit-learn',
    objective = $ko$기본 ML 코드 흐름인 fit과 predict를 익힙니다.$ko$,
    concept = $ko$Scikit-learn은 Python의 대표적인 머신러닝 라이브러리입니다. 보통 데이터를 준비하고, 모델을 만들고, fit으로 학습하고, predict로 예측합니다. 이 흐름은 이후 Vertex AI 학습 개념과도 연결됩니다.$ko$,
    summary = $ko$- fit은 모델을 학습합니다.
- predict는 예측합니다.
- train/test split으로 성능을 확인합니다.$ko$
where slug = 'ml-scikit-learn';

update public.lessons
set title = 'Cloud Fundamentals',
    objective = $ko$GCP 프로젝트, 리전, 존, API, 비용의 기본 구조를 이해합니다.$ko$,
    concept = $ko$Google Cloud는 프로젝트를 중심으로 리소스를 관리합니다. 프로젝트는 IAM, API, 과금, 리소스를 묶는 큰 폴더입니다. 리전과 존은 리소스가 실행되는 위치를 정하며 지연시간, 가용성, 규정, 비용에 영향을 줍니다.$ko$,
    summary = $ko$- 프로젝트는 GCP 리소스의 기본 단위입니다.
- 리전과 존은 위치와 가용성에 영향을 줍니다.
- PMLE 문제에서는 비용, 보안, 운영 조건을 함께 봅니다.$ko$
where slug = 'gcp-cloud-fundamentals';

update public.lessons
set title = 'IAM',
    objective = $ko$누가 어떤 리소스에 어떤 권한을 갖는지 이해합니다.$ko$,
    concept = $ko$IAM은 member, role, resource의 관계입니다. member는 사용자나 서비스 계정, role은 권한 묶음, resource는 접근 대상입니다. PMLE에서는 최소 권한 원칙이 자주 등장합니다.$ko$,
    summary = $ko$- IAM은 member, role, resource로 이해합니다.
- 서비스 계정은 프로그램이 사용하는 신분입니다.
- 필요한 권한만 주는 최소 권한이 중요합니다.$ko$
where slug = 'gcp-iam';

update public.lessons
set title = 'Storage',
    objective = $ko$Cloud Storage를 데이터와 모델 산출물 저장소로 이해합니다.$ko$,
    concept = $ko$Cloud Storage는 파일을 bucket 안에 object로 저장합니다. CSV, 이미지, 학습 데이터, 모델 artifact 같은 파일 저장에 적합합니다. Vertex AI 학습 작업은 입력 데이터를 Cloud Storage에서 읽고 결과 artifact를 다시 저장하는 경우가 많습니다.$ko$,
    summary = $ko$- Cloud Storage는 객체 저장소입니다.
- 학습 데이터와 모델 artifact 저장에 자주 씁니다.
- 위치, 권한, lifecycle 설정을 함께 고려합니다.$ko$
where slug = 'gcp-storage';

update public.lessons
set title = 'BigQuery',
    objective = $ko$대규모 표 데이터 분석과 BigQuery ML 사용 상황을 이해합니다.$ko$,
    concept = $ko$BigQuery는 서버리스 데이터 웨어하우스입니다. SQL로 큰 표 데이터를 빠르게 분석하고, 피처 탐색이나 BigQuery ML 모델 학습에도 사용할 수 있습니다.$ko$,
    summary = $ko$- BigQuery는 대규모 SQL 분석에 적합합니다.
- BigQuery ML은 SQL 기반 모델 학습을 지원합니다.
- 파티셔닝과 클러스터링은 비용과 성능에 중요합니다.$ko$
where slug = 'gcp-bigquery';

update public.lessons
set title = 'Compute Engine',
    objective = $ko$직접 제어가 필요한 VM 사용 상황을 이해합니다.$ko$,
    concept = $ko$Compute Engine은 가상 머신입니다. 운영체제, 라이브러리, 실행 환경을 직접 통제해야 할 때 유용하지만 관리 책임도 커집니다. PMLE에서는 managed service와 VM 중 무엇이 더 적절한지 묻는 문제가 자주 나옵니다.$ko$,
    summary = $ko$- Compute Engine은 VM입니다.
- 통제력은 높지만 운영 부담도 큽니다.
- 관리형 서비스가 가능한지 먼저 검토합니다.$ko$
where slug = 'gcp-compute-engine';

update public.lessons
set title = 'Cloud Functions',
    objective = $ko$작은 이벤트 기반 자동화에 serverless 함수를 사용하는 상황을 이해합니다.$ko$,
    concept = $ko$Cloud Functions는 파일 업로드, 메시지, HTTP 요청 같은 이벤트에 반응해 작은 코드를 실행합니다. 긴 학습 작업보다는 알림, 메타데이터 업데이트, 간단한 glue logic에 적합합니다.$ko$,
    summary = $ko$- Cloud Functions는 작은 이벤트 기반 코드에 적합합니다.
- 긴 학습 작업에는 맞지 않습니다.
- 트리거와 권한 설정을 함께 봐야 합니다.$ko$
where slug = 'gcp-cloud-functions';

update public.lessons
set title = 'Vertex AI',
    objective = $ko$Google Cloud의 관리형 ML 플랫폼 역할을 이해합니다.$ko$,
    concept = $ko$Vertex AI는 데이터셋, 학습, 실험, 모델 등록, 배포, 예측, 모니터링을 연결하는 통합 ML 플랫폼입니다. PMLE에서는 언제 Vertex AI를 선택해야 하는지와 운영 흐름을 이해하는 것이 중요합니다.$ko$,
    summary = $ko$- Vertex AI는 ML 워크플로를 관리합니다.
- 학습부터 배포, 모니터링까지 연결합니다.
- PMLE의 핵심 서비스입니다.$ko$
where slug = 'gcp-vertex-ai';

update public.lessons
set title = 'AutoML',
    objective = $ko$빠른 low-code baseline 모델을 만드는 상황을 이해합니다.$ko$,
    concept = $ko$AutoML은 직접 알고리즘을 세세하게 구현하지 않고도 라벨이 있는 데이터로 빠르게 모델 baseline을 만들 수 있는 방식입니다. 빠른 검증에는 좋지만, 특수한 구조나 custom loss가 필요하면 custom training이 더 적합합니다.$ko$,
    summary = $ko$- AutoML은 빠른 baseline에 좋습니다.
- 라벨이 있는 데이터가 필요합니다.
- 완전한 제어가 필요하면 custom training을 고려합니다.$ko$
where slug = 'gcp-automl';

update public.lessons
set title = 'Model Registry',
    objective = $ko$모델 버전과 배포 상태를 추적하는 방법을 이해합니다.$ko$,
    concept = $ko$Model Registry는 모델 버전, 메타데이터, 배포 상태를 관리합니다. 승인, 롤백, 추적성 같은 MLOps 요구사항에서 중요합니다.$ko$,
    summary = $ko$- Model Registry는 모델 버전을 추적합니다.
- 배포 상태와 메타데이터 관리에 도움됩니다.
- 운영과 감사 요구사항에 중요합니다.$ko$
where slug = 'gcp-model-registry';

update public.lessons
set title = 'Endpoints',
    objective = $ko$배포된 모델의 온라인 예측 진입점을 이해합니다.$ko$,
    concept = $ko$Vertex AI Endpoint는 앱이 실시간 예측 요청을 보내는 온라인 진입점입니다. 낮은 지연시간, traffic split, autoscaling, 접근 제어를 함께 고려해야 합니다.$ko$,
    summary = $ko$- Endpoint는 온라인 예측 요청을 받습니다.
- 실시간 예측에는 Endpoint를 사용합니다.
- batch prediction과 구분해야 합니다.$ko$
where slug = 'gcp-endpoints';

update public.lessons
set title = 'Monitoring',
    objective = $ko$배포 후 모델과 서비스 상태를 감시하는 이유를 이해합니다.$ko$,
    concept = $ko$Monitoring은 모델이 배포된 뒤 입력 데이터 변화, 예측 품질, 지연시간, 오류, 확장 상태를 확인하는 운영 활동입니다. 학습 때 좋았던 모델도 실제 데이터가 바뀌면 성능이 떨어질 수 있습니다.$ko$,
    summary = $ko$- 모니터링은 배포 후 필수입니다.
- drift, skew, latency, error를 확인합니다.
- 알림 기준과 담당자를 미리 정해야 합니다.$ko$
where slug = 'gcp-monitoring';

update public.coding_tasks
set title = '목표 변수 출력하기',
    description = $ko$문자열 변수를 만들고 print로 출력합니다.$ko$,
    instructions = $ko$goal이라는 변수에 AI Engineer를 저장하고 print로 출력하세요. 예상 출력에는 화면에 보일 값만 적습니다.$ko$
where id = '60000000-0000-4000-8000-000000000001';

update public.coding_tasks
set title = '함수로 두 수 더하기',
    description = $ko$함수를 정의하고 return으로 결과를 돌려주는 연습입니다.$ko$,
    instructions = $ko$add 함수를 정의한 뒤 add(3, 5)의 결과를 print로 출력하세요.$ko$
where id = '60000000-0000-4000-8000-000000000002';

update public.coding_tasks
set title = '리스트 평균 계산하기',
    description = $ko$sum과 len을 사용해 평균을 계산합니다.$ko$,
    instructions = $ko$scores = [70, 80, 90]을 만들고 평균을 계산한 뒤 출력하세요.$ko$
where id = '60000000-0000-4000-8000-000000000003';

update public.coding_tasks
set title = '회귀 입력과 라벨 만들기',
    description = $ko$지도학습 회귀 문제에서 X와 y를 구성하는 연습입니다.$ko$,
    instructions = $ko$X를 [[1], [2], [3]]으로, y를 [60, 75, 90]으로 만들고 labels: 와 y를 함께 출력하세요.$ko$
where id = '61000000-0000-4000-8000-000000000001';

update public.coding_tasks
set title = 'fit과 predict 흐름 쓰기',
    description = $ko$실제 실행 없이 Scikit-learn의 기본 용어를 연습합니다.$ko$,
    instructions = $ko$fit과 predict가 들어간 간단한 흐름 문자열을 만들고 workflow를 출력하세요.$ko$
where id = '61000000-0000-4000-8000-000000000002';

update public.ml_concept_map
set source_concept = '지도학습',
    target_concept = '회귀',
    relation = '포함',
    description = $ko$회귀는 숫자 예측을 위한 대표적인 지도학습 문제입니다.$ko$
where id = '70000000-0000-4000-8000-000000000001';

update public.ml_concept_map
set source_concept = '지도학습',
    target_concept = '분류',
    relation = '포함',
    description = $ko$분류는 범주 예측을 위한 대표적인 지도학습 문제입니다.$ko$
where id = '70000000-0000-4000-8000-000000000002';

update public.ml_concept_map
set source_concept = '과적합',
    target_concept = '평가 지표',
    relation = '탐지',
    description = $ko$검증 또는 테스트 데이터의 평가 지표는 과적합을 발견하는 데 도움을 줍니다.$ko$
where id = '70000000-0000-4000-8000-000000000003';

update public.mock_exams
set title = 'PMLE 준비도 미니 모의고사',
    description = $ko$GCP, Vertex AI, 모델 서빙, 모니터링, 관리형 ML 선택 시나리오를 제한 시간 안에 연습합니다.$ko$
where id = '90000000-0000-4000-8000-000000000001';

update public.exam_domains
set description = $ko$비즈니스 목표, 데이터 형태, 관리형 서비스 선택 기준을 연결해 판단합니다.$ko$,
    exam_points = array['AutoML, BigQuery ML, ML API, custom training 중 적절한 선택지를 고릅니다', '데이터 형태와 비즈니스 목표를 먼저 확인합니다'],
    practical_points = array['빠른 baseline이 필요한지, 완전한 제어가 필요한지 구분합니다', '서비스 선택 이유를 설명할 수 있어야 합니다']
where id = '80000000-0000-4000-8000-000000000001';

update public.exam_domains
set description = $ko$데이터 저장, 피처 탐색, 모델 버전 관리, 배포 준비 흐름을 이해합니다.$ko$,
    exam_points = array['Cloud Storage와 BigQuery 사용 상황을 구분합니다', 'Model Registry가 모델 버전 추적에 쓰임을 이해합니다'],
    practical_points = array['데이터 위치, 권한, 비용, 성능을 함께 설계합니다', '모델 승인, 롤백, 추적성을 운영 관점에서 봅니다']
where id = '80000000-0000-4000-8000-000000000002';

update public.exam_domains
set description = $ko$온라인 예측, batch prediction, 모니터링, drift 대응을 PMLE 시나리오로 판단합니다.$ko$,
    exam_points = array['Endpoint와 batch prediction을 구분합니다', '모니터링은 배포 후 운영의 핵심입니다'],
    practical_points = array['지연시간, 처리량, 비용, 운영 책임을 함께 고려합니다', '알림 기준과 대응 절차를 미리 정합니다']
where id = '80000000-0000-4000-8000-000000000003';

update public.service_comparisons
set category = 'Storage',
    best_for = $ko$파일, 이미지, 학습 데이터, 모델 artifact 저장$ko$,
    avoid_when = $ko$SQL 분석이 주된 목표일 때$ko$,
    exam_point = $ko$객체 저장소와 분석 저장소를 구분합니다.$ko$,
    practical_point = $ko$bucket IAM, 리전, lifecycle, naming을 신중히 설계합니다.$ko$
where id = '81000000-0000-4000-8000-000000000001';

update public.service_comparisons
set category = 'Analytics',
    best_for = $ko$대규모 표 데이터 분석, 피처 탐색, BigQuery ML$ko$,
    avoid_when = $ko$단순 파일 저장이 주된 목표일 때$ko$,
    exam_point = $ko$분석과 feature engineering 시나리오에서 자주 선택됩니다.$ko$,
    practical_point = $ko$파티셔닝과 클러스터링으로 성능과 비용을 관리합니다.$ko$
where id = '81000000-0000-4000-8000-000000000002';

update public.service_comparisons
set category = 'ML Training',
    best_for = $ko$라벨 데이터로 빠른 low-code baseline 모델 만들기$ko$,
    avoid_when = $ko$알고리즘이나 아키텍처를 완전히 제어해야 할 때$ko$,
    exam_point = $ko$빠른 관리형 AI 솔루션 선택지로 자주 등장합니다.$ko$,
    practical_point = $ko$baseline 품질을 확인한 뒤 custom training 필요성을 비교합니다.$ko$
where id = '81000000-0000-4000-8000-000000000005';

update public.service_comparisons
set category = 'MLOps',
    best_for = $ko$모델 버전, 메타데이터, 배포 상태 추적$ko$,
    avoid_when = $ko$단순한 로컬 실험만 필요한 경우$ko$,
    exam_point = $ko$모델 거버넌스와 버전 추적 시나리오에서 중요합니다.$ko$,
    practical_point = $ko$승인, 롤백, 추적성을 지원하는 데 사용합니다.$ko$
where id = '81000000-0000-4000-8000-000000000006';

update public.service_comparisons
set category = 'Serving',
    best_for = $ko$온라인 예측, traffic split, autoscaling$ko$,
    avoid_when = $ko$대량 파일을 밤새 비동기로 scoring하는 것이 목표일 때$ko$,
    exam_point = $ko$온라인 예측과 batch prediction을 구분합니다.$ko$,
    practical_point = $ko$지연시간, 확장, 트래픽 라우팅, 접근 제어를 설계합니다.$ko$
where id = '81000000-0000-4000-8000-000000000007';

update public.service_comparisons
set category = 'Operations',
    best_for = $ko$drift, skew, 예측 품질, 서비스 상태 모니터링$ko$,
    avoid_when = $ko$모델이 아직 배포되지 않은 경우$ko$,
    exam_point = $ko$배포 후 모니터링은 PMLE 시나리오의 핵심입니다.$ko$,
    practical_point = $ko$운영 전 alert 기준과 담당자를 정합니다.$ko$
where id = '81000000-0000-4000-8000-000000000008';

update public.quizzes
set question = case id
  when '30000000-0000-4000-8000-000000000001' then $ko$변수를 만들 때 사용하는 기호는 무엇인가요?$ko$
  when '30000000-0000-4000-8000-000000000002' then $ko$문자 데이터를 나타내는 자료형은 무엇인가요?$ko$
  when '30000000-0000-4000-8000-000000000003' then $ko$조건문을 시작할 때 사용하는 키워드는 무엇인가요?$ko$
  when '30000000-0000-4000-8000-000000000004' then $ko$리스트의 값을 하나씩 꺼낼 때 자주 사용하는 반복문은 무엇인가요?$ko$
  else question
end,
explanation = case id
  when '30000000-0000-4000-8000-000000000001' then $ko$= 기호는 오른쪽 값을 왼쪽 변수명에 저장합니다.$ko$
  when '30000000-0000-4000-8000-000000000002' then $ko$문자 데이터는 string이며 Python에서는 str이라고 부릅니다.$ko$
  when '30000000-0000-4000-8000-000000000003' then $ko$if는 조건문을 시작하는 키워드입니다.$ko$
  when '30000000-0000-4000-8000-000000000004' then $ko$for 반복문은 리스트 같은 묶음에서 값을 하나씩 꺼낼 때 자주 씁니다.$ko$
  else explanation
end
where id in (
  '30000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000002',
  '30000000-0000-4000-8000-000000000003',
  '30000000-0000-4000-8000-000000000004'
);

update public.quizzes
set question = case id
  when '31000000-0000-4000-8000-000000000001' then $ko$함수를 만들 때 사용하는 키워드는 무엇인가요?$ko$
  when '31000000-0000-4000-8000-000000000002' then $ko$리스트 끝에 값을 추가할 때 자주 쓰는 메서드는 무엇인가요?$ko$
  when '31000000-0000-4000-8000-000000000003' then $ko$key-value 쌍으로 데이터를 저장하는 구조는 무엇인가요?$ko$
  when '31000000-0000-4000-8000-000000000004' then $ko$파일을 읽기 모드로 열 때 사용하는 모드는 무엇인가요?$ko$
  when '31000000-0000-4000-8000-000000000005' then $ko$try에서 에러가 발생했을 때 처리하는 키워드는 무엇인가요?$ko$
  when '32000000-0000-4000-8000-000000000001' then $ko$NumPy에서 배열을 만들 때 자주 쓰는 함수는 무엇인가요?$ko$
  when '32000000-0000-4000-8000-000000000002' then $ko$Pandas에서 표 형태 데이터를 대표하는 구조는 무엇인가요?$ko$
  when '32000000-0000-4000-8000-000000000003' then $ko$CSV 파일을 불러오는 Pandas 함수는 무엇인가요?$ko$
  when '32000000-0000-4000-8000-000000000004' then $ko$결측치를 찾는 데 쓰는 함수는 무엇인가요?$ko$
  when '32000000-0000-4000-8000-000000000005' then $ko$값의 변화를 선으로 보여 주는 차트는 무엇인가요?$ko$
  when '33000000-0000-4000-8000-000000000001' then $ko$평균은 어떻게 계산하나요?$ko$
  when '33000000-0000-4000-8000-000000000002' then $ko$분산은 무엇을 측정하나요?$ko$
  when '33000000-0000-4000-8000-000000000003' then $ko$표준편차는 무엇의 제곱근인가요?$ko$
  when '33000000-0000-4000-8000-000000000004' then $ko$확률 값의 범위는 어디부터 어디까지인가요?$ko$
  when '33000000-0000-4000-8000-000000000005' then $ko$상관관계 해석에서 주의할 점은 무엇인가요?$ko$
  else question
end,
explanation = case id
  when '31000000-0000-4000-8000-000000000001' then $ko$def는 Python 함수를 만드는 키워드입니다.$ko$
  when '31000000-0000-4000-8000-000000000002' then $ko$append는 리스트 끝에 새 값을 추가합니다.$ko$
  when '31000000-0000-4000-8000-000000000003' then $ko$딕셔너리는 key와 value를 짝으로 저장합니다.$ko$
  when '31000000-0000-4000-8000-000000000004' then $ko$r은 read 모드입니다.$ko$
  when '31000000-0000-4000-8000-000000000005' then $ko$except는 try에서 발생한 에러를 처리합니다.$ko$
  when '32000000-0000-4000-8000-000000000001' then $ko$np.array는 NumPy 배열을 만들 때 사용합니다.$ko$
  when '32000000-0000-4000-8000-000000000002' then $ko$DataFrame은 Pandas의 대표적인 표 형태 데이터 구조입니다.$ko$
  when '32000000-0000-4000-8000-000000000003' then $ko$read_csv는 CSV 파일을 읽습니다.$ko$
  when '32000000-0000-4000-8000-000000000004' then $ko$isna는 결측치를 찾는 데 사용합니다.$ko$
  when '32000000-0000-4000-8000-000000000005' then $ko$line chart는 시간 흐름이나 순서에 따른 변화를 보기 좋습니다.$ko$
  when '33000000-0000-4000-8000-000000000001' then $ko$평균은 합계를 데이터 개수로 나누어 계산합니다.$ko$
  when '33000000-0000-4000-8000-000000000002' then $ko$분산은 데이터가 평균에서 얼마나 퍼져 있는지 나타냅니다.$ko$
  when '33000000-0000-4000-8000-000000000003' then $ko$표준편차는 분산의 제곱근입니다.$ko$
  when '33000000-0000-4000-8000-000000000004' then $ko$확률은 0부터 1 사이의 값입니다.$ko$
  when '33000000-0000-4000-8000-000000000005' then $ko$상관관계는 인과관계를 자동으로 의미하지 않습니다.$ko$
  else explanation
end
where id::text like '31000000-%'
   or id::text like '32000000-%'
   or id::text like '33000000-%';

update public.quizzes
set question = case id
  when '34000000-0000-4000-8000-000000000001' then $ko$지도학습의 핵심 특징은 무엇인가요?$ko$
  when '34000000-0000-4000-8000-000000000002' then $ko$비지도학습은 무엇을 찾나요?$ko$
  when '34000000-0000-4000-8000-000000000003' then $ko$회귀는 어떤 값을 예측하나요?$ko$
  when '34000000-0000-4000-8000-000000000004' then $ko$분류는 무엇을 예측하나요?$ko$
  when '34000000-0000-4000-8000-000000000005' then $ko$과적합의 대표적인 신호는 무엇인가요?$ko$
  when '34000000-0000-4000-8000-000000000006' then $ko$분류 문제에서 자주 쓰는 평가 지표는 무엇인가요?$ko$
  when '34000000-0000-4000-8000-000000000007' then $ko$Scikit-learn에서 모델을 학습할 때 자주 쓰는 메서드는 무엇인가요?$ko$
  else question
end,
explanation = case id
  when '34000000-0000-4000-8000-000000000001' then $ko$지도학습은 정답 라벨이 있는 예제로 학습합니다.$ko$
  when '34000000-0000-4000-8000-000000000002' then $ko$비지도학습은 라벨 없이 패턴이나 그룹을 찾습니다.$ko$
  when '34000000-0000-4000-8000-000000000003' then $ko$회귀는 연속적인 숫자 값을 예측합니다.$ko$
  when '34000000-0000-4000-8000-000000000004' then $ko$분류는 범주나 라벨을 예측합니다.$ko$
  when '34000000-0000-4000-8000-000000000005' then $ko$학습 점수는 높은데 테스트 점수가 낮으면 과적합을 의심합니다.$ko$
  when '34000000-0000-4000-8000-000000000006' then $ko$accuracy는 분류에서 자주 쓰는 기본 지표입니다.$ko$
  when '34000000-0000-4000-8000-000000000007' then $ko$fit은 모델을 학습할 때 사용하는 대표 메서드입니다.$ko$
  else explanation
end
where id::text like '34000000-%';

update public.quizzes
set question = case id
  when '35000000-0000-4000-8000-000000000001' then $ko$GCP에서 리소스와 과금을 묶는 기본 단위는 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000002' then $ko$IAM을 구성하는 핵심 요소 조합은 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000003' then $ko$Cloud Storage bucket 안에는 무엇을 저장하나요?$ko$
  when '35000000-0000-4000-8000-000000000004' then $ko$대규모 SQL 분석에 가장 적합한 서비스는 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000005' then $ko$직접 제어가 필요한 VM 서비스는 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000006' then $ko$작은 이벤트 기반 함수를 실행하기 좋은 서비스는 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000007' then $ko$ML 학습, 배포, 예측, 모니터링을 관리하는 Google Cloud 플랫폼은 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000008' then $ko$빠른 low-code baseline 모델에 유용한 Vertex AI 방식은 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000009' then $ko$모델 버전과 배포 상태를 추적하는 기능은 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000010' then $ko$온라인 예측 요청을 받는 Vertex AI 리소스는 무엇인가요?$ko$
  when '35000000-0000-4000-8000-000000000011' then $ko$배포 후 drift와 서비스 상태를 확인하는 기능은 무엇인가요?$ko$
  else question
end,
explanation = case id
  when '35000000-0000-4000-8000-000000000001' then $ko$프로젝트는 GCP 리소스, API, IAM, 과금을 묶는 기본 단위입니다.$ko$
  when '35000000-0000-4000-8000-000000000002' then $ko$IAM은 member, role, resource의 관계로 이해합니다.$ko$
  when '35000000-0000-4000-8000-000000000003' then $ko$Cloud Storage는 파일, 이미지, 학습 데이터, 모델 artifact 같은 객체를 저장합니다.$ko$
  when '35000000-0000-4000-8000-000000000004' then $ko$BigQuery는 대규모 SQL 분석에 적합한 서버리스 데이터 웨어하우스입니다.$ko$
  when '35000000-0000-4000-8000-000000000005' then $ko$Compute Engine은 VM을 직접 만들고 제어하는 서비스입니다.$ko$
  when '35000000-0000-4000-8000-000000000006' then $ko$Cloud Functions는 이벤트에 반응하는 작은 코드 실행에 적합합니다.$ko$
  when '35000000-0000-4000-8000-000000000007' then $ko$Vertex AI는 Google Cloud의 통합 ML 플랫폼입니다.$ko$
  when '35000000-0000-4000-8000-000000000008' then $ko$AutoML은 빠른 low-code 학습에 유용합니다.$ko$
  when '35000000-0000-4000-8000-000000000009' then $ko$Model Registry는 모델 버전과 배포 상태를 추적합니다.$ko$
  when '35000000-0000-4000-8000-000000000010' then $ko$Endpoint는 배포된 모델의 온라인 예측 요청을 받습니다.$ko$
  when '35000000-0000-4000-8000-000000000011' then $ko$Model Monitoring은 drift, skew, latency, error 같은 운영 신호를 확인합니다.$ko$
  else explanation
end
where id::text like '35000000-%';
