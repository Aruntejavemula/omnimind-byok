from pathlib import Path
import re

def inventory(root):
    files = list(Path(root).rglob('*.dart'))
    screen_files = []
    classes = []
    for f in files:
        txt = f.read_text(errors='ignore')
        rel = str(f.relative_to(root))
        if re.search(r'(screen|page|settings|subscription|usage|api|key|preference)', rel, re.I):
            screen_files.append(rel)
        for m in re.finditer(r'class\s+([A-Za-z0-9_]*(?:Screen|Page|Settings|Subscription|Usage|Preferences|Preference|Api|API|Keys|Billing|Limits|Panel|Dialog)[A-Za-z0-9_]*)\s+extends\s+([^\{]+)', txt):
            classes.append((rel, m.group(1), ' '.join(m.group(2).split())))
    return screen_files, classes

current_files, current_classes = inventory('/home/ubuntu/omnimind-byok/lib')
legacy_files, legacy_classes = inventory('/home/ubuntu/Chatbot_Mio/frontend/lib')

print('CURRENT_SCREENISH_FILE_COUNT', len(current_files))
for f in current_files: print('CURRENT_FILE', f)
print('CURRENT_SCREENISH_CLASS_COUNT', len(current_classes))
for rel, name, base in current_classes: print('CURRENT_CLASS', name, '::', rel)
print('LEGACY_SCREENISH_FILE_COUNT', len(legacy_files))
for f in legacy_files: print('LEGACY_FILE', f)
print('LEGACY_SCREENISH_CLASS_COUNT', len(legacy_classes))
for rel, name, base in legacy_classes: print('LEGACY_CLASS', name, '::', rel)
