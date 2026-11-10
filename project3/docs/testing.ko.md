# tb와 tests의 역할 및 검증 흐름

[분석 안내](README.ko.md) · [55개 테스트 케이스 목록](tests_cases.ko.md) · [검토 및 한계](review.ko.md)

## 1. 두 폴더는 무엇이 다른가

`tb`는 CPU를 둘러싼 **시뮬레이션 환경**이다. 클록과 reset을 만들고, 메모리를 제공하고, 실행 기록을 출력한다. `tests`는 그 환경에서 CPU가 실행할 **어셈블리 프로그램과 변환 도구**이다.

```text
tests/asm/01add.asm  같은 테스트 소스
        ↓ tests/asm/Makefile: GNU RISC-V assembler
      01add.o       기계어가 들어 있는 오브젝트
        ↓ objcopy -O binary -j .text
      01add.hex     이름과 달리 텍스트 hex가 아닌 raw binary
        ↓ xxd + sed
tb/program.mem     byte 단위 16진수 텍스트
        ↓ tb/tb.v의 $readmemh
tb의 imem 배열
        ↓ 주소에 따라 4바이트를 조립
RTL hart가 명령어를 실행
        ↓ retire/data memory 인터페이스
터미널 trace 출력
```

따라서 `.asm` 파일을 Verilog 컴파일러에 직접 넣는 것은 아니다. 어셈블러는 RISC-V 프로그램을 기계어로 변환하고, Verilog 시뮬레이터는 그 기계어를 실행하는 CPU 회로를 시뮬레이션한다.

## 2. tb/tb.v: 실행 환경

모듈 이름은 파일명 `tb`와 달리 **hart_tb**이다. 외부 포트가 없는 시뮬레이션 최상위 모듈이며 내부에 `dut`라는 이름의 hart 인스턴스가 있다. DUT는 Device Under Test, 즉 검증 대상 회로라는 관례적 이름이다.

### 1~46행: 신호와 DUT 연결

clk/rst는 tb가 구동하므로 reg이다. imem_rdata/dmem_rdata도 tb의 always 블록에서 만들어 DUT에 공급하므로 reg이다. 주소, enable, mask, write data, retire는 DUT가 만들어 tb로 전달하므로 wire이다.

hart의 RESET_ADDR는 0으로 설정한다. instruction memory 주소와 데이터, data memory의 주소/읽기/쓰기/mask, retire 기록을 모두 연결한다. reset은 hart와 동일한 active-high 동기식이다.

### 48~55행: instruction memory

```verilog
reg [7:0] imem [0:1023];
imem_rdata = {imem[imem_raddr + 3], imem[imem_raddr + 2],
              imem[imem_raddr + 1], imem[imem_raddr + 0]};
```

imem은 **1024개의 8비트 원소**, 즉 1 KiB byte-addressed 메모리이다. PC부터 4바이트를 읽어 상위 주소의 byte를 높은 비트에 놓는다. 예를 들어 주소 0~3에 `93 00 10 00`이 있으면 32비트 명령어는 `0x00100093`, 즉 `addi x1,x0,1`이다. 이런 byte 배치가 little-endian이다.

instruction read는 조합식이며 별도 읽기 enable이 없다. 범위 검사도 없으므로 유효한 4바이트 읽기 시작 주소는 0~1020이고, 정상 4바이트 정렬 PC는 0,4,...,1020이다.

### 57~68행: data memory 읽기

먼저 dmem_rdata 전체를 `32'hx`로 만든 뒤, ren과 mask가 켜진 lane만 dmem에서 채운다. 비활성 lane을 0으로 숨기지 않아 잘못된 lane을 선택하는 버그가 드러나기 쉽다.

| 조건 | 읽는 byte | 출력 위치 |
|---|---|---|
| ren & mask[0] | dmem[addr+0] | bits7:0 |
| ren & mask[1] | dmem[addr+1] | bits15:8 |
| ren & mask[2] | dmem[addr+2] | bits23:16 |
| ren & mask[3] | dmem[addr+3] | bits31:24 |

여기서 addr는 hart가 내보내는 **정렬된 word 주소**이다. 예를 들어 `LBU`의 유효 주소가 0x103이면 addr=0x100, mask=1000이고 읽기 버스는 `0x80xxxxxx` 같은 값일 수 있다. load_format이 상위 byte만 선택하면 결과는 정상적으로 0x00000080이다.

