# OmniMind BYOK

Bring Your Own Key (BYOK) integration for OmniMind — connect your own AI provider API keys.

## Features

- Support for multiple AI providers (OpenAI, Anthropic, etc.)
- Secure key management
- Unified API interface

## Project Structure

```
omnimind-byok/
├── src/
│   ├── providers/       # AI provider integrations
│   ├── api/             # API routes
│   ├── config/          # Configuration management
│   └── utils/           # Shared utilities
├── tests/               # Test suite
├── .env.example         # Environment variable template
├── .gitignore
└── README.md
```

## Getting Started

1. Copy `.env.example` to `.env` and fill in your API keys.
2. Install dependencies.
3. Run the project.
