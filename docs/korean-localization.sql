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

-- Bilingual learning terms and assessment text.
-- Concept explanations stay Korean. Core terms are shown as Korean (English) for future English-source study.
update public.lessons as lesson
set title = terms.title
from (
  values
    ('python-variables', '변수 (variables)'),
    ('python-data-types', '자료형 (data types)'),
    ('python-conditionals', '조건문 (conditionals)'),
    ('python-loops', '반복문 (loops)'),
    ('python-functions', '함수 (functions)'),
    ('python-lists', '리스트 (lists)'),
    ('python-dictionaries', '딕셔너리 (dictionaries)'),
    ('python-file-io', '파일입출력 (file input/output)'),
    ('python-exceptions', '예외처리 (exception handling)'),
    ('data-numpy', 'NumPy (넘파이)'),
    ('data-pandas', 'Pandas (판다스)'),
    ('data-csv', 'CSV (comma-separated values)'),
    ('data-missing-values', '결측치 (missing values)'),
    ('data-visualization', '데이터 시각화 (data visualization)'),
    ('stats-mean', '평균 (mean)'),
    ('stats-variance', '분산 (variance)'),
    ('stats-standard-deviation', '표준편차 (standard deviation)'),
    ('stats-probability', '확률 (probability)'),
    ('stats-correlation', '상관관계 (correlation)'),
    ('ml-supervised-learning', '지도학습 (supervised learning)'),
    ('ml-unsupervised-learning', '비지도학습 (unsupervised learning)'),
    ('ml-regression', '회귀 (regression)'),
    ('ml-classification', '분류 (classification)'),
    ('ml-overfitting', '과적합 (overfitting)'),
    ('ml-metrics', '평가 지표 (evaluation metrics)'),
    ('ml-scikit-learn', 'Scikit-learn'),
    ('gcp-cloud-fundamentals', 'Cloud Fundamentals (클라우드 기본)'),
    ('gcp-iam', 'IAM (Identity and Access Management)'),
    ('gcp-storage', 'Storage (저장소)'),
    ('gcp-bigquery', 'BigQuery'),
    ('gcp-compute-engine', 'Compute Engine'),
    ('gcp-cloud-functions', 'Cloud Functions'),
    ('gcp-vertex-ai', 'Vertex AI'),
    ('gcp-automl', 'AutoML'),
    ('gcp-model-registry', 'Model Registry'),
    ('gcp-endpoints', 'Endpoints'),
    ('gcp-monitoring', 'Monitoring')
) as terms(slug, title)
where lesson.slug = terms.slug;

update public.quizzes as quiz
set question = texts.question,
    explanation = texts.explanation
