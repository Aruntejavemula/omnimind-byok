from pathlib import Path
import re
root = Path('/home/ubuntu/omnimind-byok')
files = list((root/'lib').rglob('*.dart'))
all_text = '\n'.join(f.read_text(errors='ignore') for f in files)
main = (root/'lib/main.dart').read_text(errors='ignore')

routes = []
for m in re.finditer(r"GoRoute\s*\((.*?)\)", main, re.S):
    block = m.group(1)
    path = re.search(r"path:\s*'([^']+)'", block)
    builder = re.search(r"builder:\s*\([^=]*=>\s*(?:const\s+)?([A-Za-z0-9_]+)", block)
    routes.append((path.group(1) if path else '?', builder.group(1) if builder else '?'))

classes = []
for f in files:
    txt = f.read_text(errors='ignore')
    for m in re.finditer(r"class\s+([A-Za-z0-9_]*(?:Screen|Page|View|Settings|Subscription|Usage|Preferences|Api|API|Keys|Billing|Limits)[A-Za-z0-9_]*)\s+extends\s+([^\{]+)", txt):
        classes.append((str(f.relative_to(root)), m.group(1), ' '.join(m.group(2).split())))

onboarding_pages = re.search(r"children:\s*\[(.*?)\],\s*\n\s*\)", main[main.find('PageView('):], re.S)
page_methods = re.findall(r"Widget\s+(_buildPage[A-Za-z0-9_]+)\(", main)

settings_start = main.find('class SettingsButton')
settings_end = main.find('class ProviderPill')
if settings_end < settings_start:
    settings_end = main.find('class Composer')
settings_block = main[settings_start:settings_end] if settings_start != -1 else ''
settings_methods = re.findall(r"Widget\s+(_[A-Za-z0-9_]*(?:Settings|Preference|Api|API|Usage|Limit|Subscription|Billing|Plan|Key)[A-Za-z0-9_]*)\(", settings_block)
settings_titles = sorted(set(re.findall(r"Text\('([^']*(?:Settings|Preferences|API|Keys|Usage|Limits|Subscription|Billing|Plan|Provider|Model)[^']*)'", settings_block)))

markers = ['Preferences','API Keys','Usage','Limits','Subscription','Billing','Plan','Settings','Privacy','Theme','Account','Provider']
marker_counts = {m: len(re.findall(re.escape(m), main, re.I)) for m in markers}

print('ROUTES_COUNT', len(routes))
for r in routes:
    print('ROUTE', r[0], '=>', r[1])
print('SCREEN_CLASS_COUNT', len(classes))
for c in classes:
    print('CLASS', c[0], c[1], 'extends', c[2])
print('ONBOARDING_PAGE_METHOD_COUNT', len(page_methods))
for p in page_methods:
    print('ONBOARDING_PAGE_METHOD', p)
print('SETTINGS_METHOD_COUNT', len(settings_methods))
for m in settings_methods:
    print('SETTINGS_METHOD', m)
print('SETTINGS_TITLE_COUNT', len(settings_titles))
for t in settings_titles:
    print('SETTINGS_TITLE', t)
print('MARKER_COUNTS')
for k,v in marker_counts.items():
    print(k, v)
print('FILES')
for f in files:
    print(f.relative_to(root))
