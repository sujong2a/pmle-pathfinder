import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createGeminiProvider } from "@/lib/ai/gemini";
import { buildTutorSystemPrompt, type AiMessage } from "@/lib/ai/provider";

type TutorPostBody =
  | {
      action: "send_message";
      message: string;
      sessionId?: string;
      lessonId?: string;
    }
  | {
      action: "save_explanation";
      title: string;
      content: string;
      sourceQuestion?: string;
      sessionId?: string;
      messageId?: string;
      lessonId?: string;
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
      headers: {
        Authorization: authHeader
      }
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

    const sessionId = request.nextUrl.searchParams.get("sessionId");
    const [sessionsResult, savedResult] = await Promise.all([
      supabase.from("ai_chat_sessions").select("*").eq("user_id", user.id).order("updated_at", { ascending: false }).limit(20),
      supabase.from("saved_ai_explanations").select("*").eq("user_id", user.id).order("updated_at", { ascending: false }).limit(20)
    ]);

    if (sessionsResult.error || savedResult.error) {
      return NextResponse.json({ error: sessionsResult.error?.message ?? savedResult.error?.message }, { status: 500 });
    }

    const effectiveSessionId = sessionId || sessionsResult.data?.[0]?.id;
    let messages: unknown[] = [];
    if (effectiveSessionId) {
      const messagesResult = await supabase
        .from("ai_chat_messages")
        .select("*")
        .eq("user_id", user.id)
        .eq("session_id", effectiveSessionId)
        .order("created_at", { ascending: true });

      if (messagesResult.error) {
        return NextResponse.json({ error: messagesResult.error.message }, { status: 500 });
      }
      messages = messagesResult.data ?? [];
    }

    return NextResponse.json({
      sessions: sessionsResult.data ?? [],
      messages,
      savedExplanations: savedResult.data ?? []
    });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "AI 튜터 데이터를 불러오지 못했습니다." }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as TutorPostBody;
    const supabase = createAuthedSupabase(request);
    const {
      data: { user },
      error: userError
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({ error: "로그인이 필요합니다." }, { status: 401 });
    }

    if (body.action === "save_explanation") {
      const result = await supabase
        .from("saved_ai_explanations")
        .insert({
          user_id: user.id,
          session_id: body.sessionId || null,
          message_id: body.messageId || null,
          lesson_id: body.lessonId || null,
          title: body.title || "AI 설명",
          content: body.content,
          source_question: body.sourceQuestion || ""
        })
        .select("*")
        .single();

      if (result.error) {
        return NextResponse.json({ error: result.error.message }, { status: 500 });
      }

      return NextResponse.json({ savedExplanation: result.data });
    }

    const userMessage = body.message.trim();
    if (!userMessage) {
      return NextResponse.json({ error: "질문을 입력하세요." }, { status: 400 });
    }

    const session = await ensureSession({
      supabase,
      userId: user.id,
      sessionId: body.sessionId,
      lessonId: body.lessonId,
      titleSeed: userMessage
    });

    const previousMessages = await loadPreviousMessages(supabase, user.id, session.id);
    const context = await loadTutorContext(supabase, user.id);
    const systemPrompt = buildTutorSystemPrompt(context);

    const userInsert = await supabase
      .from("ai_chat_messages")
      .insert({
        user_id: user.id,
        session_id: session.id,
        role: "user",
        content: userMessage
      })
      .select("*")
      .single();

    if (userInsert.error) {
      return NextResponse.json({ error: userInsert.error.message }, { status: 500 });
    }

    const aiMessages = [
      ...previousMessages.map<AiMessage>((message) => ({
        role: message.role === "assistant" ? "assistant" : "user",
        content: message.content
      })),
      { role: "user", content: userMessage } satisfies AiMessage
    ].slice(-12);

    const provider = createGeminiProvider();
    const reply = await provider.generateText({ systemPrompt, messages: aiMessages });

    const assistantInsert = await supabase
      .from("ai_chat_messages")
      .insert({
        user_id: user.id,
        session_id: session.id,
        role: "assistant",
        content: reply
      })
      .select("*")
      .single();

    if (assistantInsert.error) {
      return NextResponse.json({ error: assistantInsert.error.message }, { status: 500 });
    }

    await supabase.from("ai_chat_sessions").update({ updated_at: new Date().toISOString() }).eq("id", session.id).eq("user_id", user.id);

    return NextResponse.json({
      session,
      userMessage: userInsert.data,
      assistantMessage: assistantInsert.data
    });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "AI 튜터 요청 처리에 실패했습니다." }, { status: 500 });
  }
}