dmem은 별도로 초기화하지 않는다. 먼저 store하지 않은 위치를 읽으면 X가 나올 수 있다. 프로그램은 imem에만 들어가므로 코드와 데이터를 같은 주소 공간에 공유하는 일반 메모리 모델로 이해하면 안 된다.

### 70~81행: data memory 쓰기

상승 에지에서 wen & mask[n]인 byte만 nonblocking 대입으로 갱신한다. SW는 네 byte, SH는 두 byte, SB는 한 byte를 갱신한다. 나머지 byte는 이전 값을 유지한다.

예를 들어 addr=0x100, mask=0100, wdata=0x00440000이면 dmem[0x102]만 0x44가 된다. 0x100이나 0x101에 0을 쓰는 것이 아니다. 따라서 mask와 store_align이 서로 맞아야 한다.

### 83~94행: 시작과 reset

initial 블록은 시뮬레이션 시작 시 한 번 실행한다. clk=0으로 설정한 뒤 `$readmemh("program.mem", imem)`으로 프로그램을 읽는다. 파일 경로는 tb.v가 있는 위치가 아니라 **시뮬레이터 실행 작업 디렉터리 기준**이다.

reset은 두 하강 에지 사이에 1로 유지한다. 아래 시간은 소스의 `#5`가 뜻하는 시간 단위를 그대로 사용한 것이다.

| 시각 | 사건 |
|---:|---|
| 0 | clk=0, 프로그램 로드, rst는 아직 명시적으로 초기화되지 않음 |
| 5 | 첫 상승 에지. reset 전이므로 출력/상태가 X일 수 있음 |
| 10 | 하강 에지에서 rst=1 |
| 15 | 상승 에지에서 rf=0, PC=RESET_ADDR로 reset |
| 20 | 하강 에지에서 rst=0, 실행 관측 준비 |
| 25 | 첫 정상 명령의 상승 에지와 trace 관측 |

rst 초기값이 지정되지 않았다는 점과 reset 동안 외부 메모리 쓰기 enable이 별도로 차단되지 않는다는 점은 [검토 문서](review.ko.md)에 따로 기록했다.

### 96~103행: 관측 루프

헤더를 출력한 뒤 run=1, cycles=0으로 시작한다. 각 상승 에지에 cycles를 증가시키고 valid가 1이면 명령을 출력한다. hart는 valid=1로 고정하므로 정상 실행 구간에서는 매 상승 에지마다 관측된다.

PC와 rf가 nonblocking으로 갱신되므로 tb는 보통 그 에지의 NBA 상태 갱신 이전 값을 읽어 **이번에 완료되는 명령의 PC/피연산자와 예정된 결과**를 출력한다. 별도의 `$strobe`, clocking block, 등록된 retire 인터페이스는 없다. 따라서 향후 blocking 상태 갱신이나 관측 방식을 바꾸면 시뮬레이션 이벤트 순서를 다시 검토해야 한다.

### 104~111행: 명령에 맞는 피연산자 출력

LUI/AUIPC, SYSTEM, JAL처럼 rs를 사용하지 않는 명령은 둘 다 `r[--]=--------`로 출력한다. I형 ALU, load, JALR은 rs1만 출력한다. 그 외에는 rs1과 rs2를 출력한다.

`inst[3:0]==0111`은 현재 대상으로 삼는 U형 opcode를 간단히 판별하기 위한 **출력 포맷 조건**이다. 이것이 CPU의 명령 합법성 판정은 아니다. 실제 illegal 판정은 control_unit이 한다.

### 113~124행: 효과 출력

- rd_waddr가 0이 아니면 `w[rd]=value`를 출력한다. store/branch 등 쓰기 없는 명령은 hart가 rd 주소 0을 내보내므로 생략된다. x0를 쓰는 명령도 생략된다.
- dmem_ren이면 `l[addr,mask]=read_bus`를 출력한다.
- dmem_wen이면 `s[addr,mask]=write_bus`를 출력한다.
- trap이면 `TRAP`을 붙인다.
- `$write`는 줄바꿈 없이 이어 쓰고 마지막 `$display()`가 줄을 끝낸다.

여기서 load/store 출력값은 **메모리 버스 값**이다. load가 부호 확장된 최종 값은 w[...]에서 볼 수 있다. 주소도 원래 byte 유효 주소가 아니라 정렬된 버스 주소이다.

예를 들어 x1=2, x2=3인 `add x30,x1,x2`는 대략 다음과 같은 형식으로 나온다. 이는 형식 설명용 예이며 실제 실행에서 캡처한 로그가 아니다.

```text
[00000010] 00208f33 r[ 1]=00000002 r[ 2]=00000003 w[30]=00000005
```

