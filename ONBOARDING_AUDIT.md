# Mio Onboarding Audit

The current rebuilt app now restores the intended **eight-screen onboarding flow** after the official handshake splash and welcome/login entry screen.

| Flow area | Restored current app |
| --- | --- |
| Startup sequence | Splash → Welcome/Login → 8-step Onboarding → Chat |
| Router paths | `/`, `/welcome`, `/onboarding`, `/chat` |
| Onboarding implementation | `OnboardingScreen` with `_totalPages = 8` and a locked `PageView` |
| Welcome completion key | `mio_welcome_complete` in shared preferences |
| Onboarding completion key | `mio_onboarding_complete` in shared preferences |
| Local-first warning | Preserved before local-only users enter onboarding |

The restored eight pages are:

| # | Screen | Purpose |
| ---: | --- | --- |
| 1 | Name | Capture first and last name for personalization |
| 2 | Problem | Explain the problems Mio avoids: filler, lock-in, unclear cost |
| 3 | Solution | Present Mio as a direct, local-first AI workspace |
| 4 | BYOK | Explain bring-your-own-key and supported provider flexibility |
| 5 | Preferences | Let users select AI usage focus areas |
| 6 | Add API Key | Let users optionally save a provider key to secure device storage |
| 7 | Plan | Let users start free/local-first while keeping Pro as a future placeholder |
| 8 | Ready | Final ready screen before entering chat |

Implementation note: the pricing page was restored in a safer MVP form. It does **not** promise live subscriptions or billing until those systems are implemented. It presents Free/Local-first as the default and keeps Pro as a future placeholder.
