import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createGeminiProvider } from "@/lib/ai/gemini";
import type { PortfolioProject } from "@/lib/types";

type CareerToolBody =
  | {
      action: "generate_readme";
      projectId: string;
    }
  | {
      action: "generate_resume_bullet";
      projectId: string;
      roleFocus?: string;
    }
  | {
      action: "generate_interview_questions";
      projectId: string;
      category?: "technical" | "project" | "behavioral" | "pmle";
    };

function createAuthedSupabase(request: NextRequest) {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const authHeader = request.headers.get("authorization") ?? "";

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error("Supabase environment variables are not configured.");
  }

  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader
      }
    }
  });
}

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as CareerToolBody;
    const supabase = createAuthedSupabase(request);
    const {
      data: { user },
      error: userError
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({ error: "Login is required." }, { status: 401 });
    }

    const projectResult = await supabase.from("portfolio_projects").select("*").eq("id", body.projectId).eq("user_id", user.id).maybeSingle();
    if (projectResult.error || !projectResult.data) {
      return NextResponse.json({ error: projectResult.error?.message ?? "Portfolio project was not found." }, { status: 404 });
    }

    const project = normalizeProject(projectResult.data as PortfolioProject);
    const source = process.env.GEMINI_API_KEY ? "gemini" : "template";

    if (body.action === "generate_readme") {
      const content = await generateWithFallback({
        prompt: buildReadmePrompt(project),
        fallback: buildReadmeTemplate(project)
      });

      const updateResult = await supabase
        .from("portfolio_projects")
        .update({ readme_content: content, updated_at: new Date().toISOString() })
        .eq("id", project.id)
        .eq("user_id", user.id)
        .select("*")
        .single();

      if (updateResult.error) {
        return NextResponse.json({ error: updateResult.error.message }, { status: 500 });
      }

      return NextResponse.json({ project: updateResult.data, content, source });
    }

    if (body.action === "generate_resume_bullet") {
      const roleFocus = body.roleFocus || "AI Engineer";
      const content = await generateWithFallback({
        prompt: buildResumePrompt(project, roleFocus),
        fallback: buildResumeBulletTemplate(project, roleFocus)
      });

      const insertResult = await supabase
        .from("resume_bullets")
        .insert({
          user_id: user.id,
          project_id: project.id,
          content,
          role_focus: roleFocus,
          source
        })
        .select("*")
        .single();

      if (insertResult.error) {
        return NextResponse.json({ error: insertResult.error.message }, { status: 500 });
      }

      return NextResponse.json({ resumeBullet: insertResult.data, content, source });
    }

    const category = body.category || "project";
    const generated = await generateInterviewQuestions(project, category);
    const rows = generated.map((item) => ({
      user_id: user.id,
      project_id: project.id,
      question: item.question,
      suggested_answer: item.suggestedAnswer,
      category,
      difficulty: item.difficulty,
      source
    }));

    const insertResult = await supabase.from("interview_questions").insert(rows).select("*");
    if (insertResult.error) {
      return NextResponse.json({ error: insertResult.error.message }, { status: 500 });
    }

    return NextResponse.json({ interviewQuestions: insertResult.data ?? [], source });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Career tool request failed." }, { status: 500 });
  }
}

async function generateWithFallback({ prompt, fallback }: { prompt: string; fallback: string }) {
  if (!process.env.GEMINI_API_KEY) return fallback;

  try {
    const provider = createGeminiProvider();
    return await provider.generateText({
      systemPrompt:
        "You are a career coach for a non-CS learner becoming an AI engineer and preparing for Google Cloud PMLE. Use clear, practical language. Do not mention OpenAI. Keep output concise and job-ready.",
      messages: [{ role: "user", content: prompt }]
    });
  } catch {
    return fallback;
  }
}

async function generateInterviewQuestions(project: PortfolioProject, category: "technical" | "project" | "behavioral" | "pmle") {
  const fallback = buildInterviewQuestionTemplates(project, category);
  if (!process.env.GEMINI_API_KEY) return fallback;

  try {
    const provider = createGeminiProvider();
    const text = await provider.generateText({
      systemPrompt:
        "Generate interview preparation content for an aspiring AI engineer and PMLE candidate. Return only valid JSON with an array named questions. Each item must have question, suggestedAnswer, and difficulty fields. Difficulty must be easy, medium, or hard. Do not mention OpenAI.",
      messages: [{ role: "user", content: buildInterviewPrompt(project, category) }]
    });
    const parsed = JSON.parse(text) as {
      questions?: Array<{ question?: string; suggestedAnswer?: string; difficulty?: string }>;
    };
    const questions = (parsed.questions ?? [])
      .filter((item) => item.question && item.suggestedAnswer)
      .slice(0, 5)
      .map((item) => ({
        question: item.question ?? "",
        suggestedAnswer: item.suggestedAnswer ?? "",
        difficulty: normalizeDifficulty(item.difficulty)
      }));

    return questions.length > 0 ? questions : fallback;
  } catch {
    return fallback;
  }
}

function normalizeProject(project: PortfolioProject): PortfolioProject {
  return {
    ...project,
    tech_stack: Array.isArray(project.tech_stack) ? project.tech_stack : []
  };
}

