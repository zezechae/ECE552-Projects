"""정적 설명 데이터로 RTL 전체 줄별 문서를 재생성하고 누락을 검사한다."""
import sys
sys.dont_write_bytecode = True
import hashlib
import json
import re
import runpy
from build_line_notes import ROOT, OUT, add, NOTES, INTRO

for name in ('line_notes_memory.py', 'line_notes_hart.py'):
    runpy.run_path(str(ROOT / 'docs' / name), init_globals={'add': add, 'NOTES': NOTES})

# 주석도 한국어로 설명한다. 같은 구간의 문장은 각각 독립된 표 행으로 남긴다.
comment_notes = {
    'fetch.v': {38:'PC를 저장하는 상승 에지 순차 always 블록을 닫는다. reset이나 halt 조건에 따라 상태 갱신 또는 유지가 결정된다.'},
    'alu_control.v': {15:'R형, I형, branch, 그 외 덧셈이라는 네 분류를 설명하는 주석.'},
    'alu.v': {
        19:'signed 타입이나 $signed 변환 없이 비트 논리로 signed 작다 비교를 구현한다는 주석.',
        20:'두 수의 부호가 같은 경우에 관한 설명의 첫 줄이다.',
        21:'같은 부호끼리는 unsigned 비교와 순서가 같고 다른 부호만 별도 처리하면 된다는 설명.',
        30:'시프트 크기 0~31별로 고정 배선을 나열하는 왼쪽 논리 시프트 구간의 제목.',
        70:'위쪽에 0을 채우는 오른쪽 논리 시프트 구간 제목.',
        110:'위쪽에 부호 비트를 채우는 오른쪽 산술 시프트 구간 제목.',
    },
    'control_unit.v': {
        35:'funct3와 funct7의 허용 인코딩을 검사하는 구간 제목.',
        51:'제어기는 원시 제어를 출력하고 trap에 따른 차단은 hart에서 한다는 설계 설명.',
        61:'ALUSrc1 코드 설명: 00=rs1, 01=PC+4, 10=PC, 11=0.',
        65:'ALUSrc2 코드 설명: 00=rs2, 01=immediate, 10=0.',
        69:'ALUOp의 네 분류 설명: 00=덧셈, 01=branch, 10=R ALU, 11=I ALU.',
        70:'00 덧셈 경로를 쓰는 명령: LUI, AUIPC, LOAD, STORE, JAL, JALR.',
        73:'one-hot 형식의 각 비트 위치: R/I/S/B/U/J 순서가 bits 0~5에 대응한다.',
    },
    'dmem_mask_gen.v': {
        12:'byte 접근은 offset에 따라 네 mask 중 하나를 사용한다는 주석.',
        13:'half 접근은 하위 또는 상위 두 byte를 함께 선택한다는 주석.',
        14:'word 접근은 네 byte 모두를 선택한다는 주석.',
        16:'아래에 byte offset과 크기 인코딩을 설명한다는 주석.',
        19:'여러 줄 주석의 시작. 다음 줄들에서 misaligned 조건을 문장으로 설명한다.',
        20:'half 접근은 offset의 bit0=1이면 비정렬이라는 설명.',
        21:'word 접근은 offset 00 이외이면 비정렬이라는 설명.',
        22:'byte 접근에는 자연 정렬 오류가 없다는 설명.',
        23:'정렬 오류는 메모리 명령일 때만 유효하고 그 외에는 0이어야 한다는 설명 및 주석 종료.',
    },
    'store_align.v': {
        11:'store 데이터를 대상 byte lane으로 이동한다는 설명.',
        12:'mask 생성기가 고른 lane과 맞추며 고정 이동량만 사용한다는 설명.',
    },
    'imm.v': {
        3:'immediate 생성기가 32비트 부호 확장 값을 만든다는 설명의 시작.',
        4:'현재 명령어에서 immediate를 추출하며 순수 조합 블록이라는 설명.',
        5:'명령어 디코더에 포함해 사용할 구성 요소라는 설명.',
        7:'원본 명령어 입력에서 필요한 immediate 비트를 뽑는다는 설명.',
        8:'뽑은 비트들을 최종 immediate로 조립한다는 설명.',
        10:'opcode를 보고 제어기가 명령 형식을 정해 전달한다는 설명.',
        11:'형식 선택이 one-hot 인코딩이라는 설명.',
        12:'형식 bit0은 R형.',13:'형식 bit1은 I형.',14:'형식 bit2는 S형.',
        15:'형식 bit3은 B형.',16:'형식 bit4는 U형.',17:'형식 bit5는 J형.',
        19:'출력이 32비트 부호 확장 immediate라는 설명. U형은 상위 20비트와 12개 0으로 구성된다.',
        20:'R형에는 immediate 자체가 없다는 안내의 시작.',
        21:'R형일 때 immediate는 사용하지 않는 값으로 취급할 수 있다는 설명.',
        22:'형식 목록의 완전성을 위해 R형 선택도 포함한다는 설명.',
    },
    'rf.v': {
        3:'레지스터 파일의 원소 폭이 32비트라는 모듈 설명.',
        4:'깊이가 32개이고 비동기 읽기 포트가 두 개라는 설명.',
        5:'두 레지스터를 조합식으로 동시에 읽고 한 포트로 동기 쓰기한다는 설명.',
        6:'쓰기는 다음 활성 클록 에지에서 저장 상태에 반영된다는 설명.',
        7:'x0 읽기는 0이고 x0 쓰기는 무시한다는 아키텍처 규칙.',
        9:'매개변수를 1로 하면 bypass 모드를 활성화한다는 설명.',
        10:'bypass에서는 write 포트의 값을 read 포트가 볼 수 있다는 설명.',
        11:'이 우회 전달은 클록 에지를 기다리지 않고 조합식으로 동작한다는 설명.',
        12:'파이프라인에서 forwarding 최적화로 사용할 수 있다는 설명.',
        13:'현재 단일 사이클에서는 bypass가 잘못된 동작을 유발할 수 있다는 경고.',
        15:'원래 과제는 두 모드를 구현하고 검증하도록 요구한다는 주석.',
        16:'project3/4에서는 0, project5에서는 1을 사용하도록 안내하는 과제 주석.',
        19:'다음 포트가 전체 클록이라는 주석.',21:'다음 reset이 동기식 active-high라는 주석.',
        23:'두 읽기 포트가 비동기식이라는 설명. 여기서 비동기는 별도의 비동기 클록이라는 뜻이 아니다.',
        24:'읽기 주소 변화에 조합적으로 반응해 클록 대기 없이 데이터가 나온다는 뜻이다. 실제 전파 지연은 존재한다.',
        26:'첫 번째 읽기 포트의 주소 범위가 0~31임을 설명한다.',
        29:'두 번째 읽기 포트도 주소 0~31과 데이터 출력을 가진다는 주석.',
        32:'쓰기 포트는 읽기와 달리 클록에 동기화한다는 설명.',
        33:'활성 클록 에지 뒤에 저장된 쓰기 결과가 읽기 포트에 보인다는 설명.',
        35:'다음 세 입력이 쓰기 허용·주소·데이터임을 설명한다.',
    },
}
for f, entries in comment_notes.items():
    NOTES[f].update(entries)

