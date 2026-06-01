# Backend decision

The MVP intentionally does not require a custom backend.

Use Supabase for auth, database, row-level security, and sync. Use Railway later only if you add server-only features such as billing webhooks, shared team admin, provider proxying, audit logs, or scheduled jobs.

For BYOK chat, provider requests should go directly from the Flutter client to the AI provider using the user's locally stored key.