from (
  values
    ('30000000-0000-4000-8000-000000000001', E'What does a variable do?\n해석: 변수는 어떤 역할을 하나요?', E'A variable stores a value with a name.\n해석: 변수는 값에 이름을 붙여 저장합니다.'),
    ('30000000-0000-4000-8000-000000000002', E'Which data type is used for text?\n해석: 문자 데이터를 나타내는 자료형은 무엇인가요?', E'Text values are strings, also called str in Python.\n해석: 문자 데이터는 string이며 Python에서는 str이라고 부릅니다.'),
    ('30000000-0000-4000-8000-000000000003', E'Which keyword starts a conditional?\n해석: 조건문을 시작할 때 사용하는 키워드는 무엇인가요?', E'if starts a conditional statement.\n해석: if는 조건문을 시작하는 키워드입니다.'),
    ('30000000-0000-4000-8000-000000000004', E'Why do we use a loop?\n해석: 반복문은 왜 사용하나요?', E'A loop repeats work without writing the same code many times.\n해석: 반복문은 같은 코드를 여러 번 쓰지 않고 작업을 반복하게 해 줍니다.'),
    ('31000000-0000-4000-8000-000000000001', E'What keyword creates a function?\n해석: 함수를 만들 때 사용하는 키워드는 무엇인가요?', E'def creates a Python function.\n해석: def는 Python 함수를 만드는 키워드입니다.'),
    ('31000000-0000-4000-8000-000000000002', E'Which method adds a value to the end of a list?\n해석: 리스트 끝에 값을 추가할 때 사용하는 메서드는 무엇인가요?', E'append adds a new value to the end of a list.\n해석: append는 리스트 끝에 새 값을 추가합니다.'),
    ('31000000-0000-4000-8000-000000000003', E'What structure uses key-value pairs?\n해석: key-value 쌍으로 데이터를 저장하는 구조는 무엇인가요?', E'A dictionary stores key-value pairs.\n해석: 딕셔너리는 key와 value를 짝으로 저장합니다.'),
    ('31000000-0000-4000-8000-000000000004', E'Which mode reads a file?\n해석: 파일을 읽기 모드로 열 때 사용하는 모드는 무엇인가요?', E'r is read mode.\n해석: r은 read 모드입니다.'),
    ('31000000-0000-4000-8000-000000000005', E'Which keyword handles an error from try?\n해석: try에서 발생한 에러를 처리하는 키워드는 무엇인가요?', E'except handles an error from try.\n해석: except는 try에서 발생한 에러를 처리합니다.'),
    ('32000000-0000-4000-8000-000000000001', E'What is NumPy mainly used for?\n해석: NumPy는 주로 무엇에 사용하나요?', E'NumPy is used for numeric array calculation.\n해석: NumPy는 숫자 배열 계산에 사용합니다.'),
    ('32000000-0000-4000-8000-000000000002', E'What does a Pandas DataFrame represent?\n해석: Pandas DataFrame은 무엇을 나타내나요?', E'A DataFrame represents table-shaped data.\n해석: DataFrame은 표 형태 데이터를 나타냅니다.'),
    ('32000000-0000-4000-8000-000000000003', E'Which Pandas function loads CSV files?\n해석: CSV 파일을 불러오는 Pandas 함수는 무엇인가요?', E'read_csv loads CSV files.\n해석: read_csv는 CSV 파일을 읽습니다.'),
    ('32000000-0000-4000-8000-000000000004', E'Which function finds missing values?\n해석: 결측치를 찾는 함수는 무엇인가요?', E'isna helps find missing values.\n해석: isna는 결측치를 찾는 데 사용합니다.'),
    ('32000000-0000-4000-8000-000000000005', E'Why do we visualize data?\n해석: 데이터를 시각화하는 이유는 무엇인가요?', E'Visualization helps us see patterns.\n해석: 시각화는 데이터의 패턴을 보기 쉽게 해 줍니다.'),
    ('33000000-0000-4000-8000-000000000001', E'What is the mean?\n해석: 평균은 무엇인가요?', E'The mean is the average.\n해석: 평균은 데이터의 합계를 개수로 나눈 대표값입니다.'),
    ('33000000-0000-4000-8000-000000000002', E'What does variance measure?\n해석: 분산은 무엇을 측정하나요?', E'Variance measures spread.\n해석: 분산은 값들이 평균에서 얼마나 퍼져 있는지 나타냅니다.'),
    ('33000000-0000-4000-8000-000000000003', E'What is standard deviation?\n해석: 표준편차는 무엇인가요?', E'Standard deviation is the square root of variance.\n해석: 표준편차는 분산의 제곱근입니다.'),
    ('33000000-0000-4000-8000-000000000004', E'What range can probability have?\n해석: 확률 값의 범위는 어디부터 어디까지인가요?', E'Probability ranges from 0 to 1.\n해석: 확률은 0부터 1 사이의 값입니다.'),
    ('33000000-0000-4000-8000-000000000005', E'Does correlation always mean causation?\n해석: 상관관계는 항상 인과관계를 뜻하나요?', E'No. Correlation does not automatically mean causation.\n해석: 아닙니다. 상관관계는 인과관계를 자동으로 의미하지 않습니다.'),
    ('34000000-0000-4000-8000-000000000001', E'What is the key trait of supervised learning?\n해석: 지도학습의 핵심 특징은 무엇인가요?', E'Supervised learning uses labeled examples.\n해석: 지도학습은 정답 라벨이 있는 예제로 학습합니다.'),
    ('34000000-0000-4000-8000-000000000002', E'What does unsupervised learning look for?\n해석: 비지도학습은 무엇을 찾나요?', E'It looks for patterns without labels.\n해석: 비지도학습은 라벨 없이 패턴이나 그룹을 찾습니다.'),
    ('34000000-0000-4000-8000-000000000003', E'What does regression predict?\n해석: 회귀는 무엇을 예측하나요?', E'Regression predicts continuous numeric values.\n해석: 회귀는 연속적인 숫자 값을 예측합니다.'),
    ('34000000-0000-4000-8000-000000000004', E'What does classification predict?\n해석: 분류는 무엇을 예측하나요?', E'Classification predicts categories or labels.\n해석: 분류는 범주나 라벨을 예측합니다.'),
    ('34000000-0000-4000-8000-000000000005', E'What is a sign of overfitting?\n해석: 과적합의 대표적인 신호는 무엇인가요?', E'High training score but low test score suggests overfitting.\n해석: 학습 점수는 높은데 테스트 점수가 낮으면 과적합을 의심합니다.'),
    ('34000000-0000-4000-8000-000000000006', E'Which metric is common for classification?\n해석: 분류 문제에서 자주 쓰는 평가 지표는 무엇인가요?', E'Accuracy is a common classification metric.\n해석: accuracy는 분류에서 자주 쓰는 기본 지표입니다.'),
    ('34000000-0000-4000-8000-000000000007', E'Which Scikit-learn method trains a model?\n해석: Scikit-learn에서 모델을 학습할 때 쓰는 메서드는 무엇인가요?', E'fit trains a model.\n해석: fit은 모델을 학습할 때 사용하는 대표 메서드입니다.'),
    ('35000000-0000-4000-8000-000000000001', E'What is the main container for GCP resources and billing?\n해석: GCP 리소스와 과금을 묶는 기본 단위는 무엇인가요?', E'A project is the main GCP container.\n해석: 프로젝트는 GCP 리소스, API, IAM, 과금을 묶는 기본 단위입니다.'),
    ('35000000-0000-4000-8000-000000000002', E'What are the key parts of IAM?\n해석: IAM을 구성하는 핵심 요소는 무엇인가요?', E'IAM connects member, role, and resource.\n해석: IAM은 member, role, resource의 관계로 이해합니다.'),
    ('35000000-0000-4000-8000-000000000003', E'What does Cloud Storage store inside buckets?\n해석: Cloud Storage bucket 안에는 무엇을 저장하나요?', E'Cloud Storage stores objects such as files, images, training data, and artifacts.\n해석: Cloud Storage는 파일, 이미지, 학습 데이터, 모델 artifact 같은 객체를 저장합니다.'),
    ('35000000-0000-4000-8000-000000000004', E'Which service is best for large-scale SQL analytics?\n해석: 대규모 SQL 분석에 적합한 서비스는 무엇인가요?', E'BigQuery is a serverless data warehouse built for large-scale SQL analytics.\n해석: BigQuery는 대규모 SQL 분석에 적합한 서버리스 데이터 웨어하우스입니다.'),
    ('35000000-0000-4000-8000-000000000005', E'Which service gives direct VM control?\n해석: VM을 직접 제어할 수 있는 서비스는 무엇인가요?', E'Compute Engine provides VM-level control.\n해석: Compute Engine은 VM을 직접 만들고 제어하는 서비스입니다.'),
    ('35000000-0000-4000-8000-000000000006', E'Which service is best for small event-driven functions?\n해석: 작은 이벤트 기반 함수를 실행하기 좋은 서비스는 무엇인가요?', E'Cloud Functions runs small code units in response to events.\n해석: Cloud Functions는 이벤트에 반응하는 작은 코드 실행에 적합합니다.'),
    ('35000000-0000-4000-8000-000000000007', E'Which Google Cloud platform manages ML training, deployment, prediction, and monitoring?\n해석: ML 학습, 배포, 예측, 모니터링을 관리하는 Google Cloud 플랫폼은 무엇인가요?', E'Vertex AI is Google Cloud''s unified ML platform.\n해석: Vertex AI는 Google Cloud의 통합 ML 플랫폼입니다.'),
    ('35000000-0000-4000-8000-000000000008', E'Which Vertex AI approach is useful for fast low-code model baselines?\n해석: 빠른 low-code baseline 모델에 유용한 Vertex AI 방식은 무엇인가요?', E'AutoML is useful for fast low-code training.\n해석: AutoML은 빠른 low-code 학습에 유용합니다.'),
    ('35000000-0000-4000-8000-000000000009', E'Which Vertex AI feature helps track model versions and deployment status?\n해석: 모델 버전과 배포 상태를 추적하는 기능은 무엇인가요?', E'Model Registry tracks model versions and deployment state.\n해석: Model Registry는 모델 버전과 배포 상태를 추적합니다.'),
    ('35000000-0000-4000-8000-000000000010', E'Which Vertex AI resource receives online prediction requests?\n해석: 온라인 예측 요청을 받는 Vertex AI 리소스는 무엇인가요?', E'An endpoint receives online prediction requests for deployed models.\n해석: Endpoint는 배포된 모델의 온라인 예측 요청을 받습니다.'),
    ('35000000-0000-4000-8000-000000000011', E'What helps check drift and service health after deployment?\n해석: 배포 후 drift와 서비스 상태를 확인하는 기능은 무엇인가요?', E'Model Monitoring checks drift, skew, latency, errors, and service health.\n해석: Model Monitoring은 drift, skew, latency, error 같은 운영 신호를 확인합니다.')
) as texts(id, question, explanation)
where quiz.id = texts.id::uuid;