`%08h`는 16진수를 8자리로, `%04b`는 2진수를 4자리로 보여 준다. 표시 순서는 PC, 명령어, 원본 레지스터 값, 기록 및 메모리 효과이다.

### 126~138행: 종료 조건

halt가 1이면 run=0으로 루프를 끝낸다. trap 자체로 종료하는 조건은 없다. 무한 루프를 제한하기 위해 `cycles > 40000`이면 중지한다. 엄밀히는 40001번째 관측 사이클에서 조건이 참이다.

마지막의 `Program halted after ...` 문장은 정상 EBREAK뿐 아니라 timeout 이후에도 출력된다. 따라서 이 문장 하나를 PASS 증거로 쓰면 안 된다. 실패 테스트도 EBREAK를 실행하므로 **halt와 pass는 별개**이다.

### 141~143행: 클록 생성

```verilog
always
    #5 clk = ~clk;
```

5 시간 단위마다 clk를 반전하므로 주기는 10 시간 단위이다. 이 소스에는 `timescale`이 없어서 이를 무조건 10ns 또는 100MHz라고 부를 수 없다. 시뮬레이터 설정이나 컴파일 환경의 시간 단위를 확인해야 한다. 파형 파일을 만드는 `$dumpfile/$dumpvars`도 현재 tb에는 없다.

## 3. tests/README

총 네 줄의 안내 파일이다. Gradescope에서 사용하는 어셈블리 테스트 중 다섯 개만 제공됐고 나머지는 이후 단계에서 공개될 예정이라는 설명이 있다. 학생이 추가 테스트를 만들 것을 권장한다. Makefile 사용법은 별도 문서를 참조하라고 하지만, 이 project3 폴더에는 그 실행 문서가 포함돼 있지 않다.

따라서 제공된 5개 테스트를 통과한다는 사실만으로 전체 CPU 검증이 끝났다고 볼 수 없다. 여기서는 실제 실행 결과를 얻지 않았으므로 통과 여부도 주장하지 않는다.

## 4. 어셈블리 테스트의 공통 구조

```asm
.text
main:
test_2:
    li x1, 0
    li x2, 0
    add x30, x1, x2
    li x29, 0
    li gp, 2
    bne x30, x29, fail
...
pass:
    li a0, 1
    ebreak
fail:
    li a0, 0xdead
    ebreak
```

| 요소 | 역할 |
|---|---|
| `.text` | 실행 명령이 들어갈 코드 section 선택 |
| `main:`, `test_N:` | 주소에 붙인 label; label 자체가 실행 명령은 아님 |
| `li` | load immediate 의사 명령; 상수에 따라 ADDI 또는 LUI+ADDI 등으로 확장 가능 |
| x1/x2 | 주로 입력 데이터 레지스터 |
| x30 | 주로 검사할 연산 결과 |
| x29 | 기대값 레지스터 |
| `gp` | x3의 ABI 별칭; 현재 test 번호 기록 용도 |
| `bne actual, expected, fail` | 다르면 공통 실패 label로 이동, 같으면 다음 case로 진행 |
| `a0` | x10의 ABI 별칭; 1은 성공, 0xdead는 실패라는 이 테스트의 관례 |
| `ebreak` | 이 hart에서 halt, tb에서 실행 종료 |

각 test의 gp 설정이 비교 직전에 있으므로 실패 경로에서 x3를 보면 어떤 case가 실패했는지 알 수 있다. 다만 현재 tb는 종료 시 x3/x10을 별도 요약하지 않는다. gp에 마지막으로 쓴 값과 a0에 쓴 값을 trace에서 확인해야 한다.

모든 case를 통과하면 마지막 비교 이후 자연스럽게 pass label로 내려간다. pass의 EBREAK가 시뮬레이션을 끝내므로 그 아래 fail 코드는 실행되지 않는다. 어느 case든 비교가 다르면 fail로 직접 분기해 a0=0xdead를 기록하고 종료한다.

## 5. 파일별로 무엇을 검증하는가

| 파일 | case 수 | 주 검사 대상 | 세부 사항 |
|---|---:|---|---|
| 01add.asm | 18 | ADD | 0, 양수, 음수 비트열, 32비트 overflow, rd=rs1/rs2/둘 다 |
| 02addi.asm | 18 | ADDI | 12비트 부호 확장, 경계 -2048/+2047, overflow, x0 읽기·쓰기 |
| 03and.asm | 7 | AND | 서로 다른 비트 패턴, rd와 원본 겹침, 자기 자신 AND |
| 04andi.asm | 7 | ANDI | 음수/양수 immediate 마스크, rd=rs1, x0 읽기·쓰기 |
| 05lui.asm | 5 | LUI | 상위 20비트, 양수/음수 경계, SRAI와 조합, x0 쓰기 무시 |
| 합계 | **55** |  | label 하나를 case 하나로 집계 |

