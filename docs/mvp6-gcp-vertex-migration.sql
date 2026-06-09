-- PMLE Pathfinder MVP6 GCP + Vertex AI course migration
-- Apply after MVP1-MVP5 migrations.

create table if not exists public.exam_domains (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  weight_percent integer,
  exam_points text[] not null default '{}',
  practical_points text[] not null default '{}',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.service_comparisons (
  id uuid primary key default gen_random_uuid(),
  service_name text not null,
  category text not null,
  best_for text not null default '',
  avoid_when text not null default '',
  exam_point text not null default '',
  practical_point text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.scenario_questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid references public.lessons(id) on delete set null,
  title text not null,
  scenario text not null,
  options jsonb not null default '[]'::jsonb,
  correct_option_index integer not null default 0,
  explanation text not null default '',
  exam_point text not null default '',
  practical_point text not null default '',
  difficulty text not null default 'medium' check (difficulty in ('easy', 'medium', 'hard')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.exam_domains enable row level security;
alter table public.service_comparisons enable row level security;
alter table public.scenario_questions enable row level security;

drop policy if exists "exam domains read authenticated" on public.exam_domains;
create policy "exam domains read authenticated" on public.exam_domains
for select to authenticated using (true);

drop policy if exists "service comparisons read authenticated" on public.service_comparisons;
create policy "service comparisons read authenticated" on public.service_comparisons
for select to authenticated using (true);

drop policy if exists "scenario questions read authenticated" on public.scenario_questions;
create policy "scenario questions read authenticated" on public.scenario_questions
for select to authenticated using (true);

insert into public.modules (id, title, description, sort_order)
values
  (
    '10000000-0000-4000-8000-000000000006',
    'GCP + Vertex AI',
    'Learn the Google Cloud and Vertex AI foundations needed for PMLE: cloud basics, IAM, storage, analytics, compute, serverless, model training, registry, endpoints, and monitoring.',
    6
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    sort_order = excluded.sort_order;

insert into public.lessons (id, module_id, slug, title, objective, concept, example_code, summary, sort_order)
values
  (
    '25000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000006',
    'gcp-cloud-fundamentals',
    'Cloud Fundamentals',
    'Understand projects, regions, APIs, billing, and the basic Google Cloud resource model.',
    $concept$Google Cloud organizes work around projects. A project is the main container for resources, IAM, APIs, and billing. Regions and zones decide where resources run, which affects latency, availability, compliance, and cost.

For PMLE scenarios, first identify the business goal, data location, latency target, security requirement, and whether a managed service can reduce operational work.$concept$,
    $code$gcloud projects list
gcloud config set project my-project
gcloud services enable aiplatform.googleapis.com$code$,
    $summary$- Projects are the basic management and billing unit.
- APIs must be enabled before services can be used.
- Region choice affects latency, cost, security, and availability.$summary$,
    30
  ),
  (
    '25000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000006',
    'gcp-iam',
    'IAM',
    'Control who can access which Google Cloud resources and what they can do.',
    $concept$IAM connects members, roles, and resources. A member can be a user, group, or service account. A role is a set of permissions. A resource is the thing being accessed.

For ML systems, service accounts are often the identity used by training jobs, pipelines, and deployed services. The safest default is least privilege: grant only the roles needed for the task.$concept$,
    $code$gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:trainer@my-project.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"$code$,
    $summary$- IAM is built from member, role, and resource.
- Service accounts are identities for applications and workloads.
- Least privilege is a common exam and production requirement.$summary$,
    31
  ),
  (
    '25000000-0000-4000-8000-000000000003',
    '10000000-0000-4000-8000-000000000006',
    'gcp-storage',
    'Storage',
    'Use Cloud Storage as a data and model artifact store.',
    $concept$Cloud Storage stores objects inside buckets. It is a good fit for files such as CSVs, images, training data, model artifacts, and exported assets.

Vertex AI jobs often read input data from Cloud Storage and write model artifacts back to Cloud Storage.$concept$,
    $code$gsutil mb gs://my-ml-bucket
gsutil cp data.csv gs://my-ml-bucket/data/data.csv$code$,
    $summary$- Cloud Storage is object storage.
- Bucket names must be globally unique.
- It is often used for training data and model artifacts.$summary$,
    32
  ),
  (
    '25000000-0000-4000-8000-000000000004',
    '10000000-0000-4000-8000-000000000006',
    'gcp-bigquery',
    'BigQuery',
    'Analyze large tabular datasets and understand when BigQuery ML is useful.',
    $concept$BigQuery is a serverless data warehouse for large-scale SQL analytics. It is useful when data is already tabular and the team needs fast analysis, feature exploration, or SQL-based machine learning through BigQuery ML.

PMLE questions often ask whether a workload is analytics-first, storage-first, or model-serving-first.$concept$,
    $code$SELECT
  AVG(score) AS avg_score
FROM `project.dataset.training_data`;$code$,
    $summary$- BigQuery is best for large-scale SQL analytics.
- BigQuery ML supports SQL-based model training.
- It is useful for feature exploration and data preparation.$summary$,
    33
  ),
  (
    '25000000-0000-4000-8000-000000000005',
    '10000000-0000-4000-8000-000000000006',
    'gcp-compute-engine',
    'Compute Engine',
    'Recognize when a managed VM is appropriate for ML work.',
    $concept$Compute Engine provides virtual machines. It gives deep control over OS, machine type, GPUs, disks, and networking, but it also adds operational responsibility.

For PMLE, Compute Engine can be correct when the scenario requires custom infrastructure, special GPU setup, or direct VM control. It is usually not the first choice for managed ML workflows.$concept$,
    $code$gcloud compute instances create ml-vm \
  --machine-type=n1-standard-4 \
  --zone=us-central1-a$code$,
    $summary$- Compute Engine is VM-based compute.
- It gives control but increases operations work.
- Consider it for special environments or GPU experiments.$summary$,
    34
  ),
  (
    '25000000-0000-4000-8000-000000000006',
    '10000000-0000-4000-8000-000000000006',
    'gcp-cloud-functions',
    'Cloud Functions',
    'Use serverless functions for small event-driven automation.',
    $concept$Cloud Functions runs small pieces of code in response to events such as file uploads, messages, or HTTP requests. It is useful for glue logic and lightweight automation.

For ML, Cloud Functions can trigger a workflow or process a small event. It is not a good fit for long-running training jobs.$concept$,
    $code$def hello_gcs(event, context):
    print("file uploaded:", event["name"])$code$,
    $summary$- Cloud Functions is event-driven serverless compute.
- It is useful for small automation tasks.
- It is not ideal for heavy training workloads.$summary$,
    35
  ),
  (
    '25000000-0000-4000-8000-000000000007',
    '10000000-0000-4000-8000-000000000006',
    'gcp-vertex-ai',
    'Vertex AI',
    'Understand Vertex AI as Google Cloud''s managed ML platform.',
    $concept$Vertex AI is Google Cloud's unified ML platform. It connects datasets, training, experiments, model registry, deployment, prediction, and monitoring.

For PMLE, you must compare AutoML, custom training, endpoints, batch prediction, model registry, and monitoring based on business requirements.$concept$,
    $code$from google.cloud import aiplatform

aiplatform.init(project="my-project", location="us-central1")$code$,
    $summary$- Vertex AI manages the ML workflow.
- It supports AutoML and custom training.
- It connects model deployment and monitoring.$summary$,
    36
  ),
  (
    '25000000-0000-4000-8000-000000000008',
    '10000000-0000-4000-8000-000000000006',
    'gcp-automl',
    'AutoML',
    'Choose AutoML when a fast low-code model baseline is appropriate.',
    $concept$AutoML trains models with less manual model design. It is useful when the learner or team has labeled data and needs a fast baseline for tabular, image, text, or similar tasks.

If the scenario needs deep algorithm control, special training code, or custom architecture, custom training is usually a better fit.$concept$,
    $code$training_method = "AutoML"
print(training_method)$code$,
    $summary$- AutoML is a low-code training approach.
- It is useful for fast baselines.
- Use custom training when model control matters.$summary$,
    37
  ),
  (
    '25000000-0000-4000-8000-000000000009',
    '10000000-0000-4000-8000-000000000006',
    'gcp-model-registry',
    'Model Registry',
    'Track model versions, metadata, and deployment status.',
    $concept$Model Registry is the place to register and manage models. It helps teams compare model versions, track metadata, and connect model governance to deployment.

In production, it matters who trained a model, what data was used, what version is deployed, and how rollback will work.$concept$,
    $code$model_name = "churn-model"
version = "v1"
print(model_name, version)$code$,
    $summary$- Model Registry manages model versions.
- It supports traceability and deployment governance.
- It is important for MLOps and rollback planning.$summary$,
    38
  ),
  (
    '25000000-0000-4000-8000-000000000010',
    '10000000-0000-4000-8000-000000000006',
    'gcp-endpoints',
    'Endpoints',
    'Serve online predictions from deployed Vertex AI models.',
    $concept$A Vertex AI endpoint is the online entry point for prediction requests. Applications send inputs to the endpoint and receive prediction results.

PMLE scenarios may ask about online prediction, batch prediction, autoscaling, traffic split, public access, private access, and latency requirements.$concept$,
    $code$endpoint = "projects/.../locations/us-central1/endpoints/123"
print("send prediction request to", endpoint)$code$,
    $summary$- Endpoints serve online predictions.
- Traffic split can route traffic across model versions.
- Latency, scaling, and security must be considered.$summary$,
    39
  ),
  (
    '25000000-0000-4000-8000-000000000011',
    '10000000-0000-4000-8000-000000000006',
    'gcp-monitoring',
    'Monitoring',
    'Monitor model and service health after deployment.',
    $concept$Monitoring checks whether the deployed model and service are still healthy. It can include latency, error rates, prediction volume, data drift, skew, and alerts.

Operational ML is not finished at deployment. A production model needs feedback loops, alerts, and review processes.$concept$,
    $code$metrics = ["latency", "errors", "drift"]
for metric in metrics:
    print("monitor", metric)$code$,
    $summary$- Monitoring tracks service and model health.
- Drift and skew are ML-specific risks.
- Alerts and review processes are part of MLOps.$summary$,
    40
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
  ('35000000-0000-4000-8000-000000000001', '25000000-0000-4000-8000-000000000001', 'What is the main container for Google Cloud resources and billing?', 'A project is the main resource and billing container in Google Cloud.', 1),
  ('35000000-0000-4000-8000-000000000002', '25000000-0000-4000-8000-000000000002', 'Which identity type is commonly used by workloads and training jobs?', 'Service accounts are identities for applications and workloads.', 1),
  ('35000000-0000-4000-8000-000000000003', '25000000-0000-4000-8000-000000000003', 'What does Cloud Storage store inside buckets?', 'Cloud Storage stores objects such as files, images, training data, and artifacts.', 1),
  ('35000000-0000-4000-8000-000000000004', '25000000-0000-4000-8000-000000000004', 'Which service is best for large-scale SQL analytics?', 'BigQuery is a serverless data warehouse built for large-scale SQL analytics.', 1),
  ('35000000-0000-4000-8000-000000000005', '25000000-0000-4000-8000-000000000005', 'Which service provides managed virtual machines?', 'Compute Engine provides virtual machines.', 1),
  ('35000000-0000-4000-8000-000000000006', '25000000-0000-4000-8000-000000000006', 'Which service is best for small event-driven functions?', 'Cloud Functions runs small code units in response to events.', 1),
  ('35000000-0000-4000-8000-000000000007', '25000000-0000-4000-8000-000000000007', 'Which Google Cloud platform manages ML training, deployment, prediction, and monitoring?', 'Vertex AI is Google Cloud''s unified ML platform.', 1),
  ('35000000-0000-4000-8000-000000000008', '25000000-0000-4000-8000-000000000008', 'Which Vertex AI approach is useful for fast low-code model baselines?', 'AutoML is useful for fast low-code training.', 1),
  ('35000000-0000-4000-8000-000000000009', '25000000-0000-4000-8000-000000000009', 'Which feature tracks model versions and deployment status?', 'Model Registry tracks registered models, versions, metadata, and deployment state.', 1),
  ('35000000-0000-4000-8000-000000000010', '25000000-0000-4000-8000-000000000010', 'Which Vertex AI resource receives online prediction requests?', 'An endpoint receives online prediction requests for deployed models.', 1),
  ('35000000-0000-4000-8000-000000000011', '25000000-0000-4000-8000-000000000011', 'Which practice tracks latency, errors, drift, and skew after deployment?', 'Monitoring tracks operational and ML health after deployment.', 1)
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    question = excluded.question,
    explanation = excluded.explanation,
    sort_order = excluded.sort_order;

insert into public.quiz_options (id, quiz_id, option_text, is_correct, sort_order)
values
  ('55000000-0000-4000-8000-000000000001', '35000000-0000-4000-8000-000000000001', 'Project', true, 1),
  ('55000000-0000-4000-8000-000000000002', '35000000-0000-4000-8000-000000000001', 'Training file', false, 2),
  ('55000000-0000-4000-8000-000000000003', '35000000-0000-4000-8000-000000000001', 'Model parameter', false, 3),
  ('55000000-0000-4000-8000-000000000004', '35000000-0000-4000-8000-000000000002', 'Service account', true, 1),
  ('55000000-0000-4000-8000-000000000005', '35000000-0000-4000-8000-000000000002', 'CSV header', false, 2),
  ('55000000-0000-4000-8000-000000000006', '35000000-0000-4000-8000-000000000002', 'Local variable', false, 3),
  ('55000000-0000-4000-8000-000000000007', '35000000-0000-4000-8000-000000000003', 'Objects', true, 1),
  ('55000000-0000-4000-8000-000000000008', '35000000-0000-4000-8000-000000000003', 'Endpoints only', false, 2),
  ('55000000-0000-4000-8000-000000000009', '35000000-0000-4000-8000-000000000003', 'IAM roles only', false, 3),
  ('55000000-0000-4000-8000-000000000010', '35000000-0000-4000-8000-000000000004', 'BigQuery', true, 1),
  ('55000000-0000-4000-8000-000000000011', '35000000-0000-4000-8000-000000000004', 'Cloud Functions', false, 2),
  ('55000000-0000-4000-8000-000000000012', '35000000-0000-4000-8000-000000000004', 'IAM', false, 3),
  ('55000000-0000-4000-8000-000000000013', '35000000-0000-4000-8000-000000000005', 'Compute Engine', true, 1),
  ('55000000-0000-4000-8000-000000000014', '35000000-0000-4000-8000-000000000005', 'Model Registry', false, 2),
  ('55000000-0000-4000-8000-000000000015', '35000000-0000-4000-8000-000000000005', 'BigQuery ML', false, 3),
  ('55000000-0000-4000-8000-000000000016', '35000000-0000-4000-8000-000000000006', 'Cloud Functions', true, 1),
  ('55000000-0000-4000-8000-000000000017', '35000000-0000-4000-8000-000000000006', 'Cloud Storage bucket', false, 2),
  ('55000000-0000-4000-8000-000000000018', '35000000-0000-4000-8000-000000000006', 'IAM role', false, 3),
  ('55000000-0000-4000-8000-000000000019', '35000000-0000-4000-8000-000000000007', 'Vertex AI', true, 1),
  ('55000000-0000-4000-8000-000000000020', '35000000-0000-4000-8000-000000000007', 'Cloud DNS', false, 2),
  ('55000000-0000-4000-8000-000000000021', '35000000-0000-4000-8000-000000000007', 'Cloud Billing', false, 3),
  ('55000000-0000-4000-8000-000000000022', '35000000-0000-4000-8000-000000000008', 'AutoML', true, 1),
  ('55000000-0000-4000-8000-000000000023', '35000000-0000-4000-8000-000000000008', 'Compute Engine only', false, 2),
  ('55000000-0000-4000-8000-000000000024', '35000000-0000-4000-8000-000000000008', 'Cloud Logging', false, 3),
  ('55000000-0000-4000-8000-000000000025', '35000000-0000-4000-8000-000000000009', 'Model Registry', true, 1),
  ('55000000-0000-4000-8000-000000000026', '35000000-0000-4000-8000-000000000009', 'Cloud Shell', false, 2),
  ('55000000-0000-4000-8000-000000000027', '35000000-0000-4000-8000-000000000009', 'VPC firewall', false, 3),
  ('55000000-0000-4000-8000-000000000028', '35000000-0000-4000-8000-000000000010', 'Endpoint', true, 1),
  ('55000000-0000-4000-8000-000000000029', '35000000-0000-4000-8000-000000000010', 'Dataset', false, 2),
  ('55000000-0000-4000-8000-000000000030', '35000000-0000-4000-8000-000000000010', 'Bucket', false, 3),
  ('55000000-0000-4000-8000-000000000031', '35000000-0000-4000-8000-000000000011', 'Monitoring', true, 1),
  ('55000000-0000-4000-8000-000000000032', '35000000-0000-4000-8000-000000000011', 'Label encoding', false, 2),
  ('55000000-0000-4000-8000-000000000033', '35000000-0000-4000-8000-000000000011', 'One-hot encoding', false, 3)
on conflict (id) do update
set quiz_id = excluded.quiz_id,
    option_text = excluded.option_text,
    is_correct = excluded.is_correct,
    sort_order = excluded.sort_order;

insert into public.exam_domains (id, title, description, weight_percent, exam_points, practical_points, sort_order)
values
  (
    '80000000-0000-4000-8000-000000000001',
    'Architect low-code AI solutions',
    'Choose the right managed or low-code AI approach for a business problem.',
    null,
    array['Choose between AutoML, BigQuery ML, ML APIs, and custom training', 'Identify the data type and business goal before choosing a service'],
    array['Start with managed services when speed and simplicity matter', 'Move to custom training when model control is required'],
    1
  ),
  (
    '80000000-0000-4000-8000-000000000002',
    'Manage data and models',
    'Design storage, preprocessing, model versioning, and traceability.',
    null,
    array['Separate Cloud Storage and BigQuery use cases', 'Use Model Registry for model version tracking'],
    array['Design for data location, permissions, lineage, and lifecycle', 'Track deployed model versions for rollback and audits'],
    2
  ),
  (
    '80000000-0000-4000-8000-000000000003',
    'Serve, scale, and monitor models',
    'Deploy models, serve predictions, and monitor production health.',
    null,
    array['Choose online prediction or batch prediction', 'Understand endpoints, traffic split, drift, skew, and alerts'],
    array['Balance latency, cost, security, and reliability', 'Use monitoring to catch data and model quality changes'],
    3
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    weight_percent = excluded.weight_percent,
    exam_points = excluded.exam_points,
    practical_points = excluded.practical_points,
    sort_order = excluded.sort_order;

insert into public.service_comparisons (id, service_name, category, best_for, avoid_when, exam_point, practical_point, sort_order)
values
  ('81000000-0000-4000-8000-000000000001', 'Cloud Storage', 'Storage', 'Files, images, training data, and model artifacts', 'SQL analytics is the main goal', 'Distinguish object storage from analytics storage', 'Design bucket IAM, region, lifecycle, and naming carefully', 1),
  ('81000000-0000-4000-8000-000000000002', 'BigQuery', 'Analytics', 'Large tabular analytics, feature exploration, and BigQuery ML', 'Simple file storage is the main goal', 'Common choice for analytics, feature engineering, and BigQuery ML scenarios', 'Use partitioning and clustering to manage performance and cost', 2),
  ('81000000-0000-4000-8000-000000000003', 'Compute Engine', 'Compute', 'VM control, custom GPU setup, and special runtime environments', 'Managed ML services already satisfy the requirement', 'Recognize the trade-off between control and operations burden', 'VMs require patching, security, cost, and lifecycle management', 3),
  ('81000000-0000-4000-8000-000000000004', 'Cloud Functions', 'Serverless', 'Small event-driven automation such as file upload triggers', 'Long-running training or complex ML pipelines', 'Use for lightweight event-driven glue code', 'Keep functions small and focused on short tasks', 4),
  ('81000000-0000-4000-8000-000000000005', 'Vertex AI AutoML', 'ML Training', 'Fast low-code model baselines with labeled data', 'The team needs full algorithm or architecture control', 'Important low-code AI solution choice', 'Compare baseline quality with later custom training needs', 5),
  ('81000000-0000-4000-8000-000000000006', 'Vertex AI Model Registry', 'MLOps', 'Model version, metadata, and deployment state tracking', 'Only a quick local experiment is needed', 'Model governance and version tracking are common scenario themes', 'Use it to support approvals, rollback, and traceability', 6),
  ('81000000-0000-4000-8000-000000000007', 'Vertex AI Endpoints', 'Serving', 'Online predictions, traffic split, and autoscaling', 'Large asynchronous batch scoring is the main goal', 'Separate online prediction from batch prediction', 'Design for latency, scaling, traffic routing, and access control', 7),
  ('81000000-0000-4000-8000-000000000008', 'Vertex AI Monitoring', 'Operations', 'Drift, skew, prediction quality, and service health monitoring', 'The model has not been deployed yet', 'Monitoring after deployment is essential in PMLE scenarios', 'Define alert thresholds and review ownership before production', 8)
on conflict (id) do update
set service_name = excluded.service_name,
    category = excluded.category,
    best_for = excluded.best_for,
    avoid_when = excluded.avoid_when,
    exam_point = excluded.exam_point,
    practical_point = excluded.practical_point,
    sort_order = excluded.sort_order;

insert into public.scenario_questions (id, lesson_id, title, scenario, options, correct_option_index, explanation, exam_point, practical_point, difficulty, sort_order)
values
  (
    '82000000-0000-4000-8000-000000000001',
    '25000000-0000-4000-8000-000000000004',
    'Large tabular analytics',
    'A team has millions of customer transaction rows and needs SQL analysis plus feature exploration before model training. Which service should they consider first?',
    '["BigQuery", "Cloud Functions", "Compute Engine only"]'::jsonb,
    0,
    'BigQuery is the best first choice for large tabular SQL analysis and feature exploration.',
    'Choose the service based on data shape and access pattern.',
    'Use partitioning and query scope controls to manage cost.',
    'easy',
    1
  ),
  (
    '82000000-0000-4000-8000-000000000002',
    '25000000-0000-4000-8000-000000000008',
    'Fast baseline model',
    'A small team has labeled tabular data and wants a fast baseline classifier without writing custom model training code. Which option fits best?',
    '["Vertex AI AutoML", "Write every algorithm on a VM", "Use Cloud Storage only"]'::jsonb,
    0,
    'Vertex AI AutoML is appropriate for a fast low-code baseline.',
    'AutoML is a key low-code solution choice.',
    'After the baseline, compare quality and decide whether custom training is needed.',
    'medium',
    2
  ),
  (
    '82000000-0000-4000-8000-000000000003',
    '25000000-0000-4000-8000-000000000010',
    'Online prediction service',
    'A mobile app needs real-time prediction results from a deployed model. Which Vertex AI resource receives those requests?',
    '["Endpoint", "Dataset only", "Cloud Billing"]'::jsonb,
    0,
    'A Vertex AI endpoint receives online prediction requests for deployed models.',
    'Distinguish online prediction from batch prediction.',
    'Plan latency, autoscaling, traffic split, and access control.',
    'medium',
    3
  ),
  (
    '82000000-0000-4000-8000-000000000004',
    '25000000-0000-4000-8000-000000000011',
    'Deployed model quality change',
    'A model has been deployed for two weeks. Input data distribution appears to be changing and prediction quality may be falling. What should be used?',
    '["Model Monitoring", "Rename a bucket", "Delete all IAM roles"]'::jsonb,
    0,
    'Model monitoring helps detect drift, skew, and production quality risks.',
    'Production monitoring is an important PMLE topic.',
    'Define alert rules, review owners, and response processes.',
    'medium',
    4
  ),
  (
    '82000000-0000-4000-8000-000000000005',
    '25000000-0000-4000-8000-000000000002',
    'Least privilege',
    'A training service account only needs to read training data and start Vertex AI training jobs. Which IAM principle matters most?',
    '["Grant only the required roles", "Give Owner to everyone", "Publish credentials publicly"]'::jsonb,
    0,
    'Least privilege means granting only the permissions needed for the task.',
    'IAM questions often test member, role, resource, and least privilege.',
    'Separate service account roles and review them regularly.',
    'easy',
    5
  )
on conflict (id) do update
set lesson_id = excluded.lesson_id,
    title = excluded.title,
    scenario = excluded.scenario,
    options = excluded.options,
    correct_option_index = excluded.correct_option_index,
    explanation = excluded.explanation,
    exam_point = excluded.exam_point,
    practical_point = excluded.practical_point,
    difficulty = excluded.difficulty,
    sort_order = excluded.sort_order;
