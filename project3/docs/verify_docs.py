"""문서 링크, RTL 원문 대응, 파일 해시, 표 구조를 확인한다. HDL 검증은 아니다."""
from pathlib import Path
import hashlib
import html
import json
import re

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / 'docs'
manifest = json.loads((DOCS / 'line_coverage.json').read_text(encoding='utf-8'))
total = 0
for entry in manifest:
    source = ROOT / entry['file']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == entry['sha256']
    lines = source.read_text(encoding='utf-8-sig').splitlines()
    report = DOCS / 'rtl' / (source.name + '.ko.md')
    body = report.read_text(encoding='utf-8').split('## 줄별 해설\n', 1)[1]
    rows = re.findall(r'^\| (\d+) \| <code>(.*?)</code> \| (.*?) \|$', body, re.M)
    assert len(rows) == len(lines) == entry['lines'] == entry['explained_rows']
    for number, (n, text, explanation) in enumerate(rows, 1):
        assert int(n) == number
        assert html.unescape(text) == (lines[number-1] if lines[number-1] else '(빈 줄)')
        assert explanation.strip()
        assert '|' not in explanation
    total += len(rows)
count = 0
for report in DOCS.rglob('*.md'):
    body = report.read_text(encoding='utf-8')
    # 코드 예제에 들어 있는 표현을 실제 문서 링크로 오인하지 않는다.
    body = re.sub(r'```.*?```', '', body, flags=re.S)
    for destination in re.findall(r'\[[^\]]*\]\(([^)]+)\)', body):
        if destination.startswith(('http:', 'https:', '#')):
            continue
        target = (report.parent / destination.split('#',1)[0]).resolve()
        assert target.exists(), (report, destination)
        count += 1
case_report = (DOCS / 'tests_cases.ko.md').read_text(encoding='utf-8')
assert len(re.findall(r'^\| test_\d+ / gp=\d+ \|', case_report, re.M)) == 55
print(json.dumps({'rtl_files':len(manifest), 'verified_line_rows':total, 'assembly_case_rows':55, 'local_links_checked':count, 'result':'PASS (documentation integrity only)'}, ensure_ascii=False))
