import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createGeminiProvider } from "@/lib/ai/gemini";
import { evaluateCodingSubmission } from "@/lib/coding/evaluator";
import type { CodingEvaluationResult, CodingTask } from "@/lib/types";

type SubmitBody = {
  taskId: string;
  code: string;
  userExpectedOutput: string;
};

function createAuthedSupabase(request: NextRequest) {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const authHeader = request.headers.get("authorization") ?? "";

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error("Supabase 환경변수가 설정되지 않았습니다.");
  }

  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: { Authorization: authHeader }
    }
  });
}

export async function GET(request: NextRequest) {
  try {
    const supabase = createAuthedSupabase(request);
    const {
      data: { user },
      error: userError
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({ error: "로그인이 필요합니다." }, { status: 401 });
    }

    const [tasksResult, submissionsResult, feedbackResult] = await Promise.all([
      supabase.from("coding_tasks").select("*").eq("is_active", true).order("sort_order", { ascending: true }),
      supabase.from("coding_submissions").select("*").eq("user_id", user.id).order("created_at", { ascending: false }).limit(30),
      supabase.from("coding_feedback").select("*").eq("user_id", user.id).order("created_at", { ascending: false }).limit(30)
    ]);

    const firstError = tasksResult.error || submissionsResult.error || feedbackResult.error;
    if (firstError) {
      return NextResponse.json({ error: firstError.message }, { status: 500 });
    }

    return NextResponse.json({
      tasks: tasksResult.data ?? [],
      submissions: submissionsResult.data ?? [],
      feedback: feedbackResult.data ?? []
    });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "실습 데이터를 불러오지 못했습니다." }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as SubmitBody;
    const supabase = createAuthedSupabase(request);
    const {
      data: { user },
      error: userError
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({ error: "로그인이 필요합니다." }, { status: 401 });
    }

    if (!body.taskId || !body.code.trim()) {
      return NextResponse.json({ error: "과제와 코드를 입력해 주세요." }, { status: 400 });
    }

    const taskResult = await supabase.from("coding_tasks").select("*").eq("id", body.taskId).eq("is_active", true).maybeSingle();
    if (taskResult.error || !taskResult.data) {
      return NextResponse.json({ error: taskResult.error?.message ?? "과제를 찾을 수 없습니다." }, { status: 404 });
    }

    const task = taskResult.data as CodingTask;
    const evaluation = evaluateCodingSubmission({
      task,
      code: body.code,
      userExpectedOutput: body.userExpectedOutput
    });

    const attemptResult = await supabase.from("coding_submissions").select("id").eq("user_id", user.id).eq("task_id", task.id);
    if (attemptResult.error) {
      return NextResponse.json({ error: attemptResult.error.message }, { status: 500 });
    }

    const attemptNumber = (attemptResult.data?.length ?? 0) + 1;
    const submissionResult = await supabase
      .from("coding_submissions")
      .insert({
        user_id: user.id,
        task_id: task.id,
        code: body.code,
        user_expected_output: body.userExpectedOutput,
        evaluation_result: evaluation,
        score: evaluation.score,
        status: evaluation.passed ? "passed" : "needs_retry",
        attempt_number: attemptNumber
      })
      .select("*")
      .single();

    if (submissionResult.error) {
      return NextResponse.json({ error: submissionResult.error.message }, { status: 500 });
    }

    const aiFeedback = await buildGeminiCodingFeedback({ task, code: body.code, userExpectedOutput: body.userExpectedOutput, evaluation });
    const feedbackResult = await supabase
      .from("coding_feedback")
      .insert({
        user_id: user.id,
        task_id: task.id,
        submission_id: submissionResult.data.id,
        improvements: evaluation.improvements,
        recommended_study: evaluation.recommendedStudy,
        feedback: buildRuleFeedback(evaluation),
        ai_feedback: aiFeedback
      })
      .select("*")
      .single();

    if (feedbackResult.error) {
      return NextResponse.json({ error: feedbackResult.error.message }, { status: 500 });
    }

    return NextResponse.json({
      task,
      submission: submissionResult.data,
      feedback: feedbackResult.data
    });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "실습 제출 처리에 실패했습니다." }, { status: 500 });
  }
}

async function buildGeminiCodingFeedback({
  task,
  code,
  userExpectedOutput,
  evaluation
}: {
  task: CodingTask;
  code: string;
  userExpectedOutput: string;
  evaluation: CodingEvaluationResult;
}) {
  try {
    const provider = createGeminiProvider();
    return await provider.generateText({
      systemPrompt: `당신은 PMLE Pathfinder의 Python 실습 튜터입니다.
사용자는 비전공자이고 Python 초보입니다.
실제 코드는 실행하지 않았고, 예상 출력 비교, 필수 키워드 검사, 정답 패턴 검사만 완료했습니다.

피드백 규칙:
- 쉬운 한국어로 말합니다.
- 먼저 잘한 점을 짧게 말합니다.
- 개선점, 추천 학습, 다음 재제출 힌트를 나누어 제공합니다.
- 정답 전체를 그대로 대신 작성하지 않습니다.
- 힌트 중심으로 사고를 유도합니다.`,
      messages: [
        {
          role: "user",
          content: `과제: ${task.title}
설명: ${task.description}
요구사항: ${task.instructions}
기준 출력:
${task.expected_output}

사용자의 예상 출력:
${userExpectedOutput}

사용자의 코드:
\`\`\`python
${code}
\`\`\`

평가 결과:
${JSON.stringify(evaluation, null, 2)}

이 정보를 바탕으로 개선점, 추천 학습, 재제출 힌트를 제공해 주세요.`
        }
      ]
    });
  } catch (error) {
    console.warn("Gemini coding feedback unavailable:", toSafeGeminiErrorMessage(error));
    return "";
  }
}

function buildRuleFeedback(evaluation: CodingEvaluationResult) {
  const status = evaluation.passed ? "제출 조건을 통과했습니다." : "아직 재제출이 필요합니다.";
  return `${status}\n\n개선점:\n${evaluation.improvements.map((item) => `- ${item}`).join("\n")}\n\n추천 학습:\n${evaluation.recommendedStudy.map((item) => `- ${item}`).join("\n")}`;
}

function toSafeGeminiErrorMessage(error: unknown) {
  if (!(error instanceof Error)) return "unknown Gemini error";
  if (error.message.toLowerCase().includes("prepayment credits are depleted")) {
    return "Gemini credits are depleted.";
  }
  return error.message;
}
