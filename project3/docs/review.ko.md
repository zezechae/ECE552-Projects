# 구현 검토, 주의점, 분석의 검증 범위

[분석 안내](README.ko.md) · [전체 구조](architecture.ko.md) · [테스트](testing.ko.md)

이 문서는 수정 제안과 현재 동작을 구분한다. 사용자의 요청은 분석이므로 RTL과 tb, tests 원본은 변경하지 않았다. 아래의 문제점도 수정된 상태가 아니다.

## 1. JALR에서 funct3 검사가 빠짐

**위치:** control_unit.v 30, 45, 47~49행.

현재 코드는 opcode=1100111이면 funct3 값과 관계없이 JALR 계열로 허용한다. 45행의 `jalr_ok`는 주석 처리되어 있다. 따라서 funct3=001 등의 인코딩도 illegal=0이 되고 점프와 rd 쓰기를 수행할 수 있다.

공식 JALR 인코딩에서 funct3는 000이다. “RV32 spec에 언급되지 않음”이라는 기존 주석은 부정확하다. 이 부분은 [RISC-V 공식 인코딩 표의 JALR 행](https://github.com/riscv/riscv-isa-manual/blob/main/src/unpriv/rv-32-64g.adoc)과 대조했다. 다른 funct3를 JALR로 실행하는 것을 표준 JALR 지원으로 설명해서는 안 된다. 예약 인코딩을 어느 범위까지 illegal로 보고할지는 과제의 illegal 판정 요구사항도 확인해야 한다.

디코더가 표준 JALR만 허용하도록 하려는 경우에는 다음과 같은 조건이 검토 대상이다. 이 문서는 적용하지 않는다.

```verilog
wire jalr_ok = (funct3 == 3'b000);
// 허용 조건의 is_jalr 대신 (is_jalr & jalr_ok) 사용 검토
```

재현용 인코딩 예는 0x00001067이다. 이는 JALR opcode에 funct3=001을 넣은 값으로, 현재 디코더 식에서는 허용된다. 이는 정적 식 평가에 따른 예이며 실제 시뮬레이터에서 실행한 로그는 아니다.

## 2. trap은 보고와 부작용 차단만 수행함

**위치:** hart.v 150, 202~203, 209행; fetch.v 30~37행.

검출 조건은 illegal, 데이터 접근 비정렬, 실제로 이동하려는 분기·점프 목표의 비정렬이다. trap이면 레지스터 쓰기와 메모리 읽기·쓰기를 막고 fetch의 redirect도 막는다.

하지만 fetch는 이 경우 PC+4를 선택한다. trap PC를 저장하는 CSR, trap 원인 코드, handler 주소, 복귀 명령은 구현되어 있지 않다. tb 역시 TRAP만 출력하고 계속 실행한다. 과제의 관측 인터페이스로 충분한지와 일반적인 완전한 예외 처리 동작인지는 구분해야 한다.

예를 들어 taken branch의 목표가 PC+2이면 trap이 발생하고 실제 PC는 PC+4로 진행한다. 같은 branch가 not-taken이면 목표 정렬로 trap을 만들지 않는다. JALR은 bit0을 지운 뒤의 주소를 검사한다. 이는 [공식 RV32I 제어 이전 설명](https://github.com/riscv/riscv-isa-manual/blob/main/src/unpriv/rv32.adoc)의 목표 정렬 규칙과 비교해 읽을 수 있다.

## 3. EBREAK는 종료 관례

**위치:** control_unit.v 33, 55행; fetch.v 36행; tb.v 126~128행.

정확히 0x00100073일 때 halt=1이 된다. CPU의 PC 갱신을 막고 testbench는 실행을 종료한다. illegal 조건의 허용 목록에도 EBREAK를 포함하므로, 이 구현은 EBREAK에 trap을 켜는 대신 halt로 처리한다. 실제 소프트웨어 디버깅 환경의 breakpoint 예외 처리까지 구현했다고 보면 안 된다.

## 4. halt에서 next_pc 관측값과 실제 PC가 다를 수 있음

**위치:** fetch.v 27~37행; hart.v 225행.

o_next_pc의 조합식에는 halt 조건이 없다. EBREAK에서는 redirect=0이어서 o_next_pc=PC+4이지만, 순차 블록은 halt 때문에 실제 PC를 유지한다. 따라서 o_retire_next_pc라는 이름을 보고 항상 다음 에지의 PC 상태라고 해석하면 안 된다. 테스트/채점 인터페이스가 halt 시 어떤 값을 요구하는지에 따라 검토해야 하는 부분이다.

## 5. reset과 관측 신호의 경계

**위치:** hart.v 202~203, 209, 214행; tb.v 85, 93~94행.

- hart의 retire_valid는 reset 중에도 1이다. 외부 관측기가 reset 구간을 제외해야 한다.
- rf는 내부 reset 우선순위 덕분에 reset 시 일반 레지스터 쓰기를 하지 않는다.
- 외부 dmem_wen에는 reset 조건이 없다. 실행 중 store 명령이 보이는 상태에서 reset을 걸면 같은 상승 에지에 외부 메모리 쓰기가 일어날 가능성이 있다. 현재 tb의 시작 sequence와 별개로 재사용·재reset 시 검토할 문제이다.
- tb는 clk만 즉시 초기화하고 rst는 첫 하강 에지에서 처음 대입한다. 첫 상승 에지는 reset 전이어서 상태가 미정일 수 있다. 정상 trace는 reset 완료 후 시작하지만 초기 X와 메모리 부작용 가능성을 완전히 없애는 초기화 방식은 아니다.

이 항목은 현재 공개 테스트가 반드시 실패한다는 뜻은 아니다. 인터페이스를 다른 환경에 연결할 때 드러날 수 있는 경계 조건이다.

## 6. formal용 포트 구간은 완성 여부를 확인할 수 없음

**위치:** hart.v 28~30행.

RISCV_FORMAL이 정의되면 RVFI_OUTPUTS라는 외부 매크로를 펼친다. 이 project3에는 해당 매크로의 정의 파일이나 RVFI 신호 할당이 없다. 포트 행 끝의 쉼표도 매크로 확장 및 도구의 문법 허용 여부에 따라 확인해야 한다. 일반 빌드에서는 이 부분이 제외되지만, 이 코드만으로 formal verification 환경이 구성됐다고 판단할 근거는 없다.

## 7. imm의 과제 주석과 현재 구현은 구분해야 함

**위치:** imm.v 25~39행.

주석에는 “적어도 하나 버그”가 있다고 적혀 있지만 현재 I/S/B/U/J immediate의 비트 연결은 각 형식의 부호 확장 배치와 일치한다. 특히 아래 식은 복제 수가 이상해 보일 수 있어도 올바르다.

```text
현재 I형: 21개 sign + inst[30:20]의 11개 = 32
통상 I형: 20개 sign + inst[31:20]의 12개 = 32
```

현재 식의 21번째 sign이 원래 inst[31]의 자리를 대신하므로 같은 값이다. S/B형도 같은 방식으로 원래 sign bit를 복제에 포함한다. 근거 없이 복제 횟수만 바꾸면 오히려 폭을 잘못 만들 수 있다.

R형 immediate의 X는 의도적인 don't-care 표현이다. 잘못된 mux나 형식 플래그 때문에 R형 immediate를 ALU에 선택하면 X가 전파될 수 있지만, 정상 R형은 rs2를 선택한다. 형식이 multi-hot이면 오류 검출 없이 앞선 형식이 우선되므로 control_unit의 one-hot 전제가 중요하다.

## 8. 메모리 계약과 공개 테스트의 빈틈

유효 주소를 4바이트 경계로 내리는 동작은 byte 접근의 주소를 잃어버리는 버그가 아니다. 원래 하위 비트는 mask와 store/load formatter가 사용한다. 외부 메모리가 이 계약과 다르게 “byte 유효 주소 자체”를 기준으로 lane을 배치하면 이중 offset 오류가 생길 수 있다.

현재 공개 테스트에는 load/store가 없다. 따라서 다음 항목은 5개 프로그램만으로 검증되지 않는다.

| 추가 확인할 대상 | 좋은 관측 예 |
|---|---|
| SB/LB/LBU lane 0~3 | 0x80/0xff를 모든 offset에서 읽고 부호·0 확장 비교 |
| SH/LH/LHU | offset 0/2 정상, 1/3 trap 및 쓰기 없음 |
| SW/LW | offset 0 정상, 1/2/3 차단 |
| 데이터 보존 | SB/SH 후 비활성 lane의 기존 byte가 유지되는지 |
| BEQ/BNE | taken과 not-taken을 각각 강제 |
| BLT/BGE와 unsigned형 | 0x80000000, 0xffffffff, 0, 1 경계 비교 |
| JAL/JALR | rd=PC+4, 기준 주소 차이, JALR bit0 정리 |
| 목표 비정렬 | taken일 때 trap, not-taken이면 정상 순차 실행 |
| 시프트 | shamt 0/1/31, op2 상위 비트 무시, 음수 SRA |
| AUIPC | 현재 PC를 더하는지, PC+4와 혼동하지 않는지 |
| illegal | 잘못된 opcode, R형 funct7, load/store/branch funct3 |
| reset/retire | reset 중 enable과 valid가 외부 계약에 맞는지 |
| rf standalone bypass | BYPASS_EN 0/1 각각, 주소 충돌과 x0 우선순위 |

표는 추가 검증 제안이며, 이런 테스트가 저장소에 이미 존재하거나 실행됐다는 뜻은 아니다.

## 9. testbench의 PASS 판정 한계

현재 tb에는 기대 레지스터 값을 직접 assert하는 코드가 없다. 어셈블리 안의 BNE와 a0 결과 코드에 검증을 맡긴다. fail도 EBREAK로 끝나므로 “Program halted”는 성공 신호가 아니다. timeout 뒤에도 같은 종료 문구를 출력한다.

imem/dmem은 각각 1 KiB이고 범위 검사가 없으며 dmem 초기화도 없다. trap은 출력만 하고 종료하지 않는다. program.mem이 없으면 제대로 된 프로그램 실행을 기대할 수 없다. traces는 .gitkeep만 있으므로 기존 실행 로그와 대조할 수 없다.

## 10. 이번 분석에서 실제로 확인한 범위

| 항목 | 결과/한계 |
|---|---|
| RTL 소스 읽기 | 10개 파일 전부 확인 |
| 물리적 줄별 설명 | 총 805줄, 빈 줄·주석 포함 805행 대응 |
| 설명 표 검증 | 각 파일에서 1~마지막 줄 순서, 원문 셀 일치, 누락 여부를 스크립트로 검사 |
| 원본 식별 | 파일별 SHA-256을 각 해설과 line_coverage.json에 기록 |
| tb 분석 | 143줄 전부 읽고 기능 구간별 설명 작성 |
| tests 분석 | README, Makefile, 5개 .asm 전부 읽음 |
| case 표 | 55개 label의 입력/연산/기대값/분기 추출, gp 번호 및 비교 구조 검사 |
| ISA 대조 | JALR 인코딩과 분기·점프 정렬을 공식 자료로 확인 |
| HDL 컴파일/시뮬레이션 | **미실행**. PATH에 iverilog/verilator가 없고 Docker/WSL 접근도 허용되지 않아 사용하지 못함 |
| 어셈블/공개 테스트 PASS | **미확인**. 문서에 제시한 실행 절차는 실제 통과 기록이 아님 |
| 합성/주파수/FPGA 동작 | 미검증 |
| 회로도 PDF 내용 | 별도 판독하지 않음. 동작 분석의 근거는 실제 RTL |
| 원본 수정 | 없음. 문서 및 문서 생성 보조 스크립트만 추가 |

문서 생성 보조 파일은 CPU 빌드에 필요하지 않다. 재생성하려면 프로젝트 루트에서 Python으로 실행한다.

```sh
python docs/generate_notes.py
python docs/generate_cases.py
python docs/verify_docs.py
```

첫 스크립트는 build_line_notes.py, line_notes_memory.py, line_notes_hart.py의 해설 데이터를 사용한다. RTL 변경 후에는 줄별 설명 데이터도 함께 갱신해야 한다. 마지막 검사는 805개 원문 행 대응, 55개 case 행, 53개 내부 링크를 확인했으며 모두 통과했다. 이 검사는 문서의 누락과 원문 대응을 확인하며 설명 내용의 논리적 정확성이나 HDL 동작을 자동 증명하지는 않는다.
