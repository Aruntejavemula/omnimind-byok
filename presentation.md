# OmniMind BYOK
### Arun Teja Vemula

---

## Slide 1: What Is OmniMind BYOK?

OmniMind BYOK is a **premium, cross-platform AI chat application** where users bring their own API keys. It eliminates the middleman: chat calls go directly from the Flutter client to OpenAI, Anthropic, Gemini, and 15+ other providers using the user's own credentials.

**The problem it solves:** Most AI chat apps require a subscription or proxy every request through a proprietary server. OmniMind gives power users full control — their keys, their models, their data — with no server in the critical path and no cost markup.

**Platforms:** macOS · Windows · Linux · Web · iOS · Android (single codebase)

---

## Slide 2: Key Features

| Feature | Description |
|---|---|
| **18+ AI Providers** | OpenAI, Anthropic, Gemini, Groq, Mistral, DeepSeek, Kimi, Ollama, OpenRouter |
| **Direct API Calls** | Client calls providers directly — no custom server in the critical path |
| **Secure Key Storage** | `flutter_secure_storage` — keys never logged, synced, or sent to any backend |
| **Provider Selector** | Switch providers per-chat with per-provider model menus |
| **Project Organization** | Organize chats into projects with full local persistence |
| **Connectors** | Camera, Gallery, Documents, Link, Web Search, GitHub, Notion, Gmail |
| **Optional Supabase Sync** | Opt-in auth and encrypted sync; keys never reach the cloud |
| **Premium UI** | Cream/Persian-orange design system, Lottie animations, shimmer states |

---