각 case의 실제 입력, 연산, 기대값, 비교 문장은 [전체 case 목록](tests_cases.ko.md)에 원본에서 추출해 정리했다. 아래는 의미상 중요한 부분이다.

### 01add.asm

test_2~16은 산술값과 wraparound를 검사한다. 예를 들어 test_14는 0xffffffff+1=0, test_16은 0x00000001+0x7fffffff=0x80000000이다. 부호 있는 수로 overflow하더라도 이 ALU는 별도 overflow trap을 만들지 않고 하위 32비트 결과를 사용한다.

test_17은 `add x1,x1,x2`, test_18은 `add x2,x1,x2`, test_19는 `add x1,x1,x1`이다. 원본과 목적지가 같아도 현재 명령은 갱신 전 값을 읽고 다음 에지에 결과를 써야 한다. BYPASS_EN 설정이 특히 관련된다.

### 02addi.asm

음수 immediate 0xfffff800은 32비트 표기로 -2048을 뜻하며 실제 명령의 12비트 필드는 0x800이다. 0xffffffff는 -1이고 0x7ff는 +2047이다. ADDI의 immediate는 0 확장하지 않고 부호 확장해야 한다.

test_17은 같은 x1을 읽고 쓰는 경우, test_24는 x0에서 읽기, test_25는 x0에 쓰기를 무시하는 경우이다. case 번호는 연속되지 않으므로 25개 테스트가 아니라 18개이다. test_16은 label과 첫 `li`가 같은 줄에 있어 줄 단위로만 단순 분리하면 놓칠 수 있다.

### 03and.asm

test_2~5는 AND가 비트별로 동작하는지 서로 다른 마스크 패턴으로 검사한다. 논리 연산 `&&`로 잘못 구현하면 이 값들은 대부분 0/1만 나오므로 실패한다. test_6~8은 각각 rd=rs1, rd=rs2, 모든 원본과 목적지가 동일한 경우이다.

### 04andi.asm

test_2의 immediate 0xffffff0f는 -241이며 12비트 값은 0xf0f이다. 이를 32비트로 부호 확장하면 상위가 1이 되어 `0xff00ff00 & 0xffffff0f = 0xff00ff00`이 된다. immediate를 0x00000f0f로 잘못 확장하면 상위 값이 없어져 실패한다.

test_3~5는 양수 마스크, test_6은 rd=rs1, test_13은 x0 입력, test_14는 x0 쓰기 무시를 검사한다.

### 05lui.asm

test_2는 LUI 0, test_6은 x0 쓰기 무시이다. 나머지는 LUI 뒤에 SRAI를 붙여 확인한다.

- test_3: 0xfffff000을 산술 오른쪽 1비트 이동 → 0xfffff800.
- test_4: 0x7ffff000을 산술 오른쪽 20비트 이동 → 0x000007ff.
- test_5: 0x80000000을 산술 오른쪽 20비트 이동 → 0xfffff800.

따라서 이 파일이 실패했다고 LUI 하나만 문제라고 단정할 수 없다. SRAI 제어, ALU의 부호 채우기, 레지스터 쓰기도 원인이 될 수 있다.

### 테스트가 의존하는 명령과 직접 검증하는 명령

각 파일은 이름의 명령만 실행하지 않는다. 입력 및 기대값을 만드는 li는 ADDI/LUI 등에 의존하고, 모든 검사는 BNE에 의존하며 EBREAK로 종료한다. 즉 공개 테스트는 ADD/ADDI/AND/ANDI/LUI 외에도 일부 BNE/SRAI/EBREAK 경로를 간접 실행한다.

그러나 간접 실행은 포괄적인 검증이 아니다. 특히 정상 성공 경로에서 BNE는 모두 **분기하지 않는** 경로이다. BNE가 항상 not-taken으로 오동작하면 잘못된 산술 결과를 놓칠 수 있다. 의도적으로 비교가 다른 경우에도 fail로 가는지, 분기 자체의 taken/not-taken 테스트를 추가해야 검사 장치도 신뢰할 수 있다.

## 6. tests/asm/Makefile

이 Makefile은 시뮬레이션 실행이 아니라 **program.mem 생성**이 주 역할이다.