update public.quiz_options as opt
set option_text = texts.option_text
from (
  values
    ('40000000-0000-4000-8000-000000000001', E'It stores a value with a name.\n해석: 값에 이름을 붙여 저장합니다.'),
    ('40000000-0000-4000-8000-000000000002', E'It deletes all code.\n해석: 모든 코드를 삭제합니다.'),
    ('40000000-0000-4000-8000-000000000003', E'It only changes colors.\n해석: 색만 바꿉니다.'),
    ('40000000-0000-4000-8000-000000000004', E'str\n해석: 문자열 자료형'),
    ('40000000-0000-4000-8000-000000000005', E'int\n해석: 정수 자료형'),
    ('40000000-0000-4000-8000-000000000006', E'bool\n해석: 참/거짓 자료형'),
    ('40000000-0000-4000-8000-000000000007', E'if\n해석: 조건문 시작 키워드'),
    ('40000000-0000-4000-8000-000000000008', E'repeat\n해석: 반복이라는 일반 단어이지만 Python 조건문 키워드는 아닙니다.'),
    ('40000000-0000-4000-8000-000000000009', E'folder\n해석: 폴더'),
    ('40000000-0000-4000-8000-000000000010', E'To repeat work.\n해석: 작업을 반복하기 위해 사용합니다.'),
    ('40000000-0000-4000-8000-000000000011', E'To stop the computer.\n해석: 컴퓨터를 멈추기 위해 사용합니다.'),
    ('40000000-0000-4000-8000-000000000012', E'To create an account.\n해석: 계정을 만들기 위해 사용합니다.'),
    ('41000000-0000-4000-8000-000000000001', E'def\n해석: 함수 정의 키워드'),
    ('41000000-0000-4000-8000-000000000002', E'make\n해석: 만든다는 일반 단어이지만 Python 함수 정의 키워드는 아닙니다.'),
    ('41000000-0000-4000-8000-000000000003', E'loop\n해석: 반복'),
    ('41000000-0000-4000-8000-000000000004', E'append\n해석: 리스트 끝에 값을 추가하는 메서드'),
    ('41000000-0000-4000-8000-000000000005', E'delete_all\n해석: 모든 것을 삭제한다는 의미의 예시 이름'),
    ('41000000-0000-4000-8000-000000000006', E'freeze\n해석: 멈추다/얼리다'),
    ('41000000-0000-4000-8000-000000000007', E'Dictionary\n해석: 딕셔너리'),
    ('41000000-0000-4000-8000-000000000008', E'String only\n해석: 문자열만'),
    ('41000000-0000-4000-8000-000000000009', E'Comment\n해석: 주석'),
    ('41000000-0000-4000-8000-000000000010', E'r\n해석: read 모드'),
    ('41000000-0000-4000-8000-000000000011', E'paint\n해석: 칠하다'),
    ('41000000-0000-4000-8000-000000000012', E'sleep\n해석: 잠자기/대기'),
    ('41000000-0000-4000-8000-000000000013', E'except\n해석: 예외 처리 키워드'),
    ('41000000-0000-4000-8000-000000000014', E'folder\n해석: 폴더'),
    ('41000000-0000-4000-8000-000000000015', E'chart\n해석: 차트'),
    ('42000000-0000-4000-8000-000000000001', E'Numeric array calculation\n해석: 숫자 배열 계산'),
    ('42000000-0000-4000-8000-000000000002', E'Email design only\n해석: 이메일 디자인만'),
    ('42000000-0000-4000-8000-000000000003', E'Password storage only\n해석: 비밀번호 저장만'),
    ('42000000-0000-4000-8000-000000000004', E'Table-shaped data\n해석: 표 형태 데이터'),
    ('42000000-0000-4000-8000-000000000005', E'Single password\n해석: 하나의 비밀번호'),
    ('42000000-0000-4000-8000-000000000006', E'Screen color\n해석: 화면 색상'),
    ('42000000-0000-4000-8000-000000000007', E'read_csv\n해석: CSV 파일 읽기 함수'),
    ('42000000-0000-4000-8000-000000000008', E'read_color\n해석: 색을 읽는다는 예시 이름'),
    ('42000000-0000-4000-8000-000000000009', E'open_account\n해석: 계정을 연다는 예시 이름'),
    ('42000000-0000-4000-8000-000000000010', E'isna\n해석: 결측치 여부 확인 함수'),
    ('42000000-0000-4000-8000-000000000011', E'paint\n해석: 칠하다'),
    ('42000000-0000-4000-8000-000000000012', E'deploy\n해석: 배포하다'),
    ('42000000-0000-4000-8000-000000000013', E'To see patterns\n해석: 패턴을 보기 위해'),
    ('42000000-0000-4000-8000-000000000014', E'To hide data\n해석: 데이터를 숨기기 위해'),
    ('42000000-0000-4000-8000-000000000015', E'To delete Python\n해석: Python을 삭제하기 위해'),
    ('43000000-0000-4000-8000-000000000001', E'Average\n해석: 평균'),
    ('43000000-0000-4000-8000-000000000002', E'Maximum only\n해석: 최댓값만'),
    ('43000000-0000-4000-8000-000000000003', E'File name\n해석: 파일 이름'),
    ('43000000-0000-4000-8000-000000000004', E'Spread\n해석: 퍼짐 정도'),
    ('43000000-0000-4000-8000-000000000005', E'Font size\n해석: 글자 크기'),
    ('43000000-0000-4000-8000-000000000006', E'Login time\n해석: 로그인 시간'),
    ('43000000-0000-4000-8000-000000000007', E'Square root of variance\n해석: 분산의 제곱근'),
    ('43000000-0000-4000-8000-000000000008', E'A list method\n해석: 리스트 메서드'),
    ('43000000-0000-4000-8000-000000000009', E'A file mode\n해석: 파일 모드'),
    ('43000000-0000-4000-8000-000000000010', E'0 to 1\n해석: 0부터 1까지'),
    ('43000000-0000-4000-8000-000000000011', E'10 to 20\n해석: 10부터 20까지'),
    ('43000000-0000-4000-8000-000000000012', E'Only negative values\n해석: 음수 값만'),
    ('43000000-0000-4000-8000-000000000013', E'No\n해석: 아니요'),
    ('43000000-0000-4000-8000-000000000014', E'Always yes\n해석: 항상 예'),
    ('43000000-0000-4000-8000-000000000015', E'Only in Python\n해석: Python에서만'),
    ('54000000-0000-4000-8000-000000000001', E'It has correct labels\n해석: 정답 라벨이 있습니다.'),
    ('54000000-0000-4000-8000-000000000002', E'It has no data\n해석: 데이터가 없습니다.'),
    ('54000000-0000-4000-8000-000000000003', E'It only changes colors\n해석: 색만 바꿉니다.'),
    ('54000000-0000-4000-8000-000000000004', E'Patterns without labels\n해석: 라벨 없이 패턴을 찾습니다.'),
    ('54000000-0000-4000-8000-000000000005', E'Only labeled answers\n해석: 라벨이 있는 정답만'),
    ('54000000-0000-4000-8000-000000000006', E'Only code length\n해석: 코드 길이만'),
    ('54000000-0000-4000-8000-000000000007', E'A number\n해석: 숫자'),
    ('54000000-0000-4000-8000-000000000008', E'A class label only\n해석: 클래스 라벨만'),
    ('54000000-0000-4000-8000-000000000009', E'A file name only\n해석: 파일 이름만'),
    ('54000000-0000-4000-8000-000000000010', E'A category\n해석: 범주'),
    ('54000000-0000-4000-8000-000000000011', E'A continuous price only\n해석: 연속적인 가격 값만'),
    ('54000000-0000-4000-8000-000000000012', E'A folder path\n해석: 폴더 경로'),
    ('54000000-0000-4000-8000-000000000013', E'High train score and low test score\n해석: 학습 점수는 높고 테스트 점수는 낮음'),
    ('54000000-0000-4000-8000-000000000014', E'Perfect generalization\n해석: 완벽한 일반화'),
    ('54000000-0000-4000-8000-000000000015', E'No training data\n해석: 학습 데이터 없음'),
    ('54000000-0000-4000-8000-000000000016', E'Accuracy\n해석: 정확도'),
    ('54000000-0000-4000-8000-000000000017', E'File size\n해석: 파일 크기'),
    ('54000000-0000-4000-8000-000000000018', E'Screen width\n해석: 화면 너비'),
    ('54000000-0000-4000-8000-000000000019', E'fit\n해석: 모델 학습 메서드'),
    ('54000000-0000-4000-8000-000000000020', E'paint\n해석: 칠하다'),
    ('54000000-0000-4000-8000-000000000021', E'rename\n해석: 이름 바꾸기'),
    ('55000000-0000-4000-8000-000000000001', E'Project\n해석: 프로젝트'),
    ('55000000-0000-4000-8000-000000000002', E'Training file\n해석: 학습 파일'),
    ('55000000-0000-4000-8000-000000000003', E'Model parameter\n해석: 모델 파라미터'),
    ('55000000-0000-4000-8000-000000000004', E'Service account\n해석: 서비스 계정'),
    ('55000000-0000-4000-8000-000000000005', E'CSV header\n해석: CSV 헤더'),
    ('55000000-0000-4000-8000-000000000006', E'Local variable\n해석: 로컬 변수'),
    ('55000000-0000-4000-8000-000000000007', E'Objects\n해석: 객체'),
    ('55000000-0000-4000-8000-000000000008', E'Endpoints only\n해석: Endpoint만'),
    ('55000000-0000-4000-8000-000000000009', E'IAM roles only\n해석: IAM 역할만'),
    ('55000000-0000-4000-8000-000000000010', E'BigQuery\n해석: BigQuery'),
    ('55000000-0000-4000-8000-000000000011', E'Cloud Functions\n해석: Cloud Functions'),
    ('55000000-0000-4000-8000-000000000012', E'IAM\n해석: IAM'),
    ('55000000-0000-4000-8000-000000000013', E'Compute Engine\n해석: Compute Engine'),
    ('55000000-0000-4000-8000-000000000014', E'Model Registry\n해석: Model Registry'),
    ('55000000-0000-4000-8000-000000000015', E'BigQuery ML\n해석: BigQuery ML'),
    ('55000000-0000-4000-8000-000000000016', E'Cloud Functions\n해석: Cloud Functions'),
    ('55000000-0000-4000-8000-000000000017', E'Cloud Storage bucket\n해석: Cloud Storage 버킷'),
    ('55000000-0000-4000-8000-000000000018', E'IAM role\n해석: IAM 역할'),
    ('55000000-0000-4000-8000-000000000019', E'Vertex AI\n해석: Vertex AI'),
    ('55000000-0000-4000-8000-000000000020', E'Cloud DNS\n해석: Cloud DNS'),
    ('55000000-0000-4000-8000-000000000021', E'Cloud Billing\n해석: Cloud Billing'),
    ('55000000-0000-4000-8000-000000000022', E'AutoML\n해석: AutoML'),
    ('55000000-0000-4000-8000-000000000023', E'Compute Engine only\n해석: Compute Engine만'),
    ('55000000-0000-4000-8000-000000000024', E'Cloud Logging\n해석: Cloud Logging'),
    ('55000000-0000-4000-8000-000000000025', E'Model Registry\n해석: Model Registry'),
    ('55000000-0000-4000-8000-000000000026', E'Cloud Shell\n해석: Cloud Shell'),
    ('55000000-0000-4000-8000-000000000027', E'VPC firewall\n해석: VPC 방화벽'),
    ('55000000-0000-4000-8000-000000000028', E'Endpoint\n해석: 온라인 예측 진입점'),
    ('55000000-0000-4000-8000-000000000029', E'Dataset\n해석: 데이터셋'),
    ('55000000-0000-4000-8000-000000000030', E'Bucket\n해석: 버킷'),
    ('55000000-0000-4000-8000-000000000031', E'Monitoring\n해석: 모니터링'),
    ('55000000-0000-4000-8000-000000000032', E'Label encoding\n해석: 라벨 인코딩'),
    ('55000000-0000-4000-8000-000000000033', E'One-hot encoding\n해석: 원-핫 인코딩')
) as texts(id, option_text)
where opt.id = texts.id::uuid;

