from pathlib import Path

root = Path('/home/ubuntu/omnimind-byok')
main = root / 'lib' / 'main.dart'
text = main.read_text()

checks = []
checks.append(('main.dart exists', main.exists()))
checks.append(('pubspec exists', (root / 'pubspec.yaml').exists()))
checks.append(('supabase schema exists', (root / 'supabase_schema.sql').exists()))
checks.append(('provider list includes 18 providers', text.count('AiProviderConfig(id:') >= 18))
checks.append(('secure storage used', 'FlutterSecureStorage' in text))
checks.append(('zero fluff toggle exists', 'ZeroFluffToggle' in text))
checks.append(('direct OpenAI-compatible call exists', '_callOpenAiCompatible' in text))
checks.append(('Anthropic call exists', '_callAnthropic' in text))
checks.append(('Gemini call exists', '_callGemini' in text))
checks.append(('braces balanced', text.count('{') == text.count('}')))
checks.append(('parentheses balanced', text.count('(') == text.count(')')))
checks.append(('brackets balanced', text.count('[') == text.count(']')))

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(f'{"PASS" if ok else "FAIL"}: {name}')

if failed:
    raise SystemExit(f'Failed checks: {failed}')
print('All lightweight checks passed.')