section_titles = {
    'Instruction fields':'명령어 필드 추출 구간 제목.',
    'Control unit (pure function of the instruction word)':'명령어만으로 출력이 정해지는 조합 제어기 구간 제목.',
    'Immediate generator':'즉시값 생성기 연결 구간 제목.',
    'Register file (BYPASS_EN must be 0 in a single-cycle design)':'레지스터 파일 연결 구간. 단일 사이클은 bypass를 꺼야 한다는 안내.',
    'ALU operand muxes':'ALU 피연산자 선택 mux 구간 제목.',
    'src1: 00 rs1, 01 PC+4, 10 PC, 11 zero':'첫 operand 선택 코드 설명: rs1, PC+4, PC, 0.',
    'src2: 00 rs2, 01 imm,  10 zero (11 unused -> zero)':'둘째 operand 선택 설명. 11도 구현상 0을 선택한다.',
    'ALU control + ALU':'세부 제어와 ALU 연결 구간 제목.',
    'Trap detection':'불법 명령·비정렬 접근을 검출하는 구간 제목.',
    'Fetch / PC':'PC와 다음 주소 계산기 연결 구간 제목.',
    'Data memory interface':'데이터 메모리의 mask·store 배치·load 확장 구간 제목.',
    'Write-back':'최종 결과와 레지스터 쓰기 허용을 결정하는 구간 제목.',
    'Retire interface':'명령 실행을 외부에서 관측하는 retire 인터페이스 구간 제목.',
}

