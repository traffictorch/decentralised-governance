// worker.js — Entry point for the Round Table governance worker.
//
// Requirements (see ../README.md):
//   - D1 binding named MY_BINDING
//   - Environment secret JWT_SECRET (matches your auth worker's secret)
//   - users table with: id, created_at, verified_at, profile_public
//
// All governance logic lives in ./round-table.js — do not edit that file
// unless you are extending the engine itself.

import { handleRoundTableRoutes } from './round-table.js';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

function corsResponse(body, status = 200) {
  return new Response(body, {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

function base64urlToBytes(s) {
  s = s.replace(/-/g, '+').replace(/_/g, '/');
  while (s.length % 4) s += '=';
  const binary = atob(s);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function verifyJWT(token, secret) {
  if (!token || typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  try {
    const key = await crypto.subtle.importKey(
      'raw', new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']
    );
    const data = new TextEncoder().encode(parts[0] + '.' + parts[1]);
    const sig = base64urlToBytes(parts[2]);
    const valid = await crypto.subtle.verify('HMAC', key, sig, data);
    if (!valid) return null;
    const payload = JSON.parse(new TextDecoder().decode(base64urlToBytes(parts[1])));
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) return null;
    return payload;
  } catch {
    return null;
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (url.pathname.startsWith('/api/rt/')) {
      return await handleRoundTableRoutes(request, env, url, { corsResponse, verifyJWT });
    }

    return corsResponse(JSON.stringify({ error: 'Not found' }), 404);
  },
};
