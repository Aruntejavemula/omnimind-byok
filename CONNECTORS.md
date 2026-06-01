# Mio Connector Status

This file records the real connector wiring added to the `+` menu.

| Option | Current Behavior | Credential Needed |
| --- | --- | --- |
| Camera | Opens native camera through `image_picker` and attaches the captured image path/name to chat. | Device camera permission |
| Gallery | Opens native gallery/image picker and attaches selected image paths/names to chat. | Photo/library permission |
| Document | Opens native file picker through `file_picker` and attaches selected file paths/names to chat. | File access permission |
| Link | Opens a URL input dialog and attaches the link to chat. | None |
| Web Search | Calls DuckDuckGo Instant Answer API with the current composer query and adds results into chat. | None |
| GitHub | Calls GitHub repository search API with the current composer query. Optional token improves rate limits/private access. | Optional `connector_token_github` in secure storage |
| Notion | Calls Notion Search API with the current composer query. | Required `connector_token_notion` in secure storage |
| Gmail | Calls Gmail messages API with the current composer query. | Required Google OAuth access token as `connector_token_gmail` in secure storage |

## Important Notes

Camera/gallery support depends on platform permissions and plugin support. For desktop builds, document picking is reliable, while camera behavior may require platform-specific capture support or a desktop camera plugin.

For production Gmail and Notion, the correct implementation is OAuth with a Supabase Edge Function or Railway backend callback. The app-side API handlers are now present, but OAuth credential flow still needs actual client IDs, secrets, redirect URLs, and consent-screen setup from your Google/Notion developer accounts.
