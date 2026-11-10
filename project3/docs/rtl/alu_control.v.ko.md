# alu_control.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/alu_control.v)

원본 물리적 줄 수: **33줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

주 제어기가 만든 2비트 ALUOp와 명령어의 funct 필드를 ALU용 세부 신호로 바꾼다. 전부 조합 회로이다.

| ALUOp | 용도 | opsel |
|---|---|---|
| 00 | 주소 계산, LUI/AUIPC, 점프의 복귀 주소 | 000: 덧셈 |
| 01 | 분기 비교 | 000; 실제 분기는 eq/slt 별도 출력 사용 |
| 10 | R형 연산 | funct3 |
| 11 | I형 산술·논리 연산 | funct3 |

`o_sub`나 `o_arith`가 이름과 관계없는 명령에서도 1일 수 있다. 예를 들어 SRA의 o_sub=1은 오른쪽 시프트 경로에서 사용되지 않으므로 문제가 없다. SLTU의 unsigned는 중요하지만 AND에서 unsigned는 결과에 영향을 주지 않는다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>module alu_control (</code> | `alu_control` 모듈의 포트 목록을 시작한다. |
| 3 | <code>    input  wire [1:0] i_ALUOp,      // 00 add, 01 branch, 10 R-type, 11 I-type ALU</code> | 2비트 상위 연산 분류 입력. `2'b00`처럼 폭과 진법을 지정한 값으로 해석한다. |
| 4 | <code>    input  wire [2:0] i_funct3,     // inst[14:12]</code> | 명령어 inst[14:12]의 3비트 funct3 입력. ADD/SLT/AND 등을 구분한다. |
| 5 | <code>    input  wire       i_funct7_5,   // inst[30]</code> | funct7 전체가 아니라 그중 bit 5, 즉 inst[30]만 입력한다. SUB와 SRA 계열 구분에 사용한다. |
| 6 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 7 | <code>    output wire [2:0] o_opsel,</code> | ALU의 결과 선택기 3비트 출력. 일반 산술 명령에서는 funct3와 같다. |
| 8 | <code>    output wire       o_sub,</code> | 덧셈기 경로에서 1이면 뺄셈, 0이면 덧셈을 선택한다. |
| 9 | <code>    output wire       o_unsigned,</code> | 작다 비교에서 unsigned 해석을 선택하는 1비트 출력. |
| 10 | <code>    output wire       o_arith,</code> | 오른쪽 시프트에서 1이면 부호를 채우는 산술 시프트를 선택한다. |
| 11 | <code>    output wire       o_bcomp,      // branch: 0 = use o_eq, 1 = use o_slt</code> | 분기 비교 종류. 0이면 동등 비교 eq, 1이면 작다 비교 slt를 고른다. |
| 12 | <code>    output wire       o_bnot        // branch: invert the selected flag</code> | 선택한 비교 결과를 뒤집는 출력. BNE/BGE/BGEU에서 1이다. |
| 13 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 14 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 15 | <code>//All operations are divided into 4 categories: R, I , B, Other(Add)</code> | R형, I형, branch, 그 외 덧셈이라는 네 분류를 설명하는 주석. |
| 16 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 17 | <code>wire is_branch = (i_ALUOp == 2'b01);</code> | ALUOp가 01인지 비교한 1비트 net. wire 선언의 =는 연속 연결이지 클록 초기화가 아니다. |
| 18 | <code>wire is_r      = (i_ALUOp == 2'b10);</code> | ALUOp가 10이면 R형 연산이다. |
| 19 | <code>wire is_i      = (i_ALUOp == 2'b11);</code> | ALUOp가 11이면 I형 산술·논리 연산이다. |
| 20 | <code>wire use_f3    = is_r &#124; is_i;</code> | R형 또는 I형 ALU 명령일 때만 funct3를 결과 선택에 사용한다. `&#124;`는 비트 OR이다. |
| 21 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 22 | <code>assign o_sub = is_r &amp; i_funct7_5; //For R type only</code> | R형이면서 inst[30]=1이면 sub를 켠다. 유효한 SUB에서 사용되고 SRA에서는 덧셈 경로가 선택되지 않아 무관하다. |
| 23 | <code>assign o_unsigned = is_branch ? i_funct3[1] : (use_f3 &amp; i_funct3[0]);</code> | 분기에서는 funct3[1]이 BLTU/BGEU를 구분한다. 나머지 ALU 명령에서는 funct3[0]이 SLT/SLTU를 구분한다. `?:`는 mux이다. |
| 24 | <code>assign o_arith = use_f3 &amp; i_funct7_5; //For both R &amp; I type</code> | R/I ALU 명령에서 inst[30]을 산술 시프트 선택으로 전달한다. 실제로는 opsel=101일 때만 사용한다. |
| 25 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 26 | <code>assign o_opsel = use_f3 ? i_funct3 : 3'b000;</code> | R/I 연산은 funct3로 결과를 선택하고, 주소 계산·분기는 000을 선택한다. 분기는 result 대신 독립 비교 플래그를 쓴다. |
| 27 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 28 | <code>assign o_bcomp = i_funct3[2]; //branch checking is not required as they are seperate outputs</code> | BEQ/BNE의 funct3[2]=0, BLT/BGE/BLTU/BGEU의 [2]=1. 비교 플래그 선택 신호로 직접 전달한다. |
| 29 | <code>assign o_bnot  = i_funct3[0];</code> | BEQ/BLT/BLTU는 [0]=0, BNE/BGE/BGEU는 [0]=1. hart에서 XOR하여 조건을 반전한다. |
| 30 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 31 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |
| 32 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 33 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `77368f54ae93b4a5bf8a00ddbbcdaa313b395f0ffa5ed0ac45c1f812fb181853`
