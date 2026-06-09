-- PMLE Pathfinder MVP5 Machine Learning course migration
-- Apply after MVP1-MVP4 migrations.

create table if not exists public.ml_concept_map (
  id uuid primary key default gen_random_uuid(),
  source_concept text not null,
  target_concept text not null,
  relation text not null,
  description text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.ml_concept_map enable row level security;

drop policy if exists "ml concept map read authenticated" on public.ml_concept_map;
create policy "ml concept map read authenticated" on public.ml_concept_map
for select to authenticated using (true);

insert into public.modules (id, title, description, sort_order)
values
  (
    '10000000-0000-4000-8000-000000000005',
    'Machine Learning',
    'Learn supervised learning, unsupervised learning, regression, classification, overfitting, metrics, and Scikit-learn.',
    5
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    sort_order = excluded.sort_order;

insert into public.lessons (id, module_id, slug, title, objective, concept, example_code, summary, sort_order)
values
  (
    '24000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000005',
    'ml-supervised-learning',
    'Supervised Learning',
    'Learn how models train from labeled examples.',
    $concept$Supervised learning uses examples that include both input data and the correct answer. The model learns a rule that maps inputs to labels.

Common supervised learning tasks include regression and classification.$concept$,
    $code$X = [[1], [2], [3]]
y = [60, 75, 90]

print("inputs:", X)
print("labels:", y)$code$,
    $summary$- Supervised learning uses labeled data.
- Regression predicts numbers.
- Classification predicts categories.$summary$,
    20
  ),
  (
    '24000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000005',
    'ml-unsupervised-learning',
    'Unsupervised Learning',
    'Find patterns without labeled answers.',
    $concept$Unsupervised learning works with input data only. It tries to discover structure, groups, or patterns without a correct label.

Clustering customers by behavior is a common example.$concept$,
    $code$X = [[1, 2], [1, 3], [9, 8]]

print("find patterns from data")$code$,
    $summary$- Unsupervised learning has no labels.
- Clustering and dimensionality reduction are common examples.
- It is useful for pattern discovery.$summary$,
    21
  ),
  (
    '24000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000005',
    'ml-regression',
    'Regression',
    'Predict continuous numeric values.',
    $concept$Regression predicts numbers. Examples include predicting a test score, house price, sales amount, or delivery time.

If the answer is a continuous number, think regression.$concept$,
    $code$from sklearn.linear_model import LinearRegression

X = [[1], [2], [3]]
y = [60, 75, 90]

model = LinearRegression()
model.fit(X, y)
print(model.predict([[4]]))$code$,
    $summary$- Regression predicts numeric values.
- Linear regression is a common first model.
- The prediction is continuous.$summary$,
    22
  ),
  (
    '24000000-0000-4000-8000-000000000004',
    '10000000-0000-4000-8000-000000000005',
    'ml-classification',
    'Classification',
    'Predict categories or labels.',
    $concept$Classification predicts a category. Examples include spam or not spam, pass or fail, churn or stay, and dog or cat.

If the answer is a label, think classification.$concept$,
    $code$from sklearn.tree import DecisionTreeClassifier

X = [[1], [2], [8], [9]]
y = ["low", "low", "high", "high"]

model = DecisionTreeClassifier()
model.fit(X, y)
print(model.predict([[7]]))$code$,
    $summary$- Classification predicts labels.
- Output is a class or category.
- Accuracy is a common metric.$summary$,
    23
  ),
  (
    '24000000-0000-4000-8000-000000000005',
    '10000000-0000-4000-8000-000000000005',
    'ml-overfitting',
    'Overfitting',
    'Understand when a model memorizes training data too closely.',
    $concept$Overfitting happens when a model performs well on training data but poorly on new data. It is like memorizing practice questions instead of learning the concept.

Validation data helps detect overfitting.$concept$,
    $code$train_score = 0.99
test_score = 0.62

if train_score > 0.95 and test_score < 0.7:
    print("overfitting risk")$code$,
    $summary$- Overfitting means training performance is misleadingly high.
- Poor test performance is a warning sign.
- Validation helps control it.$summary$,
    24
  ),
  (
    '24000000-0000-4000-8000-000000000006',
    '10000000-0000-4000-8000-000000000005',
    'ml-metrics',
    'Evaluation Metrics',
    'Measure model performance based on the problem type.',
    $concept$Evaluation metrics show how well a model works. Regression uses error metrics such as MAE or RMSE. Classification uses metrics such as accuracy, precision, recall, and F1.

Choose a metric that matches the business goal.$concept$,
    $code$from sklearn.metrics import accuracy_score

y_true = [1, 0, 1, 1]
y_pred = [1, 0, 0, 1]

print(accuracy_score(y_true, y_pred))$code$,
    $summary$- Metrics measure performance.
- Regression and classification use different metrics.
- Business goals should guide metric choice.$summary$,
    25
  ),
  (
    '24000000-0000-4000-8000-000000000007',
    '10000000-0000-4000-8000-000000000005',
    'ml-scikit-learn',
    'Scikit-learn',
    'Practice the basic ML workflow in Python.',
    $concept$Scikit-learn is a Python library for machine learning practice. The common workflow is prepare data, split train/test data, create a model, fit it, predict, and evaluate.

This workflow helps connect coding practice with PMLE concepts.$concept$,
    $code$from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

X_train, X_test, y_train, y_test = train_test_split(X, y)
model = LinearRegression()
model.fit(X_train, y_train)
predictions = model.predict(X_test)$code$,
    $summary$- fit trains the model.
- predict creates predictions.
- train/test split checks generalization.$summary$,
    26
  )
on conflict (id) do update
set module_id = excluded.module_id,
    slug = excluded.slug,
    title = excluded.title,
    objective = excluded.objective,
    concept = excluded.concept,
    example_code = excluded.example_code,
    summary = excluded.summary,
    sort_order = excluded.sort_order;

insert into public.quizzes (id, lesson_id, question, explanation, sort_order)
values
  ('34000000-0000-4000-8000-000000000001', '24000000-0000-4000-8000-000000000001', 'What is the key trait of supervised learning?', 'Supervised learning uses labeled examples.', 1),
  ('34000000-0000-4000-8000-000000000002', '24000000-0000-4000-8000-000000000002', 'What does unsupervised learning look for?', 'It looks for patterns without labels.', 1),
  ('34000000-0000-4000-8000-000000000003', '24000000-0000-4000-8000-000000000003', 'What does regression predict?', 'Regression predicts continuous numeric values.', 1),
  ('34000000-0000-4000-8000-000000000004', '24000000-0000-4000-8000-000000000004', 'What does classification predict?', 'Classification predicts categories or labels.', 1),
  ('34000000-0000-4000-8000-000000000005', '24000000-0000-4000-8000-000000000005', 'What is a sign of overfitting?', 'High training score but low test score suggests overfitting.', 1),
  ('34000000-0000-4000-8000-000000000006', '24000000-0000-4000-8000-000000000006', 'Which metric is common for classification?', 'Accuracy is a common classification metric.', 1),
  ('34000000-0000-4000-8000-000000000007', '24000000-0000-4000-8000-000000000007', 'Which Scikit-learn method trains a model?', 'fit trains the model on data.', 1)
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    question = excluded.question,
    explanation = excluded.explanation,
    sort_order = excluded.sort_order;

insert into public.quiz_options (id, quiz_id, option_text, is_correct, sort_order)
values
  ('54000000-0000-4000-8000-000000000001', '34000000-0000-4000-8000-000000000001', 'It has correct labels', true, 1),
  ('54000000-0000-4000-8000-000000000002', '34000000-0000-4000-8000-000000000001', 'It has no data', false, 2),
  ('54000000-0000-4000-8000-000000000003', '34000000-0000-4000-8000-000000000001', 'It only changes colors', false, 3),
  ('54000000-0000-4000-8000-000000000004', '34000000-0000-4000-8000-000000000002', 'Patterns without labels', true, 1),
  ('54000000-0000-4000-8000-000000000005', '34000000-0000-4000-8000-000000000002', 'Only labeled answers', false, 2),
  ('54000000-0000-4000-8000-000000000006', '34000000-0000-4000-8000-000000000002', 'Only code length', false, 3),
  ('54000000-0000-4000-8000-000000000007', '34000000-0000-4000-8000-000000000003', 'A number', true, 1),
  ('54000000-0000-4000-8000-000000000008', '34000000-0000-4000-8000-000000000003', 'A class label only', false, 2),
  ('54000000-0000-4000-8000-000000000009', '34000000-0000-4000-8000-000000000003', 'A file name only', false, 3),
  ('54000000-0000-4000-8000-000000000010', '34000000-0000-4000-8000-000000000004', 'A category', true, 1),
  ('54000000-0000-4000-8000-000000000011', '34000000-0000-4000-8000-000000000004', 'A continuous price only', false, 2),
  ('54000000-0000-4000-8000-000000000012', '34000000-0000-4000-8000-000000000004', 'A folder path', false, 3),
  ('54000000-0000-4000-8000-000000000013', '34000000-0000-4000-8000-000000000005', 'High train score and low test score', true, 1),
  ('54000000-0000-4000-8000-000000000014', '34000000-0000-4000-8000-000000000005', 'Perfect generalization', false, 2),
  ('54000000-0000-4000-8000-000000000015', '34000000-0000-4000-8000-000000000005', 'No training data', false, 3),
  ('54000000-0000-4000-8000-000000000016', '34000000-0000-4000-8000-000000000006', 'Accuracy', true, 1),
  ('54000000-0000-4000-8000-000000000017', '34000000-0000-4000-8000-000000000006', 'File size', false, 2),
  ('54000000-0000-4000-8000-000000000018', '34000000-0000-4000-8000-000000000006', 'Screen width', false, 3),
  ('54000000-0000-4000-8000-000000000019', '34000000-0000-4000-8000-000000000007', 'fit', true, 1),
  ('54000000-0000-4000-8000-000000000020', '34000000-0000-4000-8000-000000000007', 'paint', false, 2),
  ('54000000-0000-4000-8000-000000000021', '34000000-0000-4000-8000-000000000007', 'rename', false, 3)
on conflict (id) do update
set quiz_id = excluded.quiz_id,
    option_text = excluded.option_text,
    is_correct = excluded.is_correct,
    sort_order = excluded.sort_order;

insert into public.coding_tasks (
  id,
  lesson_id,
  title,
  description,
  instructions,
  starter_code,
  expected_output,
  required_keywords,
  solution_pattern,
  difficulty,
  sort_order
)
values
  (
    '61000000-0000-4000-8000-000000000001',
    '24000000-0000-4000-8000-000000000003',
    'Create regression inputs and labels',
    'Practice building X and y for a supervised regression problem.',
    'Create X as [[1], [2], [3]] and y as [60, 75, 90]. Print labels: and y.',
    'X = []\ny = []\n\nprint("labels:", y)',
    'labels: [60, 75, 90]',
    array['X', 'y', 'print'],
    'X\\s*=\\s*\\[\\s*\\[\\s*1\\s*\\]\\s*,\\s*\\[\\s*2\\s*\\]\\s*,\\s*\\[\\s*3\\s*\\]\\s*\\].*y\\s*=\\s*\\[\\s*60\\s*,\\s*75\\s*,\\s*90\\s*\\].*print\\s*\\(\\s*["'']labels:["'']\\s*,\\s*y\\s*\\)',
    'easy',
    40
  ),
  (
    '61000000-0000-4000-8000-000000000002',
    '24000000-0000-4000-8000-000000000007',
    'Use fit and predict names',
    'Practice the basic Scikit-learn vocabulary without executing code.',
    'Write simple placeholder lines that mention fit and predict, then print workflow.',
    'workflow = ""\nprint(workflow)',
    'fit predict',
    array['fit', 'predict', 'print'],
    'fit.*predict.*print|predict.*fit.*print',
    'medium',
    41
  )
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    title = excluded.title,
    description = excluded.description,
    instructions = excluded.instructions,
    starter_code = excluded.starter_code,
    expected_output = excluded.expected_output,
    required_keywords = excluded.required_keywords,
    solution_pattern = excluded.solution_pattern,
    difficulty = excluded.difficulty,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.ml_concept_map (id, source_concept, target_concept, relation, description, sort_order)
values
  ('70000000-0000-4000-8000-000000000001', 'Supervised Learning', 'Regression', 'includes', 'Regression is a supervised learning task for numeric prediction.', 1),
  ('70000000-0000-4000-8000-000000000002', 'Supervised Learning', 'Classification', 'includes', 'Classification is a supervised learning task for category prediction.', 2),
  ('70000000-0000-4000-8000-000000000003', 'Overfitting', 'Evaluation Metrics', 'detected by', 'Metrics on validation or test data help reveal overfitting.', 3),
  ('70000000-0000-4000-8000-000000000004', 'Scikit-learn', 'Machine Learning Workflow', 'implements', 'Scikit-learn uses fit, predict, and evaluate as a common workflow.', 4)
on conflict (id) do update
set source_concept = excluded.source_concept,
    target_concept = excluded.target_concept,
    relation = excluded.relation,
    description = excluded.description,
    sort_order = excluded.sort_order;