async function ensureSession({
  supabase,
  userId,
  sessionId,
  lessonId,
  titleSeed
}: {
  supabase: ReturnType<typeof createAuthedSupabase>;
  userId: string;
  sessionId?: string;
  lessonId?: string;
  titleSeed: string;
}) {
  if (sessionId) {
    const existing = await supabase.from("ai_chat_sessions").select("*").eq("id", sessionId).eq("user_id", userId).maybeSingle();
    if (existing.error) throw new Error(existing.error.message);
    if (existing.data) return existing.data;
  }

  const title = titleSeed.length > 28 ? `${titleSeed.slice(0, 28)}...` : titleSeed;
  const created = await supabase
    .from("ai_chat_sessions")
    .insert({
      user_id: userId,
      lesson_id: lessonId || null,
      title: title || "새 AI 튜터 대화"
    })
    .select("*")
    .single();

  if (created.error) throw new Error(created.error.message);
  return created.data;
}

async function loadPreviousMessages(supabase: ReturnType<typeof createAuthedSupabase>, userId: string, sessionId: string) {
  const result = await supabase
    .from("ai_chat_messages")
    .select("role, content")
    .eq("user_id", userId)
    .eq("session_id", sessionId)
    .order("created_at", { ascending: true })
    .limit(20);

  if (result.error) throw new Error(result.error.message);
  return (result.data ?? []) as Array<{ role: string; content: string }>;
}

async function loadTutorContext(supabase: ReturnType<typeof createAuthedSupabase>, userId: string) {
  const [progressResult, wrongNotesResult, masteryResult, journalResult, lessonsResult] = await Promise.all([
    supabase.from("user_progress").select("lesson_id, status, completed, last_viewed_at").eq("user_id", userId).order("updated_at", { ascending: false }).limit(10),
    supabase.from("wrong_notes").select("question_snapshot, explanation_snapshot, attempt_count, resolved").eq("user_id", userId).eq("resolved", false).order("updated_at", { ascending: false }).limit(5),
    supabase.from("concept_mastery").select("lesson_id, concept_name, mastery_score, is_weak, note").eq("user_id", userId).order("mastery_score", { ascending: true }).limit(5),
    supabase.from("learning_journal").select("journal_date, study_minutes, understanding_score, content").eq("user_id", userId).order("journal_date", { ascending: false }).limit(3),
    supabase.from("lessons").select("id, title")
  ]);

  const lessonMap = new Map((lessonsResult.data ?? []).map((lesson: { id: string; title: string }) => [lesson.id, lesson.title]));

  return {
    learnerProfile: "비전공자, Python 초보, 직장인, 최종 목표는 AI 엔지니어와 Google Cloud PMLE 자격증 취득입니다.",
    progressSummary: summarizeList(
      progressResult.data?.map((item: { lesson_id: string; status: string; completed: boolean }) => {
        const title = lessonMap.get(item.lesson_id) ?? "알 수 없는 단원";
        return `${title}: ${item.completed ? "완료" : item.status}`;
      }),
      "아직 진도 기록이 없습니다."
    ),
    wrongNotesSummary: summarizeList(
      wrongNotesResult.data?.map((item: { question_snapshot: string; attempt_count: number }) => `${item.question_snapshot} (${item.attempt_count}회 틀림)`),
      "미해결 오답이 없습니다."
    ),
    weakConceptsSummary: summarizeList(
      masteryResult.data?.map((item: { concept_name: string; mastery_score: number; note: string }) => `${item.concept_name}: 이해도 ${item.mastery_score}점, 메모: ${item.note || "없음"}`),
      "등록된 취약개념이 없습니다."
    ),
    recentJournalSummary: summarizeList(
      journalResult.data?.map((item: { journal_date: string; study_minutes: number; understanding_score: number; content: string }) => `${item.journal_date}: ${item.study_minutes}분 학습, 이해도 ${item.understanding_score}점, ${item.content || "일지 내용 없음"}`),
      "최근 학습일지가 없습니다."
    )
  };
}

function summarizeList(items: string[] | undefined, emptyText: string) {
  if (!items || items.length === 0) return emptyText;
  return items.map((item) => `- ${item}`).join("\n");
}
