"use client";

import type { SupabaseClient, User } from "@supabase/supabase-js";

export async function ensureUserProfile(client: SupabaseClient, user: User, displayName?: string) {
  const fallbackName = user.email?.split("@")[0] ?? "PMLE Learner";

  // This upsert is safe on the client because the SQL policies only allow own-row writes.
  await client.from("users").upsert(
    {
      id: user.id,
      email: user.email ?? "",
      display_name: displayName || user.user_metadata?.display_name || fallbackName,
      updated_at: new Date().toISOString()
    },
    { onConflict: "id" }
  );
}
