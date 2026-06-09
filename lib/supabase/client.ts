"use client";

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

let browserClient: SupabaseClient | null = null;

function requiredEnv(name: string, value: string | undefined) {
  if (!value) {
    throw new Error(`${name} 환경변수가 설정되지 않았습니다.`);
  }

  return value;
}

export function getSupabaseBrowserClient() {
  if (browserClient) return browserClient;

  const supabaseUrl = requiredEnv("NEXT_PUBLIC_SUPABASE_URL", process.env.NEXT_PUBLIC_SUPABASE_URL);
  const supabaseAnonKey = requiredEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

  // Browser code must only use the public anon key. RLS protects user-owned rows.
  browserClient = createClient(supabaseUrl, supabaseAnonKey);
  return browserClient;
}