| 원본 줄 | 역할 |
|---:|---|
| 1 | `.ONESHELL:`: 한 target의 recipe를 하나의 shell에서 실행하도록 요청 |
| 2 | `PROGRAM ?= add0`: 사용자가 지정하지 않았을 때만 기본 이름을 add0으로 설정 |
| 3 | assemble target 시작 |
| 4 | Docker 컨테이너 실행, 현재 디렉터리를 /src에 연결, 종료 시 컨테이너 제거 |
| 5 | 컨테이너 안에서 /src로 이동하고 성공 시 다음 명령 실행 |
| 6 | `riscv64-unknown-elf-as`를 RV32I/ILP32 옵션으로 실행해 .asm→.o 변환 |
| 7 | objcopy로 .text만 raw binary로 추출하고 section을 0x400까지 패딩하도록 지정 |
| 8 | Docker에 전달한 bash 명령 문자열 닫기 |
| 9 | xxd로 byte 텍스트를 만들고 sed로 byte 사이 공백을 넣어 tb/program.mem에 저장 |
| 10 | 빈 줄 |
| 11 | clean target 시작 |
| 12 | .o/.hex 및 생성된 program.mem/a.out 삭제 |

`PROGRAM`에는 확장자를 빼고 이름을 넣는다. 제공된 파일에 `add0.asm`은 없으므로 기본값으로 `make assemble`만 실행하면 입력 파일을 찾지 못한다. `make assemble PROGRAM=01add`처럼 지정해야 한다.

툴 이름이 `riscv64-...`라고 64비트 프로그램을 만든다는 뜻은 아니다. `-march=rv32i -mabi=ilp32`가 이 프로젝트의 32비트 ISA/ABI를 선택한다. `$(PWD)`는 Make 변수 확장이고, `&&`는 앞 명령이 성공할 때 다음 명령을 실행하는 shell 연산자이다. `\`는 긴 명령을 다음 줄로 이어 준다.

objcopy의 `.hex` 출력은 실제로 raw binary이다. xxd를 통과한 **program.mem만** `$readmemh`에 적합한 16진수 텍스트다. 4바이트마다 줄바꿈해도 imem 원소가 8비트이므로 공백으로 구분된 각 두 자리 hex가 한 byte씩 들어간다.

`clean`은 원본 .asm/RTL을 지우지는 않지만 이전 생성 결과를 지우는 명령이다. 이 분석 과정에서는 실행하지 않았다. Docker 이미지 태그가 latest로 지정되어 있으므로 실행 재현성이 중요하면 사용한 이미지 버전을 기록하는 편이 좋다.

## 7. 실행 방법: 준비된 환경에서 쓰는 예

아래 명령은 **이 분석에서 실행해 통과한 기록이 아니라**, Docker와 GNU Make, POSIX shell, xxd, sed, Icarus Verilog가 준비된 환경의 절차이다. 현재 Windows PowerShell만으로 모든 도구가 제공되지는 않는다. Makefile은 POSIX 도구 및 `$(PWD)`를 전제로 하므로 WSL/Linux 등의 환경에서 경로 마운트를 확인해야 한다.

프로젝트 루트에서:

```sh
cd tests/asm
make assemble PROGRAM=01add
cd ../../tb
iverilog -g2012 -s hart_tb -o a.out ../rtl/*.v tb.v
vvp a.out
```

컴파일과 실행은 별도 단계이며 [Icarus 공식 시뮬레이션 문서](https://steveicarus.github.io/iverilog/usage/simulation.html)에서도 이 흐름을 설명한다. `-s hart_tb`는 최상위 모듈 선택이다. 이 RTL은 주로 Verilog 문법을 사용하며 여기의 `-g2012`는 SystemVerilog 모드까지 허용하는 실행 예이다. `RISCV_FORMAL`은 정의하지 않는 일반 시뮬레이션을 전제로 한다.

파일별 테스트를 바꾸려면 PROGRAM만 `02addi`, `03and`, `04andi`, `05lui`로 바꾸어 program.mem을 다시 생성하고 vvp를 실행하면 된다. RTL과 tb가 같다면 프로그램만 바꿀 때 HDL을 다시 컴파일할 필요는 없다.

현재 project3에는 program.mem, a.out, 실제 trace 로그, 자동 PASS/FAIL 판정 스크립트가 포함되어 있지 않다. 실행 후 마지막 a0(x10) 기록이 1인지, 0xdead인지 확인하고 timeout 또는 TRAP 여부도 함께 봐야 한다.