function buildReadmePrompt(project: PortfolioProject) {
  return `Create a GitHub README.md for this AI engineering portfolio project.

Project:
- Title: ${project.title}
- Summary: ${project.summary}
- Target domain: ${project.target_domain}
- Role: ${project.role}
- Tech stack: ${project.tech_stack.join(", ")}
- Problem: ${project.problem}
- Solution: ${project.solution}
- Result: ${project.result}

Include sections: Overview, Problem, Solution, Tech Stack, Key Features, Architecture, What I Learned, PMLE Relevance, How To Run, Next Steps.`;
}

function buildResumePrompt(project: PortfolioProject, roleFocus: string) {
  return `Write one resume bullet for a ${roleFocus} role based on this project. Use action verb + project + technical scope + measurable result if possible. Keep it under 35 words.

Project: ${project.title}
Problem: ${project.problem}
Solution: ${project.solution}
Result: ${project.result}
Tech stack: ${project.tech_stack.join(", ")}`;
}

function buildInterviewPrompt(project: PortfolioProject, category: string) {
  return `Create 5 ${category} interview questions for this portfolio project.

Project: ${project.title}
Summary: ${project.summary}
Problem: ${project.problem}
Solution: ${project.solution}
Result: ${project.result}
Tech stack: ${project.tech_stack.join(", ")}
Target domain: ${project.target_domain}`;
}

function buildReadmeTemplate(project: PortfolioProject) {
  return `# ${project.title}

## Overview
${project.summary || "This project demonstrates an AI engineering workflow for a PMLE-oriented portfolio."}

## Problem
${project.problem || "Define the user or business problem this project solves."}

## Solution
${project.solution || "Explain the data, model, cloud, and product approach used to solve the problem."}

## Tech Stack
${project.tech_stack.length ? project.tech_stack.map((item) => `- ${item}`).join("\n") : "- Python\n- Machine Learning\n- Google Cloud\n- Vertex AI"}

## Key Features
- Clear problem definition
- Reproducible workflow
- Model or analysis output
- Deployment or operations plan

## Architecture
Describe the flow from data source to processing, model training, serving, and monitoring.

## What I Learned
Summarize the Python, ML, cloud, and MLOps lessons from the project.

## PMLE Relevance
This project connects to PMLE topics such as data preparation, model selection, deployment, monitoring, and responsible operations.

## How To Run
Add setup commands, environment variables, and run instructions.

## Next Steps
- Add tests
- Improve monitoring
- Add model comparison
- Document cost and security decisions
`;
}

function buildResumeBulletTemplate(project: PortfolioProject, roleFocus: string) {
  const tech = project.tech_stack.slice(0, 3).join(", ") || "Python, ML, and Google Cloud";
  const result = project.result || "improved portfolio readiness for AI engineering roles";
  return `Built ${project.title || "an AI portfolio project"} for a ${roleFocus} path using ${tech}, translating a real problem into a documented solution that ${result}.`;
}

function buildInterviewQuestionTemplates(project: PortfolioProject, category: "technical" | "project" | "behavioral" | "pmle") {
  const title = project.title || "your portfolio project";
  const tech = project.tech_stack.slice(0, 3).join(", ") || "your chosen tech stack";

  if (category === "pmle") {
    return [
      {
        question: `How does ${title} demonstrate a PMLE skill area?`,
        suggestedAnswer: "Connect the project to data preparation, model selection, deployment, monitoring, and business trade-offs.",
        difficulty: "medium" as const
      },
      {
        question: "What would you monitor after deploying this model or workflow?",
        suggestedAnswer: "Discuss latency, errors, prediction quality, drift, skew, cost, and alert ownership.",
        difficulty: "medium" as const
      },
      {
        question: "When would you choose AutoML instead of custom training for this problem?",
        suggestedAnswer: "Use AutoML for fast baselines with labeled data; use custom training when model control or special architecture matters.",
        difficulty: "hard" as const
      }
    ];
  }

  return [
    {
      question: `What problem does ${title} solve?`,
      suggestedAnswer: project.problem || "Explain the user pain, why it matters, and how the project addresses it.",
      difficulty: "easy" as const
    },
    {
      question: `Why did you choose ${tech}?`,
      suggestedAnswer: "Explain the practical reason for each major tool and what trade-off it solved.",
      difficulty: "medium" as const
    },
    {
      question: "What would you improve in the next version?",
      suggestedAnswer: "Discuss tests, data quality, deployment, monitoring, user feedback, or cost/security improvements.",
      difficulty: "medium" as const
    },
    {
      question: "What was the hardest technical decision?",
      suggestedAnswer: "Describe the decision, alternatives, trade-offs, and final result.",
      difficulty: "hard" as const
    },
    {
      question: "How would you explain this project to a non-technical stakeholder?",
      suggestedAnswer: "Use simple language: the problem, the result, and why the solution is useful.",
      difficulty: "easy" as const
    }
  ];
}

function normalizeDifficulty(value: string | undefined): "easy" | "medium" | "hard" {
  if (value === "easy" || value === "medium" || value === "hard") return value;
  return "medium";
}