update public.scenario_questions as scenario
set title = texts.title,
    scenario = texts.scenario,
    options = texts.options,
    explanation = texts.explanation,
    exam_point = texts.exam_point,
    practical_point = texts.practical_point
from (
  values
    (
      '82000000-0000-4000-8000-000000000001',
      E'Large tabular analytics\n해석: 대규모 표 데이터 분석',
      E'A team has millions of customer transaction rows and needs SQL analysis plus feature exploration before model training. Which service should they consider first?\n해석: 한 팀이 수백만 건의 고객 거래 행을 가지고 있고, 모델 학습 전에 SQL 분석과 feature exploration이 필요합니다. 가장 먼저 고려할 서비스는 무엇인가요?',
      jsonb_build_array(E'BigQuery\n해석: BigQuery', E'Cloud Functions\n해석: Cloud Functions', E'Compute Engine only\n해석: Compute Engine만'),
      E'BigQuery is the best first choice for large tabular SQL analysis and feature exploration.\n해석: BigQuery는 대규모 표 데이터 SQL 분석과 feature exploration에 가장 적합한 첫 선택입니다.',
      E'Choose the service based on data shape and access pattern.\n해석: 데이터 형태와 접근 패턴을 기준으로 서비스를 고릅니다.',
      E'Use partitioning and query scope controls to manage cost.\n해석: partitioning과 query 범위 제어로 비용을 관리합니다.'
    ),
    (
      '82000000-0000-4000-8000-000000000002',
      E'Fast baseline model\n해석: 빠른 baseline 모델',
      E'A small team has labeled tabular data and wants a fast baseline classifier without writing custom model training code. Which option fits best?\n해석: 작은 팀이 라벨이 있는 표 데이터를 가지고 있고 custom training code 없이 빠른 baseline 분류기를 원합니다. 어떤 선택지가 가장 적합한가요?',
      jsonb_build_array(E'Vertex AI AutoML\n해석: Vertex AI AutoML', E'Write every algorithm on a VM\n해석: 모든 알고리즘을 VM에서 직접 작성', E'Use Cloud Storage only\n해석: Cloud Storage만 사용'),
      E'Vertex AI AutoML is appropriate for a fast low-code baseline.\n해석: Vertex AI AutoML은 빠른 low-code baseline에 적합합니다.',
      E'AutoML is a key low-code solution choice.\n해석: AutoML은 low-code 솔루션 선택지로 중요합니다.',
      E'After the baseline, compare quality and decide whether custom training is needed.\n해석: baseline 이후 품질을 비교하고 custom training이 필요한지 결정합니다.'
    ),
    (
      '82000000-0000-4000-8000-000000000003',
      E'Online prediction service\n해석: 온라인 예측 서비스',
      E'A mobile app needs real-time prediction results from a deployed model. Which Vertex AI resource receives those requests?\n해석: 모바일 앱이 배포된 모델에서 실시간 예측 결과를 받아야 합니다. 어떤 Vertex AI 리소스가 요청을 받나요?',
      jsonb_build_array(E'Endpoint\n해석: 온라인 예측 진입점', E'Dataset only\n해석: Dataset만', E'Cloud Billing\n해석: Cloud Billing'),
      E'A Vertex AI endpoint receives online prediction requests for deployed models.\n해석: Vertex AI Endpoint는 배포된 모델의 온라인 예측 요청을 받습니다.',
      E'Distinguish online prediction from batch prediction.\n해석: online prediction과 batch prediction을 구분합니다.',
      E'Plan latency, autoscaling, traffic split, and access control.\n해석: 지연시간, autoscaling, traffic split, 접근 제어를 계획합니다.'
    ),
    (
      '82000000-0000-4000-8000-000000000004',
      E'Deployed model quality change\n해석: 배포된 모델 품질 변화',
      E'A model has been deployed for two weeks. Input data distribution appears to be changing and prediction quality may be falling. What should be used?\n해석: 모델이 배포된 지 2주가 되었고 입력 데이터 분포가 바뀌며 예측 품질이 떨어질 수 있습니다. 무엇을 사용해야 하나요?',
      jsonb_build_array(E'Model Monitoring\n해석: 모델 모니터링', E'Rename a bucket\n해석: bucket 이름 변경', E'Delete all IAM roles\n해석: 모든 IAM role 삭제'),
      E'Model monitoring helps detect drift, skew, and production quality risks.\n해석: Model Monitoring은 drift, skew, 운영 품질 위험을 감지하는 데 도움을 줍니다.',
      E'Production monitoring is an important PMLE topic.\n해석: 운영 모니터링은 PMLE의 중요한 주제입니다.',
      E'Define alert rules, review owners, and response processes.\n해석: alert 규칙, 검토 담당자, 대응 절차를 정의합니다.'
    ),
    (
      '82000000-0000-4000-8000-000000000005',
      E'Least privilege\n해석: 최소 권한',
      E'A training service account only needs to read training data and start Vertex AI training jobs. Which IAM principle matters most?\n해석: 학습용 service account는 학습 데이터를 읽고 Vertex AI training job을 시작하기만 하면 됩니다. 어떤 IAM 원칙이 가장 중요한가요?',
      jsonb_build_array(E'Grant only the required roles\n해석: 필요한 role만 부여', E'Give Owner to everyone\n해석: 모두에게 Owner 부여', E'Publish credentials publicly\n해석: 인증 정보를 공개 저장'),
      E'Least privilege means granting only the permissions needed for the task.\n해석: 최소 권한은 작업에 필요한 권한만 부여하는 원칙입니다.',
      E'IAM questions often test member, role, resource, and least privilege.\n해석: IAM 문제는 member, role, resource, least privilege를 자주 묻습니다.',
      E'Separate service account roles and review them regularly.\n해석: service account role을 분리하고 정기적으로 검토합니다.'
    )
) as texts(id, title, scenario, options, explanation, exam_point, practical_point)
where scenario.id = texts.id::uuid;

