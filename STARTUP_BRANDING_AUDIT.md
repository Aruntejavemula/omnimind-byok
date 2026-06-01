# Startup Branding Audit

The current rebuilt Omnimind/Mio app does **not** preserve the previous startup flow completely.

| Area | Current Rebuild State | Correct Direction |
| --- | --- | --- |
| Splash screen | Removed; app routes directly to chat shell | Restore a dedicated splash screen |
| Official handshake Lottie | Not wired; no `lottie` dependency and no `assets/animations/` registration | Restore `assets/animations/mascot.json` as the official brand mark |
| Sidebar logo | Uses a text `M` badge | Replace/augment with handshake Lottie icon |
| Login screen | Old repo only had a placeholder `Login` screen; rebuild currently has no real login screen | Build a real premium login/welcome screen with the handshake brand |
| Startup routing | Single route `/` to `ShellScreen` | Add splash -> welcome/login -> chat flow |

Decision: fix from the beginning by restoring the handshake Lottie as the official app icon/brand asset, adding a branded splash screen, and adding a real premium welcome/login screen instead of keeping the current direct-to-chat startup.
