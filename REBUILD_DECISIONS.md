# Mio / Omnimind BYOK Rebuild Decisions

## Final decision

Keep Flutter and Supabase. Ditch the current UI. Do not build a heavy custom backend for the MVP.

## Keep

| Area | Decision |
| --- | --- |
| Flutter platform target | Keep. It is still the best route for one codebase across desktop, mobile, and web. |
| BYOK concept | Keep. It is the core differentiator. |
| Secure local key storage | Keep. API keys belong on the user's device. |
| Provider switching | Keep. It is required for the BYOK value proposition. |
| Supabase | Keep as optional sync/auth/database layer. |
| Local-first chat | Keep. The app should function before login or Supabase setup. |

## Ditch

| Area | Decision |
| --- | --- |
| Existing UI | Ditch completely. It does not match the premium Manus-style direction. |
| Heavy connector/skills/payment scope | Ditch from MVP. Add later only after the core chat experience feels premium. |
| Server-first chat flow | Ditch. It adds latency and creates unnecessary API-key handling risk. |
| Storing API keys in database | Ditch. Store only fingerprints/metadata if needed. |
| Overloaded dependencies | Ditch. Keep the app small and fast. |

## Rebuild

| Area | New approach |
| --- | --- |
| Visual design | Cream/light-grey base, Persian orange accent, dark ink typography, soft premium borders. |
| Desktop layout | Sidebar, top controls, provider pill, zero-fluff toggle, centered chat canvas. |
| Mobile layout | Compact single-column version of the same UI. |
| Backend | Optional Supabase for auth/sync. Optional Railway backend only if later needed for billing, webhooks, or server-only tasks. |
| Provider calls | Direct client-to-provider using the user's key. |