update public.mock_exam_questions as mockq
set question = texts.question,
    scenario = texts.scenario,
    options = texts.options,
    explanation = texts.explanation
from (
  values
    (
      '91000000-0000-4000-8000-000000000001',
      E'A business team wants a fast baseline image classifier with labeled examples and minimal code. What should be considered first?\n해석: 비즈니스 팀이 라벨이 있는 예시와 최소한의 코드로 빠른 baseline 이미지 분류기를 원합니다. 무엇을 먼저 고려해야 하나요?',
      E'The team has limited ML engineering support and needs a quick prototype before deciding whether to invest in custom training.\n해석: 팀은 ML 엔지니어링 지원이 제한적이고 custom training 투자 여부를 결정하기 전에 빠른 prototype이 필요합니다.',
      jsonb_build_array(E'Vertex AI AutoML\n해석: Vertex AI AutoML', E'Compute Engine only\n해석: Compute Engine만', E'Cloud Storage lifecycle rule\n해석: Cloud Storage lifecycle 규칙', E'Cloud DNS\n해석: Cloud DNS'),
      E'AutoML is a good first choice for fast low-code baselines when labeled data is available.\n해석: 라벨 데이터가 있으면 AutoML은 빠른 low-code baseline을 위한 좋은 첫 선택입니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000002',
      E'Which service is the best fit for large tabular SQL analytics before feature engineering?\n해석: feature engineering 전에 대규모 표 데이터 SQL 분석에 가장 적합한 서비스는 무엇인가요?',
      E'A dataset contains millions of customer transaction rows. Analysts need SQL queries and feature exploration.\n해석: 데이터셋에는 수백만 건의 고객 거래 행이 있고, 분석가는 SQL 쿼리와 feature exploration이 필요합니다.',
      jsonb_build_array(E'BigQuery\n해석: BigQuery', E'Cloud Functions\n해석: Cloud Functions', E'Vertex AI Endpoint\n해석: Vertex AI Endpoint', E'Cloud Monitoring\n해석: Cloud Monitoring'),
      E'BigQuery is designed for large-scale SQL analytics and is a common feature exploration choice.\n해석: BigQuery는 대규모 SQL 분석용으로 설계되었고 feature exploration에 자주 쓰입니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000003',
      E'A mobile app needs low-latency online predictions from a deployed model. Which Vertex AI resource should receive requests?\n해석: 모바일 앱이 배포된 모델에서 낮은 지연시간의 온라인 예측을 받아야 합니다. 어떤 Vertex AI 리소스가 요청을 받아야 하나요?',
      E'The app sends one user event at a time and expects a prediction immediately.\n해석: 앱은 한 번에 하나의 사용자 이벤트를 보내고 즉시 예측을 기대합니다.',
      jsonb_build_array(E'Endpoint\n해석: 온라인 예측 진입점', E'Dataset\n해석: 데이터셋', E'Model Registry only\n해석: Model Registry만', E'Cloud Billing\n해석: Cloud Billing'),
      E'Vertex AI endpoints receive online prediction requests for deployed models.\n해석: Vertex AI Endpoint는 배포된 모델의 온라인 예측 요청을 받습니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000004',
      E'A deployed model starts receiving input data with a distribution different from training data. What should help detect this?\n해석: 배포된 모델이 학습 데이터와 다른 분포의 입력 데이터를 받기 시작했습니다. 이를 감지하는 데 무엇이 도움이 되나요?',
      E'The operations team suspects production data drift after a marketing campaign changed user behavior.\n해석: 마케팅 캠페인으로 사용자 행동이 바뀐 뒤 운영팀은 production data drift를 의심하고 있습니다.',
      jsonb_build_array(E'Model monitoring\n해석: 모델 모니터링', E'Bucket rename\n해석: bucket 이름 변경', E'IAM delete all\n해석: 모든 IAM 삭제', E'Region list\n해석: 리전 목록'),
      E'Model monitoring can track drift, skew, and production quality risks.\n해석: Model Monitoring은 drift, skew, 운영 품질 위험을 추적할 수 있습니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000005',
      E'What is the safest IAM principle for a training service account?\n해석: 학습용 service account에 가장 안전한 IAM 원칙은 무엇인가요?',
      E'The service account needs to read one training bucket and start Vertex AI training jobs.\n해석: 이 service account는 하나의 학습 bucket을 읽고 Vertex AI training job을 시작해야 합니다.',
      jsonb_build_array(E'Grant only required roles\n해석: 필요한 role만 부여', E'Grant Owner to all users\n해석: 모든 사용자에게 Owner 부여', E'Store keys in public code\n해석: 키를 공개 코드에 저장', E'Disable authentication\n해석: 인증 비활성화'),
      E'Least privilege reduces risk by granting only the permissions required for the workload.\n해석: 최소 권한은 workload에 필요한 권한만 부여해 위험을 줄입니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000006',
      E'When is custom training more appropriate than AutoML?\n해석: AutoML보다 custom training이 더 적합한 경우는 언제인가요?',
      E'A team needs a special neural network architecture and custom loss function for research-grade model behavior.\n해석: 팀은 연구 수준의 모델 동작을 위해 특수한 neural network 구조와 custom loss function이 필요합니다.',
      jsonb_build_array(E'When model architecture control is required\n해석: 모델 아키텍처 제어가 필요할 때', E'When no code should ever be written\n해석: 코드를 절대 작성하면 안 될 때', E'When only DNS routing is needed\n해석: DNS routing만 필요할 때', E'When storing static images only\n해석: 정적 이미지만 저장할 때'),
      E'Custom training is appropriate when the scenario requires algorithm, architecture, or training-code control.\n해석: 알고리즘, 아키텍처, 학습 코드 제어가 필요하면 custom training이 적합합니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000007',
      E'Which Vertex AI feature helps track model versions and deployment status?\n해석: 모델 버전과 배포 상태 추적에 도움이 되는 Vertex AI 기능은 무엇인가요?',
      E'The team needs to know which model version is approved, deployed, and available for rollback.\n해석: 팀은 어떤 모델 버전이 승인되었고 배포되었으며 rollback 가능한지 알아야 합니다.',
      jsonb_build_array(E'Model Registry\n해석: Model Registry', E'Cloud DNS\n해석: Cloud DNS', E'Cloud Storage uniform bucket-level access only\n해석: Cloud Storage uniform bucket-level access만', E'Cloud Shell history\n해석: Cloud Shell 기록'),
      E'Model Registry supports model version tracking, metadata, deployment state, and governance.\n해석: Model Registry는 모델 버전 추적, 메타데이터, 배포 상태, 거버넌스를 지원합니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000008',
      E'Which deployment technique can gradually move online prediction traffic from an old model to a new model?\n해석: 온라인 예측 트래픽을 기존 모델에서 새 모델로 점진적으로 옮길 수 있는 배포 기법은 무엇인가요?',
      E'A team wants to reduce risk while validating a new model version in production.\n해석: 팀은 production에서 새 모델 버전을 검증하면서 위험을 줄이고 싶어 합니다.',
      jsonb_build_array(E'Traffic split on an endpoint\n해석: Endpoint의 traffic split', E'Delete the old model first\n해석: 기존 모델 먼저 삭제', E'Disable logs\n해석: 로그 비활성화', E'Use a billing export only\n해석: billing export만 사용'),
      E'Traffic splitting lets an endpoint route portions of prediction traffic to different deployed model versions.\n해석: traffic split은 Endpoint가 예측 트래픽 일부를 서로 다른 배포 모델 버전으로 보내게 합니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000009',
      E'A company has tabular data in BigQuery and wants SQL-based model training for a quick baseline. What should be considered?\n해석: 회사가 BigQuery에 표 데이터를 가지고 있고 빠른 baseline을 위해 SQL 기반 모델 학습을 원합니다. 무엇을 고려해야 하나요?',
      E'The data team is comfortable with SQL but has limited Python ML experience.\n해석: 데이터 팀은 SQL에는 익숙하지만 Python ML 경험은 제한적입니다.',
      jsonb_build_array(E'BigQuery ML\n해석: BigQuery ML', E'Cloud DNS\n해석: Cloud DNS', E'Cloud Armor only\n해석: Cloud Armor만', E'Manual VM patching\n해석: 수동 VM 패치'),
      E'BigQuery ML can train models using SQL when the data is already in BigQuery.\n해석: 데이터가 이미 BigQuery에 있으면 BigQuery ML로 SQL을 사용해 모델을 학습할 수 있습니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000010',
      E'Where are training files and model artifacts often stored for Vertex AI jobs?\n해석: Vertex AI 작업에서 학습 파일과 모델 artifact는 보통 어디에 저장하나요?',
      E'The workflow reads CSV files and writes exported model artifacts after training.\n해석: 이 workflow는 CSV 파일을 읽고 학습 후 export된 model artifact를 씁니다.',
      jsonb_build_array(E'Cloud Storage\n해석: Cloud Storage', E'Cloud DNS\n해석: Cloud DNS', E'Endpoint only\n해석: Endpoint만', E'IAM policy only\n해석: IAM policy만'),
      E'Cloud Storage is object storage commonly used for training data and model artifacts.\n해석: Cloud Storage는 학습 데이터와 모델 artifact에 자주 쓰이는 객체 저장소입니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000011',
      E'Which prediction pattern is better for scoring a large file of records overnight?\n해석: 대량 파일의 record를 밤새 scoring해야 할 때 더 적합한 예측 방식은 무엇인가요?',
      E'The business does not need immediate responses. It needs all predictions ready by morning.\n해석: 비즈니스는 즉시 응답이 필요하지 않고 아침까지 모든 예측 결과가 준비되면 됩니다.',
      jsonb_build_array(E'Batch prediction\n해석: batch prediction', E'Online endpoint request per record only\n해석: record마다 online endpoint 요청만 사용', E'Disable prediction\n해석: 예측 비활성화', E'Use Cloud DNS\n해석: Cloud DNS 사용'),
      E'Batch prediction is appropriate for asynchronous large-volume scoring when low-latency response is not required.\n해석: 낮은 지연시간 응답이 필요 없고 대량 scoring을 비동기로 처리할 때 batch prediction이 적합합니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000012',
      E'Which question should be answered before choosing an ML service?\n해석: ML 서비스를 선택하기 전에 먼저 답해야 할 질문은 무엇인가요?',
      E'A stakeholder asks for AI but has not described the data, target, latency, or business outcome.\n해석: 이해관계자가 AI를 요청했지만 데이터, 목표, 지연시간, 비즈니스 결과를 설명하지 않았습니다.',
      jsonb_build_array(E'What business problem and data type are involved?\n해석: 어떤 비즈니스 문제와 데이터 유형이 관련되어 있나요?', E'Which logo color is used?\n해석: 어떤 로고 색을 사용하나요?', E'How many DNS records exist?\n해석: DNS record가 몇 개인가요?', E'Can all permissions be public?\n해석: 모든 권한을 공개해도 되나요?'),
      E'Service choice starts with the problem, data type, target, latency, security, and operations requirements.\n해석: 서비스 선택은 문제, 데이터 유형, 목표, 지연시간, 보안, 운영 요구사항에서 시작합니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000013',
      E'Why is model lineage useful in production ML?\n해석: production ML에서 model lineage가 유용한 이유는 무엇인가요?',
      E'An incident happens and the team must identify the model version, training data, and deployment path.\n해석: 장애가 발생했고 팀은 모델 버전, 학습 데이터, 배포 경로를 확인해야 합니다.',
      jsonb_build_array(E'It supports traceability and rollback\n해석: 추적성과 rollback을 지원합니다.', E'It removes the need for monitoring\n해석: 모니터링 필요성을 없앱니다.', E'It makes all data public\n해석: 모든 데이터를 공개합니다.', E'It replaces IAM\n해석: IAM을 대체합니다.'),
      E'Lineage helps teams trace model versions, data, decisions, and rollback paths.\n해석: lineage는 모델 버전, 데이터, 의사결정, rollback 경로를 추적하는 데 도움을 줍니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000014',
      E'A production model has increasing latency and error rate. What should the team review first?\n해석: production 모델의 지연시간과 오류율이 증가하고 있습니다. 팀은 무엇을 먼저 검토해야 하나요?',
      E'Customers report slow predictions after traffic increases during a promotion.\n해석: 프로모션 중 트래픽이 증가한 뒤 고객들이 느린 예측을 보고합니다.',
      jsonb_build_array(E'Endpoint metrics, autoscaling, and logs\n해석: Endpoint metrics, autoscaling, logs', E'Only the bucket name\n해석: bucket 이름만', E'Only DNS comments\n해석: DNS comment만', E'Ignore monitoring until next month\n해석: 다음 달까지 모니터링 무시'),
      E'Operational metrics and logs help diagnose serving health, latency, errors, and scaling issues.\n해석: 운영 metrics와 logs는 serving 상태, 지연시간, 오류, scaling 문제를 진단하는 데 도움을 줍니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000015',
      E'What should be considered when choosing the region for data and training?\n해석: 데이터와 학습 리전을 선택할 때 무엇을 고려해야 하나요?',
      E'The organization has compliance requirements and users in a specific geographic area.\n해석: 조직에는 규정 준수 요구사항이 있고 사용자는 특정 지리적 지역에 있습니다.',
      jsonb_build_array(E'Latency, compliance, cost, and data location\n해석: 지연시간, 규정 준수, 비용, 데이터 위치', E'Only the project name length\n해석: 프로젝트 이름 길이만', E'Only UI color\n해석: UI 색상만', E'Whether the model name is short\n해석: 모델 이름이 짧은지 여부'),
      E'Region choice affects latency, compliance, cost, availability, and data residency.\n해석: 리전 선택은 지연시간, 규정 준수, 비용, 가용성, 데이터 위치 요건에 영향을 줍니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000016',
      E'Which option best describes Cloud Functions in an ML workflow?\n해석: ML workflow에서 Cloud Functions를 가장 잘 설명하는 선택지는 무엇인가요?',
      E'A file upload should trigger a small notification and metadata update.\n해석: 파일 업로드가 작은 알림과 메타데이터 업데이트를 트리거해야 합니다.',
      jsonb_build_array(E'Small event-driven automation\n해석: 작은 이벤트 기반 자동화', E'Full long-running GPU training\n해석: 긴 GPU 학습 전체', E'Model version registry\n해석: 모델 버전 registry', E'Online prediction endpoint\n해석: 온라인 예측 endpoint'),
      E'Cloud Functions is useful for small event-driven tasks, not long-running model training.\n해석: Cloud Functions는 긴 모델 학습이 아니라 작은 이벤트 기반 작업에 유용합니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000017',
      E'When might Compute Engine be chosen in an ML scenario?\n해석: ML 시나리오에서 Compute Engine을 선택할 수 있는 경우는 언제인가요?',
      E'A team needs direct VM control, a special GPU setup, and a custom runtime environment.\n해석: 팀은 직접적인 VM 제어, 특수 GPU 설정, custom runtime 환경이 필요합니다.',
      jsonb_build_array(E'When direct VM and environment control is required\n해석: 직접적인 VM과 환경 제어가 필요할 때', E'When only no-code training is allowed\n해석: no-code training만 허용될 때', E'When only SQL analytics is needed\n해석: SQL 분석만 필요할 때', E'When model drift must be monitored\n해석: model drift를 모니터링해야 할 때'),
      E'Compute Engine gives VM-level control but adds operational responsibility.\n해석: Compute Engine은 VM 수준 제어를 제공하지만 운영 책임도 증가합니다.'
    ),
    (
      '91000000-0000-4000-8000-000000000018',
      E'Which result suggests the model should be reviewed after deployment?\n해석: 배포 후 모델을 검토해야 함을 보여 주는 결과는 무엇인가요?',
      E'Monitoring shows that prediction input distribution is shifting and accuracy proxy metrics are declining.\n해석: Monitoring에서 예측 입력 분포가 바뀌고 accuracy proxy metric이 하락하고 있습니다.',
      jsonb_build_array(E'Data drift and quality degradation\n해석: 데이터 drift와 품질 저하', E'A new bucket label only\n해석: 새 bucket label만', E'A shorter project name\n해석: 더 짧은 프로젝트 이름', E'A disabled dashboard theme\n해석: 비활성화된 dashboard theme'),
      E'Drift and quality degradation indicate that production model behavior should be reviewed.\n해석: drift와 품질 저하는 production 모델 동작을 검토해야 한다는 신호입니다.'
    )
) as texts(id, question, scenario, options, explanation)
where mockq.id = texts.id::uuid;
