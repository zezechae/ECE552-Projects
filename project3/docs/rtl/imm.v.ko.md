# imm.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/imm.v)

원본 물리적 줄 수: **50줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

명령어에 흩어져 있는 immediate 비트를 재조립한다. 6비트 형식 입력은 one-hot을 전제로 한다. 실제 선택 회로는 R→I→S→B→U→J 우선순위를 가진다.

| 형식 | 조립할 값 | 범위/특징 |
|---|---|---|
| R | X | immediate를 사용하지 않음 |
| I | sext(inst[31:20]) | -2048~2047 |
| S | sext({inst[31:25],inst[11:7]}) | -2048~2047 |
| B | sext({inst[31],inst[7],inst[30:25],inst[11:8],0}) | -4096~4094, 짝수 |
| U | {inst[31:12],12개 0} | 상위 20비트 값 |
| J | sext({inst[31],inst[19:12],inst[20],inst[30:21],0}) | -1048576~1048574, 짝수 |

sext는 부호 확장을 뜻한다. I형 구현의 “21번 복제 + 11비트”는 일반적인 “20번 복제 + 12비트”와 동일하다. 복제된 bit31 중 마지막 하나가 원래 imm[11] 자리이기 때문이다. 따라서 주석의 “적어도 한 개 버그”를 현재 코드에 그대로 적용하면 안 된다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 3 | <code>// The immediate generator is responsible for decoding the 32-bit sign-extended</code> | immediate 생성기가 32비트 부호 확장 값을 만든다는 설명의 시작. |
| 4 | <code>// immediate from the incoming instruction word. It is a purely combinational</code> | 현재 명령어에서 immediate를 추출하며 순수 조합 블록이라는 설명. |
| 5 | <code>// block that is expected to be embedded in the instruction decoder.</code> | 명령어 디코더에 포함해 사용할 구성 요소라는 설명. |
| 6 | <code>module imm (</code> | immediate 생성 모듈 선언. |
| 7 | <code>    // Input instruction word. This is used to extract the relevant immediate</code> | 원본 명령어 입력에서 필요한 immediate 비트를 뽑는다는 설명. |
| 8 | <code>    // bits and assemble them into the final immediate.</code> | 뽑은 비트들을 최종 immediate로 조립한다는 설명. |
| 9 | <code>    input  wire [31:0] i_inst,</code> | 32비트 원본 명령어 입력. |
| 10 | <code>    // Instruction format, determined by the instruction decoder based on the</code> | opcode를 보고 제어기가 명령 형식을 정해 전달한다는 설명. |
| 11 | <code>    // opcode. This is one-hot encoded according to the following format:</code> | 형식 선택이 one-hot 인코딩이라는 설명. |
| 12 | <code>    // [0] R-type</code> | 형식 bit0은 R형. |
| 13 | <code>    // [1] I-type</code> | 형식 bit1은 I형. |
| 14 | <code>    // [2] S-type</code> | 형식 bit2는 S형. |
| 15 | <code>    // [3] B-type</code> | 형식 bit3은 B형. |
| 16 | <code>    // [4] U-type</code> | 형식 bit4는 U형. |
| 17 | <code>    // [5] J-type</code> | 형식 bit5는 J형. |
| 18 | <code>    input  wire [ 5:0] i_format,</code> | 제어기가 알려주는 6비트 형식 플래그. 이진 번호가 아니라 각 형식별 비트이다. |
| 19 | <code>    // Output 32-bit sign-extended immediate.</code> | 출력이 32비트 부호 확장 immediate라는 설명. U형은 상위 20비트와 12개 0으로 구성된다. |
| 20 | <code>    // NOTE: Because the R-type format does not have an immediate, the output</code> | R형에는 immediate 자체가 없다는 안내의 시작. |
| 21 | <code>    // immediate can be treated as a don't-care under this case. It is included</code> | R형일 때 immediate는 사용하지 않는 값으로 취급할 수 있다는 설명. |
| 22 | <code>    // for completeness.</code> | 형식 목록의 완전성을 위해 R형 선택도 포함한다는 설명. |
| 23 | <code>    output wire [31:0] o_immediate</code> | 재조립된 32비트 immediate 출력. |
| 24 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 25 | <code>    // The immediate generation logic below has at least one bug. Fix the</code> | 과제 초기 구현에 버그가 있었다는 안내 주석이다. 현재 구현에 버그가 남아 있다는 증거는 아니다. |
| 26 | <code>    // provided implementation below to generate the correct immediate values</code> | 위 과제 안내의 연속 주석. 합성되는 회로에 영향이 없다. |
| 27 | <code>    // for all instruction formats. You are encouraged to make a testbench and</code> | 별도 testbench 작성을 권장하는 기존 주석이다. |
| 28 | <code>    // look through waveforms as you do this.</code> | 파형 확인을 권하는 기존 주석의 마지막 줄이다. |
| 29 | <code>    wire [31:0] imm_r = {{32{1'bx}}};</code> | R형에는 immediate가 없으므로 32개 X를 출력 후보로 만든다. 바깥 중괄호는 불필요하지만 적법한 연결이다. X는 시뮬레이션 미정값이지 실제 하드웨어의 제3 논리값은 아니다. |
| 30 | <code>    wire [31:0] imm_i = {{21{i_inst[31]}}, i_inst[30:20]};</code> | 부호 bit31을 21개, 나머지 inst[30:20]을 11개 연결한다. 합계 32비트이며 I형 12비트 immediate의 정확한 부호 확장이다. |
| 31 | <code>    wire [31:0] imm_s = {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:7]};</code> | 부호 bit31 21개 + inst[30:25] 6개 + inst[11:7] 5개=32비트. S형의 분리된 12비트 immediate를 복원한다. |
| 32 | <code>    wire [31:0] imm_b = {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0};</code> | 부호 bit31 20개 + bit7 1개 + bits30:25 6개 + bits11:8 4개 + 0 1개=32. 원래 sign bit가 imm[12]까지 채워진다. 마지막 0은 byte 오프셋의 bit0이다. |
| 33 | <code>    wire [31:0] imm_u = {i_inst[31:12],12'b0};</code> | U형의 inst[31:12] 20비트 뒤에 12개 0을 붙인다. LUI/AUIPC에서 쓸 값이며 추가 시프트는 필요 없다. |
| 34 | <code>    wire [31:0] imm_j = {{11{i_inst[31]}}, // sign extension</code> | J형의 상위 부호 확장 11비트를 먼저 배치한다. 연결식은 다음 줄들까지 계속된다. |
| 35 | <code>                        i_inst[31],        // imm[20]</code> | 명령어 bit31을 J immediate의 bit20에 둔다. |
| 36 | <code>                        i_inst[19:12],     // imm[19:12]</code> | 명령어 bits19:12를 immediate bits19:12에 둔다. |
| 37 | <code>                        i_inst[20],        // imm[11]</code> | 명령어 bit20을 immediate bit11에 둔다. |
| 38 | <code>                        i_inst[30:21],     // imm[10:1]</code> | 명령어 bits30:21을 immediate bits10:1에 둔다. |
| 39 | <code>                        1'b0};             // imm[0]</code> | immediate bit0을 0으로 두고 연결식을 닫는다. 11+1+8+1+10+1=32비트이다. |
| 40 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 41 | <code>    assign o_immediate = i_format[0] ? imm_r :</code> | 형식 bit0이 1이면 R 후보를 선택한다. 여러 비트가 1이면 이 조건이 가장 우선한다. |
| 42 | <code>                         i_format[1] ? imm_i :</code> | R이 아니고 bit1이 1이면 I immediate. |
| 43 | <code>                         i_format[2] ? imm_s :</code> | 앞 조건이 아니고 bit2가 1이면 S immediate. |
| 44 | <code>                         i_format[3] ? imm_b :</code> | 앞 조건이 아니고 bit3이 1이면 B immediate. |
| 45 | <code>                         i_format[4] ? imm_u :</code> | 앞 조건이 아니고 bit4가 1이면 U immediate. |
| 46 | <code>                         i_format[5] ? imm_j :</code> | 앞 조건이 아니고 bit5가 1이면 J immediate. |
| 47 | <code>                         32'b0;</code> | 어떤 형식도 선택되지 않으면 0을 출력하고 assign 문을 끝낸다. |
| 48 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |
| 49 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 50 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `7c6dbed2e4aeab427eaa8292d7abf25fa2650e7226a14a53e66ac8508292b387`