## Slide 3: Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│              Flutter App (Dart)                           │
│   macOS · Windows · Linux · Web · iOS · Android          │
│   Riverpod state · go_router navigation · Dio HTTP       │
├──────────────────────────────────────────────────────────┤
│                    Security Layer                         │
│         flutter_secure_storage (local device only)       │
└──────────────────┬───────────────────────────────────────┘
                   │ Direct HTTPS (user's own key)
         ┌─────────┴──────────────────────────────────────┐
         │  AI Providers                                   │
         │  OpenAI · Anthropic · Gemini · Groq · Mistral  │
         │  DeepSeek · Kimi · Ollama · OpenRouter · …     │
         └─────────────────────────────────────────────────┘

Optional:  Supabase (auth + sync) · Railway Python backend
```

---

## Slide 4: App Flow & Navigation

**4 routes, linear user journey:**

```
/ (Splash + Lottie animation)
    │
    ▼
/welcome  (Login — Google / Apple / email)
    │
    ▼
/onboarding  (8-step guided setup: providers, keys, preferences)
    │
    ▼
/chat  (Main app — sidebar, projects, model selector, connectors)
```

The onboarding flow walks users through adding their first API key, selecting a default provider and model, configuring UI preferences, and optionally connecting Supabase sync — before they ever see the chat interface.

---

## Slide 5: Tech Stack

### Frontend (Flutter / Dart)
- **Flutter 3.x + Dart 3.8** — single codebase, six platforms
- **Riverpod 2** — reactive state management
- **go_router 14** — declarative navigation
- **Dio 5** — HTTP client for provider API calls
- **flutter_secure_storage** — encrypted local key vault
- **Lottie 3 + Shimmer 3** — premium animation and loading states
- **Google Fonts + flutter_markdown** — typography and chat rendering

### Optional Backend (Python)
- **FastAPI** — Railway-deployed backend placeholder
- **Supabase** — auth, database, optional E2EE sync

---

## Slide 6: Provider Integration

One React codebase → four distribution targets (Flutter equivalent: one codebase, six platforms):

| Provider | API Style | Models |
|---|---|---|
| OpenAI | Native REST | GPT-4o, GPT-4, GPT-3.5, o1 |
| Anthropic | Native REST | Claude 3.5 Sonnet, Opus, Haiku |
| Google Gemini | Native REST | Gemini 1.5 Pro, Flash |
| Groq | OpenAI-compatible | Llama 3, Mixtral, Gemma |
| Mistral | Native REST | Mistral Large, Small |
| DeepSeek | OpenAI-compatible | DeepSeek V3 |
| Kimi | OpenAI-compatible | Moonshot |
| Ollama | Local REST | Any local model |
| OpenRouter | Multi-provider gateway | 200+ models |

---

## Slide 7: Connectors System

The `+` menu in the chat composer exposes eight connector types:

```
User taps +
      │
      ├──► Camera  (image_picker — native capture)
      ├──► Gallery  (image_picker — photo library)
      ├──► Document  (file_picker — any file)
      ├──► Link  (URL dialog → attaches to message)
      ├──► Web Search  (DuckDuckGo Instant Answer API — no key)
      ├──► GitHub  (Search API — optional rate-limit token)
      ├──► Notion  (Search API — integration token required)
      └──► Gmail  (Messages API — Google OAuth token required)
```

Connector results are injected directly into the chat context as structured message attachments.

---

## Slide 8: Security Model

| Layer | Implementation |
|---|---|
| **Key Storage** | `flutter_secure_storage` — OS-level encryption (Keychain / Keystore / DPAPI) |
| **Transport** | Direct HTTPS from device to provider; no custom proxy server |
| **No Logging** | Keys are never printed, serialized to logs, or included in error reports |
| **No Cloud Sync of Keys** | Supabase schema intentionally excludes key fields |
| **Permission Gating** | Camera, gallery, and file access request runtime permissions via `permission_handler` |
| **Optional Auth** | Supabase auth is opt-in — the app functions fully offline with local keys |

---

## Slide 9: Cross-Platform Strategy

Single Flutter codebase → six targets:

```
lib/ (Dart source)
      │
      ├──► macOS  (AppKit wrapper, Keychain storage)
      ├──► Windows  (Win32 wrapper, DPAPI storage)
      ├──► Linux  (GTK wrapper, libsecret storage)
      ├──► Web  (Chrome/Safari, localStorage fallback)
      ├──► iOS  (UIKit wrapper, Keychain storage)
      └──► Android  (Kotlin wrapper, Keystore storage)
```

Platform-specific folders (`macos/`, `windows/`, `linux/`, `web/`, `ios/`, `android/`) handle only shell configuration and permissions. All product code lives in `lib/`.

---

## Slide 10: Project Structure

```
omnimind-byok/
├── lib/
│   ├── providers/          # Riverpod state (keys, models, chats, prefs)
│   ├── screens/            # Splash, Welcome, Onboarding, Chat
│   ├── widgets/            # Message bubbles, provider cards, sidebar
│   ├── connectors/         # Camera, docs, web search, GitHub, Notion, Gmail
│   ├── services/           # AI client adapters, storage, Supabase bridge
│   └── router.dart         # go_router: /, /welcome, /onboarding, /chat
├── backend/                # Optional Python/FastAPI (Railway)
├── assets/
│   ├── animations/         # mascot.json (Lottie)
│   └── icons/providers/    # OpenAI, Anthropic, Gemini, Groq… PNGs
└── pubspec.yaml
```

---

## Slide 11: Skills Demonstrated

- **Flutter cross-platform engineering** — single codebase targeting macOS, Windows, Linux, Web, iOS, Android
- **Direct API integration** — 18+ AI provider clients with streaming, error handling, and model enumeration
- **Security-first mobile design** — OS-level key encryption, no server proxying, explicit permission model
- **Reactive state management** — Riverpod 2 with clean provider/consumer separation
- **Connector architecture** — extensible `+` menu system with typed attachment model
- **Premium UI engineering** — Lottie animations, shimmer states, custom design system
- **Optional backend architecture** — FastAPI/Railway backend decoupled behind dart-define flags
- **Supabase integration** — Auth, database schema design, optional sync with security boundaries

---

## Summary

OmniMind BYOK demonstrates end-to-end Flutter engineering for a privacy-first, multi-platform AI product:
- A single Dart codebase targeting six platforms
- Direct-to-provider AI calls with secure local key management
- A rich connector system, premium UI, and optional cloud sync

> **Stack:** Flutter · Dart · Riverpod · go_router · Dio · flutter_secure_storage · Supabase · Python · Lottie
