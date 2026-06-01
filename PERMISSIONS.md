# Mio Permissions

Mio now uses explicit platform permission declarations and user-facing pre-permission prompts before sensitive actions.

| Feature | Permission behavior | Status |
| --- | --- | --- |
| Camera | Shows a Mio explanation dialog, then asks the OS for camera permission before opening the native camera picker. | Implemented |
| Gallery / Photos | Shows a Mio explanation dialog, then asks the OS for photo access before opening the image picker. | Implemented |
| Documents | Shows a Mio explanation dialog and uses the native file picker for user-selected files. | Implemented |
| Notifications | Shows a Mio explanation dialog, then asks the OS for notification permission. | Implemented |
| Internet / Connectors | Android and macOS network permissions are declared where needed. | Implemented |

## Platform declarations

Android permissions were added for camera, media/photo access, notifications, storage compatibility, and internet access. iOS and macOS usage descriptions were added for camera, photo library, documents, notifications, and network usage. macOS sandbox entitlements were updated for client network access, camera access, and user-selected files.

## Connector note

The connector credential note remains unchanged: Web Search and GitHub public search can work without user OAuth credentials, while Notion and Gmail require user-provided OAuth/API tokens before they can access private workspace or email data.
