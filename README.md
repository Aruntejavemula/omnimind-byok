# Mio / Omnimind BYOK

A premium **Bring Your Own Key** AI chat app rebuilt with Flutter. The MVP is desktop-first, uses a cream/light-grey and Persian-orange visual system, stores provider keys locally with secure device storage, and can optionally connect to Supabase for auth and sync.

## What this rebuild keeps

This project keeps the useful product direction from the older Mio codebase: BYOK, provider switching, secure local key storage, project-style organization, direct AI calls, and optional Supabase sync. The old UI has been ditched.

## What this rebuild ditches

The rebuild removes the generic Material-heavy UI, heavy payment/connector/scheduled-task dependencies, and server-first chat flow. The app is now leaner: chat calls go directly from the Flutter client to the selected AI provider using the user's own API key.

## Current MVP features

| Area | Status |
| --- | --- |
| Premium desktop-first UI | Implemented |
| Cream/light-grey + Persian orange theme | Implemented |
| BYOK secure local key storage | Implemented |
| Provider selector | Implemented |
| OpenAI-compatible providers | Implemented |
| Anthropic direct API | Implemented |
| Gemini direct API | Implemented |
| Local chat persistence | Implemented |
| Supabase schema | Included |
| Supabase runtime init | Optional via dart-define |
| Railway backend | Optional placeholder via dart-define |

## Run locally

Flutter is required on your machine.

```bash
flutter pub get
flutter run -d macos
```

With Supabase:

```bash
flutter run -d macos \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Supabase setup

Run `supabase_schema.sql` in your Supabase SQL editor. The schema stores projects, chats, messages, and provider metadata. It does **not** store API keys.

## Security rule

Provider keys are stored locally with `flutter_secure_storage`. They should not be logged, synced, or sent to a custom backend. The app calls providers directly from the client.

## Next build steps

The next stage is to connect authenticated Supabase sync, add real project CRUD, add a polished key-management screen, and replace the placeholder attach button with document ingestion.
