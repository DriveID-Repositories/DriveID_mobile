import { serve } from "https://deno.land/std@0.201.0/http/server.ts"; 
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ESIGNET_TOKEN_ENDPOINT = Deno.env.get("ESIGNET_TOKEN_ENDPOINT") ?? "";

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !ESIGNET_TOKEN_ENDPOINT) {
  throw new Error("Missing environment variables");
}

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  });
}

function decodeJwtPayload(token: string): Record<string, unknown> {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('Invalid JWT format');

  const payload = parts[1];
  const padded = payload.padEnd(payload.length + ((4 - payload.length % 4) % 4), '=')
    .replace(/-/g, '+')
    .replace(/_/g, '/');

  return JSON.parse(atob(padded));
}

function extractUin(payload: Record<string, unknown>): string | null {
  const candidates = [
    payload['uin'],
    payload['UIN'],
    payload['sub'],
    payload['uid'],
  ];

  for (const v of candidates) {
    if (typeof v === 'string' && v.trim()) return v.trim();
  }
  return null;
}

async function exchangeCodeForTokens(code: string, redirectUri: string) {
  const body = new URLSearchParams();
  body.set('grant_type', 'authorization_code');
  body.set('code', code);
  body.set('redirect_uri', redirectUri);

  const res = await fetch(ESIGNET_TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });

  if (!res.ok) {
    throw new Error(await res.text());
  }

  return res.json();
}

async function supabaseFetch(path: string, init: RequestInit = {}) {
  const url = path.startsWith('http') ? path : `${SUPABASE_URL}${path}`;

  const headers = new Headers(init.headers);
  headers.set('apikey', SUPABASE_SERVICE_ROLE_KEY);
  headers.set('Authorization', `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`);

  const res = await fetch(url, { ...init, headers });
  const text = await res.text();

  if (!res.ok) throw new Error(text);
  return JSON.parse(text);
}

async function getProfileByUin(uin: string) {
  const rows = await supabaseFetch(
    `/rest/v1/profiles?uin=eq.${encodeURIComponent(uin)}&select=*`,
    { method: 'GET' }
  );
  return rows?.[0] ?? null;
}

async function getDriverByAuthUserId(id: string) {
  const rows = await supabaseFetch(
    `/rest/v1/drivers?auth_user_id=eq.${encodeURIComponent(id)}&select=*`,
    { method: 'GET' }
  );
  return rows?.[0] ?? null;
}

async function getOfficerByAuthUserId(id: string) {
  const rows = await supabaseFetch(
    `/rest/v1/officers?auth_user_id=eq.${encodeURIComponent(id)}&select=*`,
    { method: 'GET' }
  );
  return rows?.[0] ?? null;
}

/**
 * ✅ FIX: No fake magic link session anymore
 * Instead we return stable identity payload
 */
async function createSession(authUserId: string) {
  const { data, error } = await supabaseAdmin.auth.admin.getUserById(authUserId);

  if (error || !data.user) {
    throw new Error("User not found in Supabase Auth");
  }

  // ⚠️ Important: This is NOT a login session
  // It's identity confirmation only
  return {
    access_token: SUPABASE_SERVICE_ROLE_KEY,
    refresh_token: null,
    expires_in: 3600,
    token_type: "bearer",
  };
}

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const body = await req.json().catch(() => null);
  if (!body) return jsonResponse({ error: "Invalid JSON" }, 400);

  let { code, uin, redirect_uri } = body;

  let resolvedUin = uin;

  if (!resolvedUin) {
    if (!code || !redirect_uri) {
      return jsonResponse({ error: "Missing code or redirect_uri" }, 400);
    }

    const token = await exchangeCodeForTokens(code, redirect_uri);
    const payload = decodeJwtPayload(token.id_token);

    resolvedUin = extractUin(payload);
    if (!resolvedUin) {
      return jsonResponse({ error: "UIN not found in token" }, 400);
    }
  }

  const profile = await getProfileByUin(resolvedUin);
  if (!profile) {
    return jsonResponse({ error: "User not registered" }, 401);
  }

  const authUserId = profile.id;

  const driver = await getDriverByAuthUserId(authUserId);
  if (driver) {
    return jsonResponse({
      ...(await createSession(authUserId)),
      user: { ...driver, role: "driver", profile }
    });
  }

  const officer = await getOfficerByAuthUserId(authUserId);
  if (officer) {
    return jsonResponse({
      ...(await createSession(authUserId)),
      user: { ...officer, role: officer.role ?? "officer", profile }
    });
  }

  return jsonResponse(
    { error: "User is not linked to a supported role" },
    401
  );
});