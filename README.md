# OmniMind BYOK

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart)](https://dart.dev)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python)](https://python.org)
[![Supabase](https://img.shields.io/badge/Supabase-optional-3ECF8E?logo=supabase)](https://supabase.com)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Web%20%7C%20iOS%20%7C%20Android-lightgrey)](https://flutter.dev/multi-platform)

A premium **Bring Your Own Key** AI chat application built with Flutter. Chat with 18+ AI providers using your own API keys — keys stay on your device, calls go directly from client to provider. No middleman, no data collection.

---

## Features

- **18+ AI Providers** — OpenAI, Anthropic (Claude), Google Gemini, Groq, Mistral, DeepSeek, Kimi, Ollama, OpenRouter, and more
- **Direct API Calls** — Client calls providers directly; no custom server in the critical path
- **Secure Local Key Storage** — API keys stored with `flutter_secure_storage`, never logged or synced
- **Cross-Platform** — macOS, Windows, Linux, Web, iOS, and Android from a single Flutter codebase
- **Provider Selector** — Switch between providers per-chat with per-provider model menus
- **Project Organization** — Organize chats into projects; full local chat persistence
- **Rich Onboarding** — 8-step onboarding flow with Lottie splash animation
- **Connectors** — Camera, Gallery, Documents, Link, Web Search (DuckDuckGo), GitHub repo search, Notion search, Gmail
- **Optional Supabase Sync** — Auth and encrypted sync via Supabase (off by default; no keys ever reach the cloud)
- **Premium UI** — Cream/light-grey + Persian-orange design system, Google Fonts, Shimmer loading states, Framer-quality animations

---

## Architecture

```
omnimind-byok/
├── lib/                        # Flutter app source (Dart)
│   ├── providers/              # Riverpod state providers
│   ├── screens/                # Splash, Welcome, Onboarding, Chat
│   ├── widgets/                # Reusable UI components
│   ├── connectors/             # Camera, Docs, Web Search, GitHub, Notion, Gmail
│   ├── services/               # AI provider clients, secure storage, Supabase
│   └── router.dart             # go_router — 4 routes: /, /welcome, /onboarding, /chat
├── backend/                    # Optional Python backend (Railway)
├── android/ ios/ macos/        # Platform-specific shells
│   windows/ linux/ web/
├── assets/
│   ├── animations/             # Lottie (mascot.json)
│   └── icons/providers/        # Provider logo assets
└── pubspec.yaml
```

### App Flow

```
Splash (/)  ──►  Welcome/Login (/welcome)  ──►  8-step Onboarding (/onboarding)  ──►  Chat (/chat)
```

### AI Call Flow

```
Flutter UI  ──►  Provider service (Dio)  ──►  OpenAI / Anthropic / Gemini / … API
                 (user's own key, no server hop)
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x, Dart 3.8 |
| State Management | Riverpod 2.x |
| Routing | go_router 14 |
| HTTP Client | Dio 5 |
| Secure Storage | flutter_secure_storage 9 |
| Auth / Sync (optional) | Supabase Flutter 2 |
| Animations | Lottie 3, Shimmer 3 |
| Web / In-App Content | webview_flutter 4 |
| Markdown Rendering | flutter_markdown |
| Fonts | Google Fonts |
| File / Media | file_picker, image_picker, path_provider |
| Permissions | permission_handler |
| Optional Backend | Python (FastAPI), Railway |

---

## AI Providers

| Provider | Integration |
|---|---|
| OpenAI | Direct REST (gpt-4o, gpt-4, gpt-3.5-turbo, …) |
| Anthropic | Direct REST (claude-3-5-sonnet, claude-3-opus, …) |
| Google Gemini | Direct REST (gemini-1.5-pro, gemini-1.5-flash, …) |
| Groq | OpenAI-compatible (llama-3, mixtral, …) |
| Mistral | Direct REST |
| DeepSeek | OpenAI-compatible |
| Kimi | OpenAI-compatible |
| Ollama | Local inference (any model) |
| OpenRouter | Multi-provider gateway |

---

## Connectors

| Connector | Implementation |
|---|---|
| Camera | `image_picker` — native camera capture |
| Gallery | `image_picker` — native photo library |
| Documents | `file_picker` — any file type |
| Link | URL input dialog |
| Web Search | DuckDuckGo Instant Answer API (no key needed) |
| GitHub | GitHub Search API (optional token for rate limits) |
| Notion | Notion Search API (token via secure storage) |
| Gmail | Gmail messages API (Google OAuth token via secure storage) |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x (`flutter --version`)
- Dart 3.8+

### Run

```bash
flutter pub get
flutter run -d macos        # or -d windows / -d chrome / -d android
```

### With Supabase (optional)

```bash
flutter run -d macos \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Run `supabase_schema.sql` in your Supabase SQL editor to create the schema (projects, chats, messages, provider metadata). API keys are **never** stored in Supabase.

---

## Security Model

- API keys are stored only in `flutter_secure_storage` on the local device
- Keys are never logged, synced, or sent to a custom backend
- AI calls go directly from the Flutter client to the provider
- Supabase sync is opt-in and does not include key material

---

## Credential Requirements (for full feature set)

| Feature | Credential Needed |
|---|---|
| Supabase auth + sync | `SUPABASE_URL`, `SUPABASE_ANON_KEY` via dart-define |
| Google Login | Google OAuth client ID/secret + Supabase redirect URL |
| Apple Login | Apple Services ID, Team ID, Key ID, private key + redirect URL |
| Notion connector | Notion integration token (`connector_token_notion`) |
| Gmail connector | Google OAuth access token (`connector_token_gmail`) |
| GitHub connector | Optional token (`connector_token_github`) for higher rate limits |

---

## License

MIT