def structural(line):
    s = line.strip()
    if not s:
        return '가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다.'
    if s == '`default_nettype none':
        return '선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다.'
    if s == '`default_nettype wire':
        return '뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다.'
    if s == ');':
        return '현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다.'
    if s == 'endmodule':
        return '현재 모듈 정의를 끝낸다.'
    if s == 'endcase':
        return 'case 선택 구문을 닫는다. 앞에서 선택된 한 항목의 대입으로 결과가 결정된다.'
    if s == 'end':
        return '가장 가까운 begin으로 연 블록을 닫는다. 여기서는 always 조합 블록의 끝이다.'
    if s.startswith('//'):
        content = s[2:].strip()
        if not content:
            return '주석 안의 빈 구분 줄. 동작하는 문장이 아니다.'
        if set(content) == {'-'}:
            return '주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다.'
        if content in section_titles:
            return section_titles[content]
    return None

def cell(s):
    # 표 구분자와 소스의 비트 OR를 충돌시키지 않는다.
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('|', '&#124;').replace('`', '&#96;')

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    files = sorted((ROOT / 'rtl').glob('*'))
    if {p.name for p in files if p.is_file()} != set(NOTES):
        raise AssertionError('RTL 파일 목록과 설명 대상 목록이 다름')
    for path in files:
        if not path.is_file():
            continue
        lines = path.read_text(encoding='utf-8-sig').splitlines()
        sha = hashlib.sha256(path.read_bytes()).hexdigest()
        rows = []
        for number, source in enumerate(lines, 1):
            explanation = NOTES[path.name].get(number) or structural(source)
            if not explanation:
                raise AssertionError(f'설명 누락: {path.name}:{number}: {source}')
            explanation = explanation.replace('|', '&#124;')
            rows.append(f'| {number} | <code>{cell(source) if source else "(빈 줄)"}</code> | {explanation} |')
        text = (f'# {path.name} — 전체 줄별 해설\n\n'
                f'[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/{path.name})\n\n'
                f'원본 물리적 줄 수: **{len(lines)}줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. '
                '여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.\n\n'
                + INTRO[path.name] + '\n\n## 줄별 해설\n\n'
                '| 원본 줄 | 원문 | 한국어 설명 및 문법 |\n|---:|---|---|\n'
                + '\n'.join(rows) + '\n\n'
                f'원본 SHA-256: `{sha}`\n')
        target = OUT / (path.name + '.ko.md')
        target.write_text(text, encoding='utf-8')
        # 실제 생성 결과의 행이 원본과 일대일 대응하는지 다시 확인한다.
        written = target.read_text(encoding='utf-8')
        table = written.split('## 줄별 해설\n', 1)[1]
        found = [int(n) for n in re.findall(r'^\| (\d+) \|', table, re.M)]
        assert found == list(range(1, len(lines)+1)), path.name
        for i, source in enumerate(lines, 1):
            expected = f'| {i} | <code>{cell(source) if source else "(빈 줄)"}</code> |'
            assert expected in written, (path.name, i)
        manifest.append({'file': 'rtl/' + path.name, 'lines': len(lines), 'explained_rows': len(found), 'sha256': sha})
    (ROOT / 'docs' / 'line_coverage.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
    print(json.dumps({'files':len(manifest), 'source_lines':sum(x['lines'] for x in manifest), 'explained_rows':sum(x['explained_rows'] for x in manifest), 'coverage':'100%'}, ensure_ascii=False))

if __name__ == '__main__':
    main()
