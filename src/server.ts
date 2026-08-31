import "./lib/error-capture";

import { consumeLastCapturedError } from "./lib/error-capture";
import { renderErrorPage } from "./lib/error-page";
import {
  handleRequestSignInOtp,
  handleRequestSignUpOtp,
  handleVerifySignInOtp,
  handleVerifySignUpOtp,
} from "./lib/otp-auth.functions";

type ServerEntry = {
  fetch: (request: Request, env: unknown, ctx: unknown) => Promise<Response> | Response;
};

let serverEntryPromise: Promise<ServerEntry> | undefined;

async function getServerEntry(): Promise<ServerEntry> {
  if (!serverEntryPromise) {
    serverEntryPromise = import("@tanstack/react-start/server-entry").then(
      (m) => (m.default ?? m) as ServerEntry,
    );
  }
  return serverEntryPromise;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

async function handleApiOtp(request: Request): Promise<Response | null> {
  const url = new URL(request.url);

  if (request.method === "OPTIONS" && (url.pathname === "/api/otp/request" || url.pathname === "/api/otp/verify")) {
    return new Response(null, { headers: corsHeaders });
  }

  if (request.method === "POST" && url.pathname === "/api/otp/request") {
    try {
      const body = (await request.json()) as {
        mode?: "signin" | "signup";
        email?: string;
        full_name?: string;
        username?: string;
      };

      const mode = body.mode ?? "signin";
      const email = (body.email ?? "").trim().toLowerCase();

      if (mode === "signup") {
        const res = await handleRequestSignUpOtp({
          email,
          full_name: (body.full_name ?? "").trim(),
          username: (body.username ?? "").trim().toLowerCase(),
        });
        return Response.json(res, { headers: corsHeaders });
      } else {
        const res = await handleRequestSignInOtp({ email });
        return Response.json(res, { headers: corsHeaders });
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return Response.json({ success: false, message: msg }, { status: 400, headers: corsHeaders });
    }
  }

  if (request.method === "POST" && url.pathname === "/api/otp/verify") {
    try {
      const body = (await request.json()) as {
        mode?: "signin" | "signup";
        email?: string;
        code?: string;
        full_name?: string;
        username?: string;
      };

      const mode = body.mode ?? "signin";
      const email = (body.email ?? "").trim().toLowerCase();
      const code = (body.code ?? "").trim();

      if (mode === "signup") {
        const res = await handleVerifySignUpOtp({
          email,
          code,
          full_name: (body.full_name ?? "").trim(),
          username: (body.username ?? "").trim().toLowerCase(),
        });
        return Response.json(res, { headers: corsHeaders });
      } else {
        const res = await handleVerifySignInOtp({ email, code });
        return Response.json(res, { headers: corsHeaders });
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return Response.json({ success: false, message: msg }, { status: 400, headers: corsHeaders });
    }
  }

  return null;
}

async function normalizeCatastrophicSsrResponse(response: Response): Promise<Response> {
  if (response.status < 500) return response;
  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return response;

  const body = await response.clone().text();
  if (!isH3SwallowedErrorBody(body)) return response;

  console.error(consumeLastCapturedError() ?? new Error(`h3 swallowed SSR error: ${body}`));
  return new Response(renderErrorPage(), {
    status: 500,
    headers: { "content-type": "text/html; charset=utf-8" },
  });
}

function isH3SwallowedErrorBody(body: string): boolean {
  try {
    const payload = JSON.parse(body) as { unhandled?: unknown; message?: unknown };
    return payload.unhandled === true && payload.message === "HTTPError";
  } catch {
    return false;
  }
}

export default {
  async fetch(request: Request, env: unknown, ctx: unknown) {
    try {
      const apiResponse = await handleApiOtp(request);
      if (apiResponse) return apiResponse;

      const handler = await getServerEntry();
      const response = await handler.fetch(request, env, ctx);
      return await normalizeCatastrophicSsrResponse(response);
    } catch (error) {
      console.error(error);
      return new Response(renderErrorPage(), {
        status: 500,
        headers: { "content-type": "text/html; charset=utf-8" },
      });
    }
  },
};
