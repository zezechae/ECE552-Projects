# control_unit.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/control_unit.v)

원본 물리적 줄 수: **77줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

명령어의 opcode와 funct 필드를 보고 CPU 전체 제어 신호를 만든다. 레지스터나 클록이 없는 조합 디코더이다. illegal 판단과 실행 제어를 분리해 raw 제어를 내보내며, hart가 trap일 때 쓰기를 막는다.

| 명령 분류 | Src1 | Src2 | ALUOp | RegWrite | MemRead/Write | imm |
|---|---|---|---|---|---|---|
| R | rs1 | rs2 | 10 | 1 | 0/0 | R |
| I ALU | rs1 | imm | 11 | 1 | 0/0 | I |
| LOAD | rs1 | imm | 00 | 1 | 1/0 | I |
| STORE | rs1 | imm | 00 | 0 | 0/1 | S |
| BRANCH | rs1 | rs2 | 01 | 0 | 0/0 | B |
| JAL/JALR | PC+4 | 0 | 00 | 1 | 0/0 | J/I |
| LUI | 0 | imm | 00 | 1 | 0/0 | U |
| AUIPC | PC | imm | 00 | 1 | 0/0 | U |

점프 목표 계산은 fetch가 따로 하므로 JAL/JALR에서 ALU는 rd에 쓸 PC+4를 계산한다. JALR의 funct3 검사가 빠져 있다는 점은 review 문서에서 별도로 설명한다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>module control_unit (</code> | 주 제어기 모듈 선언. |
| 3 | <code>    input  wire [31:0] i_clu_inst,</code> | 현재 실행할 32비트 명령어 입력. |
| 4 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 5 | <code>    output wire        o_clu_Branch,</code> | 조건 분기 opcode임을 나타내는 출력. 실제 taken 여부는 비교 후 결정한다. |
| 6 | <code>    output wire        o_clu_jump,</code> | JAL 또는 JALR이면 1인 점프 출력. |
| 7 | <code>    output wire        o_clu_targetSrc,</code> | 목표 주소 기준을 고르는 출력. 1=rs1, 0=PC. |
| 8 | <code>    output wire        o_clu_halt,</code> | 정확한 EBREAK 명령이면 1인 종료 출력. |
| 9 | <code>    output wire        o_clu_illegal,</code> | 현재 디코더가 허용하지 않는 명령어 인코딩이면 1. |
| 10 | <code>    output wire        o_clu_MemRead,</code> | 데이터 메모리 읽기 요청. |
| 11 | <code>    output wire        o_clu_MemWrite,</code> | 데이터 메모리 쓰기 요청. |
| 12 | <code>    output wire        o_clu_MemtoReg,</code> | rd에 ALU 결과 대신 load 결과를 쓸지 결정한다. |
| 13 | <code>    output wire        o_clu_RegWrite,</code> | 목적 레지스터에 결과를 기록할 명령인지 나타낸다. |
| 14 | <code>    output wire [1:0]  ALUSrc1,</code> | ALU 첫 피연산자 선택 2비트. |
| 15 | <code>    output wire [1:0]  ALUSrc2,</code> | ALU 두 번째 피연산자 선택 2비트. |
| 16 | <code>    output wire [1:0]  o_clu_ALUOp,</code> | ALU 연산의 상위 분류 2비트. |
| 17 | <code>    output wire [5:0]  o_clu_imm_format</code> | R/I/S/B/U/J 형식을 나타내는 6비트 one-hot 출력. |
| 18 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 19 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 20 | <code>    wire [6:0] opcode = i_clu_inst[6:0];</code> | 명령어 하위 7비트에서 opcode를 추출한다. |
| 21 | <code>    wire [2:0] funct3 = i_clu_inst[14:12];</code> | bits 14:12에서 연산 세부 종류 funct3를 추출한다. |
| 22 | <code>    wire [6:0] funct7 = i_clu_inst[31:25];</code> | bits 31:25를 funct7로 해석한다. 실제 I형 비시프트 명령에서는 이 부분도 immediate이므로 무조건 검사하면 안 된다. |
| 23 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 24 | <code>    wire is_r      = (opcode == 7'b0110011);</code> | opcode 0x33은 R형 레지스터 간 산술·논리 명령. |
| 25 | <code>    wire is_i_alu  = (opcode == 7'b0010011);</code> | opcode 0x13은 I형 immediate 산술·논리 명령. |
| 26 | <code>    wire is_load   = (opcode == 7'b0000011);</code> | opcode 0x03은 load. |
| 27 | <code>    wire is_store  = (opcode == 7'b0100011);</code> | opcode 0x23은 store. |
| 28 | <code>    wire is_branch = (opcode == 7'b1100011);</code> | opcode 0x63은 조건 분기. |
| 29 | <code>    wire is_jal    = (opcode == 7'b1101111);</code> | opcode 0x6f는 JAL. |
| 30 | <code>    wire is_jalr   = (opcode == 7'b1100111);</code> | opcode 0x67은 JALR 계열로 분류한다. 여기서는 funct3를 검사하지 않는다. |
| 31 | <code>    wire is_lui    = (opcode == 7'b0110111);</code> | opcode 0x37은 LUI. |
| 32 | <code>    wire is_auipc  = (opcode == 7'b0010111);</code> | opcode 0x17은 AUIPC. |
| 33 | <code>    wire is_ebreak = (i_clu_inst == 32'h00100073);</code> | opcode만 아니라 명령어 전체가 0x00100073일 때 EBREAK로 인식한다. |
| 34 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 35 | <code>    // legality of the funct fields</code> | funct3와 funct7의 허용 인코딩을 검사하는 구간 제목. |
| 36 | <code>    wire f7_zero  = (funct7 == 7'b0000000);</code> | 기본 R형 연산과 논리 시프트의 funct7=0000000을 확인한다. |
| 37 | <code>    wire f7_alt   = (funct7 == 7'b0100000);</code> | SUB/SRA의 대체 funct7=0100000을 확인한다. |
| 38 | <code>    wire r_ok     = f7_zero &#124; (f7_alt &amp; ((funct3 == 3'b000) &#124; (funct3 == 3'b101)));</code> | R형은 funct7=0을 허용하고, funct7=0x20은 funct3=000(SUB) 또는 101(SRA)일 때만 허용한다. |
| 39 | <code>    wire shift_i  = (funct3 == 3'b001) &#124; (funct3 == 3'b101);</code> | SLLI와 SRLI/SRAI처럼 immediate의 상위 비트 제한이 필요한 명령인지 판별한다. |
| 40 | <code>    wire i_ok     = ~shift_i &#124; ((funct3 == 3'b001) ? f7_zero : (f7_zero &#124; f7_alt));</code> | 비시프트 I형은 상위 immediate를 제한하지 않는다. SLLI는 f7=0만, 오른쪽 시프트는 f7=0 또는 0x20을 허용한다. |
| 41 | <code>    wire load_ok  = (funct3 == 3'b000) &#124; (funct3 == 3'b001) &#124; (funct3 == 3'b010) &#124;</code> | load의 funct3 000(LB), 001(LH), 010(LW)을 허용하는 조건을 시작한다. |
| 42 | <code>                    (funct3 == 3'b100) &#124; (funct3 == 3'b101);</code> | 이전 줄에 100(LBU), 101(LHU)을 OR로 추가하고 선언을 끝낸다. |
| 43 | <code>    wire store_ok = (funct3 == 3'b000) &#124; (funct3 == 3'b001) &#124; (funct3 == 3'b010);</code> | store는 SB/SH/SW의 funct3 000/001/010만 허용한다. |
| 44 | <code>    wire br_ok    = ~((funct3 == 3'b010) &#124; (funct3 == 3'b011));</code> | branch에서는 예약된 010/011만 제외해 BEQ/BNE/BLT/BGE/BLTU/BGEU를 허용한다. |
| 45 | <code>    //wire jalr_ok  = (funct3 == 3'b000); //Not mentioned in RV32 spec</code> | 주석 처리된 검사라 실행되지 않는다. 표준 JALR의 funct3는 000이므로 “spec에 없다”는 주석은 부정확하다. |
| 46 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 47 | <code>    assign o_clu_illegal = ~((is_r &amp; r_ok) &#124; (is_i_alu &amp; i_ok) &#124; (is_load &amp; load_ok) &#124;</code> | 허용된 명령 조건을 OR로 모은 뒤 전체를 반전해 illegal을 만든다. 이 줄은 R, I ALU, load 조건이다. |
| 48 | <code>                             (is_store &amp; store_ok) &#124; (is_branch &amp; br_ok) &#124; is_jal &#124;</code> | store와 branch는 각 funct3 검사도 통과해야 한다. JAL은 추가 funct 필드가 없다. |
| 49 | <code>                             (is_jalr) &#124; is_lui &#124; is_auipc &#124; is_ebreak);</code> | JALR opcode, LUI, AUIPC, EBREAK를 추가한다. JALR에 funct3 검사 조건이 빠져 있다. |
| 50 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 51 | <code>    // raw control signals; trap gating is done in hart</code> | 제어기는 원시 제어를 출력하고 trap에 따른 차단은 hart에서 한다는 설계 설명. |
| 52 | <code>    assign o_clu_Branch    = is_branch;</code> | branch 여부를 그대로 내보낸다. illegal branch라도 raw 신호는 1일 수 있다. |
| 53 | <code>    assign o_clu_jump      = is_jal &#124; is_jalr;</code> | JAL과 JALR 중 하나면 무조건 점프이다. |
| 54 | <code>    assign o_clu_targetSrc = is_jalr;</code> | JALR만 목표 계산의 기준을 rs1로 선택한다. |
| 55 | <code>    assign o_clu_halt      = is_ebreak;</code> | EBREAK에 halt를 켠다. 이 프로젝트에서는 실행 종료 관례이다. |
| 56 | <code>    assign o_clu_MemRead   = is_load;</code> | load opcode에서 읽기 요청. |
| 57 | <code>    assign o_clu_MemWrite  = is_store;</code> | store opcode에서 쓰기 요청. |
| 58 | <code>    assign o_clu_MemtoReg  = is_load;</code> | load에서만 write-back으로 메모리 데이터를 선택한다. |
| 59 | <code>    assign o_clu_RegWrite  = is_r &#124; is_i_alu &#124; is_load &#124; is_jal &#124; is_jalr &#124; is_lui &#124; is_auipc;</code> | R/I ALU, load, 두 점프, LUI, AUIPC는 rd를 기록한다. store/branch/EBREAK는 기록하지 않는다. |
| 60 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 61 | <code>    // 00 rs1, 01 PC+4, 10 PC, 11 zero</code> | ALUSrc1 코드 설명: 00=rs1, 01=PC+4, 10=PC, 11=0. |
| 62 | <code>    assign ALUSrc1 = is_lui ? 2'b11 :</code> | Src1 우선 선택: LUI면 11(0). 중첩 삼항 연산자의 첫 조건이다. |
| 63 | <code>                     is_auipc ? 2'b10 :</code> | LUI가 아니고 AUIPC이면 10(현재 PC). |
| 64 | <code>                     (is_jal &#124; is_jalr) ? 2'b01 : 2'b00;</code> | 앞 조건이 아니고 점프이면 01(PC+4), 나머지는 00(rs1). |
| 65 | <code>    // 00 rs2, 01 imm, 10 zero</code> | ALUSrc2 코드 설명: 00=rs2, 01=immediate, 10=0. |
| 66 | <code>    assign ALUSrc2 = (is_r &#124; is_branch) ? 2'b00 :</code> | Src2는 R형 또는 branch에서 00(rs2). |
| 67 | <code>                     (is_jal &#124; is_jalr) ? 2'b10 : 2'b01;</code> | 점프이면 10(0), 나머지는 01(immediate). |
| 68 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 69 | <code>    // 00 add, 01 branch, 10 R-type, 11 I-type ALU</code> | ALUOp의 네 분류 설명: 00=덧셈, 01=branch, 10=R ALU, 11=I ALU. |
| 70 | <code>    // (00 add : LUI, AUIPC, LOAD, STORE, JAL, JALR)</code> | 00 덧셈 경로를 쓰는 명령: LUI, AUIPC, LOAD, STORE, JAL, JALR. |
| 71 | <code>    assign o_clu_ALUOp = is_r ? 2'b10 : is_i_alu ? 2'b11 : is_branch ? 2'b01 : 2'b00;</code> | R이면 10, I ALU이면 11, branch이면 01, 그 외에는 덧셈용 00을 내보낸다. |
| 72 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 73 | <code>    // one-hot: [0]=R [1]=I [2]=S [3]=B [4]=U [5]=J</code> | one-hot 형식의 각 비트 위치: R/I/S/B/U/J 순서가 bits 0~5에 대응한다. |
| 74 | <code>    assign o_clu_imm_format = {is_jal, (is_lui &#124; is_auipc), is_branch, is_store,</code> | 6비트 연결의 상위부터 J, U, B, S 형식 플래그를 배치한다. |
| 75 | <code>                               (is_i_alu &#124; is_load &#124; is_jalr), is_r};</code> | 하위에 I와 R 플래그를 연결한다. 결과 bit 0=R, bit 5=J이며 EBREAK 등은 전부 0이다. |
| 76 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |
| 77 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `2813576b7fd304df6637aa84961455039927dab7a295b9b2e895a3cd781cf09c`
