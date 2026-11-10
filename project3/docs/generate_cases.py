"""공개 어셈블리 테스트의 case별 입력·연산·기대값을 원문에서 추출한다."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
parts = ['# 공개 어셈블리 테스트의 전체 55개 case\n',
         '[테스트 해설](testing.ko.md) · [분석 안내](README.ko.md)\n',
         '아래 표는 원본 .asm에서 추출했다. 기대값은 테스트 작성자가 지정한 값이며, '
         '실제 HDL 실행 결과를 뜻하지 않는다. `gp`는 현재 case 번호를 담고 '
         '`bne`는 값이 다르면 fail로 이동한다. label에 붙은 번호가 연속되지 않는 파일도 있다.\n',
         '입력 설정에는 검사 대상 연산 이전의 li를 표시한다. LUI 테스트의 lui/srai는 연산 열에 함께 표시한다. '
         '원본 줄은 test label의 시작 위치이다.\n']
total = 0
for path in sorted((ROOT / 'tests' / 'asm').glob('*.asm')):
    source = path.read_text(encoding='utf-8-sig')
    matches = list(re.finditer(r'^test_(\d+):\s*(.*?)(?=^(?:test_\d+|pass|fail):|\Z)', source, re.M | re.S))
    parts += [f'## {path.name} — {len(matches)}개\n',
              f'[원본](../tests/asm/{path.name})\n',
              '| case | 원본 줄 | 입력 설정 | 검사 연산 | 기대값 설정 | 실패 시 이동 조건 |\n'
              '|---|---:|---|---|---|---|']
    for m in matches:
        number = int(m.group(1))
        commands = [s.split('#',1)[0].strip() for s in m.group(2).splitlines()]
        commands = [s for s in commands if s]
        gp = [s for s in commands if re.match(r'li\s+gp\s*,', s)]
        assert len(gp) == 1 and int(gp[0].split(',')[1].strip(), 0) == number
        expected = [s for s in commands if re.match(r'li\s+x29\s*,', s)]
        branch = [s for s in commands if s.startswith('bne ')]
        assert len(expected) == 1 and len(branch) == 1 and branch[0].endswith('fail')
        inputs = [s for s in commands if s.startswith('li ') and s not in gp + expected]
        ops = [s for s in commands if s not in inputs + gp + expected + branch]
        assert ops, (path.name, number)
        fmt = lambda xs: '<br>'.join('`'+s+'`' for s in xs) if xs else '없음'
        line = source[:m.start()].count('\n') + 1
        parts.append(f'| test_{number} / gp={number} | {line} | {fmt(inputs)} | {fmt(ops)} | {fmt(expected)} | {fmt(branch)} |')
    parts.append('')
    total += len(matches)
assert total == 55, total
(ROOT / 'docs' / 'tests_cases.ko.md').write_text('\n\n'.join(parts[:4]) + '\n\n' + '\n'.join(parts[4:]) + '\n', encoding='utf-8')
print(f'Assembly source extraction: {total} cases across 5 files; gp/expected/bne structure checked.')
