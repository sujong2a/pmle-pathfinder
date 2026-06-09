"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { SupabaseClient, User } from "@supabase/supabase-js";
import { getSupabaseBrowserClient } from "./client";
import { ensureUserProfile } from "./profile";

type RequiredUserState = {
  client: SupabaseClient | null;
  user: User | null;
  loading: boolean;
  error: string;
};

export function useRequiredUser() {
  const router = useRouter();
  const [state, setState] = useState<RequiredUserState>({
    client: null,
    user: null,
    loading: true,
    error: ""
  });

  useEffect(() => {
    let active = true;

    async function loadUser() {
      try {
        const client = getSupabaseBrowserClient();
        const { data, error } = await client.auth.getUser();

        if (error || !data.user) {
          router.replace("/auth");
          if (active) setState({ client, user: null, loading: false, error: "" });
          return;
        }

        await ensureUserProfile(client, data.user);

        if (active) {
          setState({ client, user: data.user, loading: false, error: "" });
        }
      } catch (error) {
        if (active) {
          setState({
            client: null,
            user: null,
            loading: false,
            error: error instanceof Error ? error.message : "인증 정보를 불러오지 못했습니다."
          });
        }
      }
    }

    loadUser();

    return () => {
      active = false;
    };
  }, [router]);

  return state;
}
