# hart.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/hart.v)

원본 물리적 줄 수: **229줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

CPU 최상위 모듈이다. instruction memory에서 받은 명령어를 해석하고 레지스터 읽기→연산→메모리→write-back 경로를 하나의 사이클에 연결한다. PC와 rf가 상승 에지에 상태를 갱신한다. instruction/data memory는 외부에 있으며 tb가 이를 모델링한다.

이 모듈은 하위 모듈의 **배선도** 역할을 한다. `.포트명(신호명)`은 소프트웨어 함수 호출이 아니라 동시에 존재하는 하드웨어 사이의 연결이다.

주요 경로는 다음과 같다.

1. inst→control_unit→제어 신호, inst→imm→immediate.
2. inst의 rs1/rs2→rf→두 피연산자.
3. operand mux→alu_control/alu→ALU 결과와 비교 플래그.
4. load/store: 유효 주소→mask/정렬 검사, rs2→store_align, memory data→load_format.
5. load 결과 또는 ALU 결과→rf 쓰기 포트.
6. 비교 플래그→branch_taken→fetch→다음 PC.
7. illegal/비정렬→trap→메모리와 rf 쓰기 차단, PC redirect 차단.

Retire 신호는 현재 사이클의 명령 및 효과를 보여 주는 관측 인터페이스이다. 이 구현은 별도의 retire 레지스터나 valid 제어 없이 valid=1을 내보낸다. 전체 예외 처리기, 파이프라인, 메모리 대기 프로토콜은 없다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 3 | <code>module hart #(</code> | CPU 최상위 hart 모듈의 매개변수 목록을 연다. |
| 4 | <code>    parameter RESET_ADDR = 32'h00000000</code> | reset 후 시작 PC. 인스턴스에서 바꿀 수 있다. |
| 5 | <code>) (</code> | parameter 목록을 닫고 포트 목록을 시작한다. |
| 6 | <code>    input  wire        i_clk,</code> | CPU 전체 클록 입력. |
| 7 | <code>    input  wire        i_rst,</code> | active-high 동기 reset 입력. rf에는 그대로, fetch에는 반전해서 전달한다. |
| 8 | <code>    output wire [31:0] o_imem_raddr,</code> | instruction memory에 읽을 주소를 출력한다. |
| 9 | <code>    input  wire [31:0] i_imem_rdata,</code> | 해당 주소의 32비트 명령어를 외부 메모리로부터 받는다. |
| 10 | <code>    output wire [31:0] o_dmem_addr,</code> | 데이터 메모리 주소. 아래에서는 4바이트 경계로 내린 주소를 내보낸다. |
| 11 | <code>    output wire        o_dmem_ren,</code> | 데이터 메모리 읽기 허용 출력. |
| 12 | <code>    output wire        o_dmem_wen,</code> | 데이터 메모리 쓰기 허용 출력. |
| 13 | <code>    output wire [31:0] o_dmem_wdata,</code> | lane에 맞춰 이동시킨 32비트 store 데이터. |
| 14 | <code>    output wire [ 3:0] o_dmem_mask,</code> | 각 byte lane을 선택하는 4비트 마스크. |
| 15 | <code>    input  wire [31:0] i_dmem_rdata,</code> | 데이터 메모리에서 읽은 32비트 버스 값. |
| 16 | <code>    output wire        o_retire_valid,</code> | 관측 중인 명령의 retire 기록이 유효함을 알리는 출력. |
| 17 | <code>    output wire [31:0] o_retire_inst,</code> | 관측 명령어 원문 32비트. |
| 18 | <code>    output wire        o_retire_trap,</code> | 관측 명령에서 trap이 검출됐는지 나타낸다. |
| 19 | <code>    output wire        o_retire_halt,</code> | EBREAK 종료인지 알리는 출력. |
| 20 | <code>    output wire [ 4:0] o_retire_rs1_raddr,</code> | 명령에서 추출한 rs1 레지스터 번호. |
| 21 | <code>    output wire [ 4:0] o_retire_rs2_raddr,</code> | 명령에서 추출한 rs2 레지스터 번호. |
| 22 | <code>    output wire [31:0] o_retire_rs1_rdata,</code> | rs1에서 읽은 값. |
| 23 | <code>    output wire [31:0] o_retire_rs2_rdata,</code> | rs2에서 읽은 값. |
| 24 | <code>    output wire [ 4:0] o_retire_rd_waddr,</code> | 관측되는 쓰기 대상 rd. 쓰기 차단이면 아래에서 0으로 만든다. |
| 25 | <code>    output wire [31:0] o_retire_rd_wdata,</code> | 관측되는 rd 쓰기 데이터. 실제 쓰기 여부는 주소/제어와 함께 해석한다. |
| 26 | <code>    output wire [31:0] o_retire_pc,</code> | 현재 실행 명령의 PC. |
| 27 | <code>    output wire [31:0] o_retire_next_pc</code> | fetch가 조합식으로 계산한 다음 PC 후보. |
| 28 | <code>&#96;ifdef RISCV_FORMAL</code> | RISCV_FORMAL 매크로가 정의됐을 때만 다음 부분을 컴파일한다. |
| 29 | <code>    ,&#96;RVFI_OUTPUTS,</code> | 외부 RVFI_OUTPUTS 매크로로 포트를 추가하려는 코드다. 매크로 정의가 이 프로젝트에는 없고 끝 쉼표도 있어 formal 구성이 완성됐다고 볼 수 없다. |
| 30 | <code>&#96;endif</code> | 조건부 컴파일 구간을 닫는다. 일반 빌드에서는 29행이 제외된다. |
| 31 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 32 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 33 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 34 | <code>    // Instruction fields</code> | 명령어 필드 추출 구간 제목. |
| 35 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 36 | <code>    wire [31:0] inst     = i_imem_rdata;</code> | instruction memory 입력에 inst라는 내부 이름을 붙인다. wire 선언 대입은 계속 입력을 따라간다. |
| 37 | <code>    wire [4:0]  rs1_addr = inst[19:15];</code> | 명령 bits19:15에서 rs1 주소 5비트를 추출한다. |
| 38 | <code>    wire [4:0]  rs2_addr = inst[24:20];</code> | 명령 bits24:20에서 rs2 주소 5비트를 추출한다. |
| 39 | <code>    wire [4:0]  rd_addr  = inst[11:7];</code> | 명령 bits11:7에서 rd 주소를 추출한다. |
| 40 | <code>    wire [2:0]  funct3   = inst[14:12];</code> | 명령 bits14:12에서 funct3를 추출한다. |
| 41 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 42 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 43 | <code>    // Control unit (pure function of the instruction word)</code> | 명령어만으로 출력이 정해지는 조합 제어기 구간 제목. |
| 44 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 45 | <code>    wire        clu_branch, clu_jump, clu_target_src, clu_halt, clu_illegal;</code> | 분기, 점프, 목표 기준, halt, illegal의 1비트 내부 연결선을 선언한다. |
| 46 | <code>    wire        clu_mem_read, clu_mem_write, clu_mem_to_reg, clu_reg_write;</code> | 메모리 읽기·쓰기, write-back 선택, 레지스터 쓰기의 1비트 제어선. |
| 47 | <code>    wire [1:0]  alu_src1_sel, alu_src2_sel, alu_op;</code> | 두 operand mux 선택과 ALU 상위 분류를 각각 2비트로 선언한다. |
| 48 | <code>    wire [5:0]  imm_format;</code> | immediate 형식 one-hot 연결선 6비트. |
| 49 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 50 | <code>    control_unit u_control (</code> | control_unit 하드웨어 인스턴스 u_control을 만든다. |
| 51 | <code>        .i_clu_inst       (inst),</code> | 명령어를 제어기 입력에 연결한다. |
| 52 | <code>        .o_clu_Branch     (clu_branch),</code> | 분기 opcode 신호를 clu_branch에 받는다. |
| 53 | <code>        .o_clu_jump       (clu_jump),</code> | 점프 신호를 clu_jump에 받는다. |
| 54 | <code>        .o_clu_targetSrc  (clu_target_src),</code> | JALR 기준 선택 신호를 clu_target_src로 받는다. |
| 55 | <code>        .o_clu_halt       (clu_halt),</code> | EBREAK 판별 출력을 clu_halt로 받는다. |
| 56 | <code>        .o_clu_illegal    (clu_illegal),</code> | 지원하지 않는 명령 판별을 clu_illegal로 받는다. |
| 57 | <code>        .o_clu_MemRead    (clu_mem_read),</code> | 메모리 읽기 raw 제어를 받는다. |
| 58 | <code>        .o_clu_MemWrite   (clu_mem_write),</code> | 메모리 쓰기 raw 제어를 받는다. |
| 59 | <code>        .o_clu_MemtoReg   (clu_mem_to_reg),</code> | 메모리 데이터를 rd에 쓸지 나타내는 신호를 받는다. |
| 60 | <code>        .o_clu_RegWrite   (clu_reg_write),</code> | 레지스터 raw 쓰기 제어를 받는다. |
| 61 | <code>        .ALUSrc1          (alu_src1_sel),</code> | 첫 ALU operand mux 선택을 받는다. |
| 62 | <code>        .ALUSrc2          (alu_src2_sel),</code> | 두 번째 ALU operand mux 선택을 받는다. |
| 63 | <code>        .o_clu_ALUOp      (alu_op),</code> | ALU 상위 명령 분류를 받는다. |
| 64 | <code>        .o_clu_imm_format (imm_format)</code> | immediate 조립 형식을 받는다. 마지막 연결이라 쉼표가 없다. |
| 65 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 66 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 67 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 68 | <code>    // Immediate generator</code> | 즉시값 생성기 연결 구간 제목. |
| 69 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 70 | <code>    wire [31:0] immediate;</code> | immediate 결과용 32비트 연결선. |
| 71 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 72 | <code>    imm u_imm (</code> | 조합 immediate 생성기 u_imm을 만든다. |
| 73 | <code>        .i_inst      (inst),</code> | 원본 명령어를 immediate 생성기에 연결한다. |
| 74 | <code>        .i_format    (imm_format),</code> | 제어기의 one-hot 형식을 연결한다. |
| 75 | <code>        .o_immediate (immediate)</code> | 재조립된 32비트 결과를 immediate에 받는다. |
| 76 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 77 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 78 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 79 | <code>    // Register file (BYPASS_EN must be 0 in a single-cycle design)</code> | 레지스터 파일 연결 구간. 단일 사이클은 bypass를 꺼야 한다는 안내. |
| 80 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 81 | <code>    wire [31:0] rs1_rdata, rs2_rdata;</code> | 두 레지스터 읽기 데이터를 담을 32비트 연결선 두 개. |
| 82 | <code>    wire [31:0] rd_wdata;</code> | 최종 write-back 데이터 연결선. |
| 83 | <code>    wire        rf_wen;</code> | trap 차단까지 반영할 최종 rf 쓰기 허용선. |
| 84 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 85 | <code>    rf #(.BYPASS_EN(0)) u_rf (</code> | rf 인스턴스의 BYPASS_EN을 0으로 고정한다. 단일 사이클의 조합 피드백 방지를 위한 설정이다. |
| 86 | <code>        .i_clk       (i_clk),</code> | CPU 클록을 rf에 연결한다. |
| 87 | <code>        .i_rst       (i_rst),</code> | active-high reset을 rf에 연결한다. |
| 88 | <code>        .i_rs1_raddr (rs1_addr),</code> | 명령의 rs1 번호를 첫 읽기 주소에 연결한다. |
| 89 | <code>        .o_rs1_rdata (rs1_rdata),</code> | 첫 읽기 값을 rs1_rdata로 받는다. |
| 90 | <code>        .i_rs2_raddr (rs2_addr),</code> | 명령의 rs2 번호를 둘째 읽기 주소에 연결한다. |
| 91 | <code>        .o_rs2_rdata (rs2_rdata),</code> | 둘째 읽기 값을 rs2_rdata로 받는다. |
| 92 | <code>        .i_rd_wen    (rf_wen),</code> | trap까지 반영된 rf_wen을 쓰기 허용에 연결한다. |
| 93 | <code>        .i_rd_waddr  (rd_addr),</code> | 명령의 rd 번호를 쓰기 주소에 연결한다. |
| 94 | <code>        .i_rd_wdata  (rd_wdata)</code> | 최종 결과 rd_wdata를 쓰기 데이터에 연결한다. |
| 95 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 96 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 97 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 98 | <code>    // ALU operand muxes</code> | ALU 피연산자 선택 mux 구간 제목. |
| 99 | <code>    //   src1: 00 rs1, 01 PC+4, 10 PC, 11 zero</code> | 첫 operand 선택 코드 설명: rs1, PC+4, PC, 0. |
| 100 | <code>    //   src2: 00 rs2, 01 imm,  10 zero (11 unused -&gt; zero)</code> | 둘째 operand 선택 설명. 11도 구현상 0을 선택한다. |
| 101 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 102 | <code>    wire [31:0] pc, pc_plus_4, target_addr, next_pc;</code> | PC, PC+4, 분기·점프 목표, 다음 PC 후보의 32비트 연결선. |
| 103 | <code>    wire        redirect;</code> | 분기 조건 또는 jump가 요구하는 redirect 신호. |
| 104 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 105 | <code>    wire [31:0] alu_op1 = (alu_src1_sel == 2'b00) ? rs1_rdata :</code> | Src1=00이면 rs1 값을 선택한다. 연속 wire 식의 중첩 mux 시작. |
| 106 | <code>                          (alu_src1_sel == 2'b01) ? pc_plus_4 :</code> | Src1=01이면 PC+4를 선택해 점프의 복귀 주소 계산에 사용한다. |
| 107 | <code>                          (alu_src1_sel == 2'b10) ? pc        : 32'b0;</code> | Src1=10이면 현재 PC(AUIPC), 나머지 11이면 0(LUI)을 선택한다. |
| 108 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 109 | <code>    wire [31:0] alu_op2 = (alu_src2_sel == 2'b00) ? rs2_rdata :</code> | Src2=00이면 rs2를 선택한다. R형 연산과 branch 비교에서 사용한다. |
| 110 | <code>                          (alu_src2_sel == 2'b01) ? immediate : 32'b0;</code> | Src2=01이면 immediate, 나머지는 0을 선택한다. 점프에서는 0을 더해 PC+4를 보존한다. |
| 111 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 112 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 113 | <code>    // ALU control + ALU</code> | 세부 제어와 ALU 연결 구간 제목. |
| 114 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 115 | <code>    wire [2:0]  alu_opsel;</code> | ALU 내부 결과 선택 코드 3비트. |
| 116 | <code>    wire        alu_sub, alu_unsigned, alu_arith, bcomp, bnot;</code> | 뺄셈/unsigned/산술 시프트 및 분기 비교 선택·반전 신호. |
| 117 | <code>    wire [31:0] alu_result;</code> | ALU의 32비트 결과 연결선. |
| 118 | <code>    wire        alu_eq, alu_slt;</code> | ALU의 동등 비교와 작다 비교 플래그. |
| 119 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 120 | <code>    alu_control u_alu_control (</code> | ALU 세부 제어기 u_alu_control을 만든다. |
| 121 | <code>        .i_ALUOp    (alu_op),</code> | 주 제어기가 만든 ALUOp를 전달한다. |
| 122 | <code>        .i_funct3   (funct3),</code> | 명령 funct3를 전달한다. |
| 123 | <code>        .i_funct7_5 (inst[30]),</code> | inst[30], 즉 funct7의 bit5를 전달한다. |
| 124 | <code>        .o_opsel    (alu_opsel),</code> | ALU 결과 선택 코드를 alu_opsel에 받는다. |
| 125 | <code>        .o_sub      (alu_sub),</code> | 뺄셈 선택을 alu_sub에 받는다. |
| 126 | <code>        .o_unsigned (alu_unsigned),</code> | unsigned 비교 선택을 alu_unsigned에 받는다. |
| 127 | <code>        .o_arith    (alu_arith),</code> | 산술 오른쪽 시프트 선택을 alu_arith에 받는다. |
| 128 | <code>        .o_bcomp    (bcomp),</code> | 분기 비교 플래그 종류를 bcomp에 받는다. |
| 129 | <code>        .o_bnot     (bnot)</code> | 분기 조건 반전 여부를 bnot에 받는다. |
| 130 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 131 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 132 | <code>    alu u_alu (</code> | 실제 연산기 u_alu를 만든다. |
| 133 | <code>        .i_opsel    (alu_opsel),</code> | ALU 결과 선택 코드를 연결한다. |
| 134 | <code>        .i_sub      (alu_sub),</code> | 뺄셈 선택을 연결한다. |
| 135 | <code>        .i_unsigned (alu_unsigned),</code> | 비교 signed/unsigned 선택을 연결한다. |
| 136 | <code>        .i_arith    (alu_arith),</code> | 오른쪽 시프트 방식 선택을 연결한다. |
| 137 | <code>        .i_op1      (alu_op1),</code> | 첫 operand mux의 결과를 ALU 입력 1에 연결한다. |
| 138 | <code>        .i_op2      (alu_op2),</code> | 둘째 operand mux 결과를 ALU 입력 2에 연결한다. |
| 139 | <code>        .o_result   (alu_result),</code> | 계산 결과를 alu_result에 받는다. |
| 140 | <code>        .o_eq       (alu_eq),</code> | 동등 플래그를 alu_eq에 받는다. |
| 141 | <code>        .o_slt      (alu_slt)</code> | 선택된 signed/unsigned 작다 플래그를 alu_slt에 받는다. |
| 142 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 143 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 144 | <code>    wire branch_taken = (bcomp ? alu_slt : alu_eq) ^ bnot;</code> | bcomp=0이면 eq, 1이면 slt를 선택하고 bnot으로 XOR 반전한다. BEQ=eq, BNE=!eq, BLT/BLTU=slt, BGE/BGEU=!slt이다. |
| 145 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 146 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 147 | <code>    // Trap detection</code> | 불법 명령·비정렬 접근을 검출하는 구간 제목. |
| 148 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 149 | <code>    wire mem_misaligned;</code> | 메모리 주소 정렬 오류 연결선. 뒤쪽 u_mask_gen이 구동한다. |
| 150 | <code>    wire trap = clu_illegal &#124; mem_misaligned &#124; (redirect &amp; (target_addr[1:0] != 2'b00));</code> | illegal 또는 메모리 비정렬 또는 실제 요구된 redirect의 목표가 4바이트 비정렬이면 trap이다. 안 타는 branch의 목표가 비정렬인 것은 trap으로 만들지 않는다. |
| 151 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 152 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 153 | <code>    // Fetch / PC</code> | PC와 다음 주소 계산기 연결 구간 제목. |
| 154 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 155 | <code>    fetch #(.RESET_ADDR(RESET_ADDR)) u_fetch (</code> | fetch 인스턴스를 만들고 최상위 RESET_ADDR 매개변수를 전달한다. |
| 156 | <code>        .clk                 (i_clk),</code> | PC 갱신 클록을 연결한다. |
| 157 | <code>        .rst_n               (~i_rst),</code> | CPU의 active-high reset을 반전해 fetch의 active-low 동기 reset에 연결한다. |
| 158 | <code>        .i_clu_branch        (clu_branch),</code> | 분기 명령 여부를 연결한다. |
| 159 | <code>        .i_clu_halt          (clu_halt),</code> | EBREAK에서 PC를 유지하도록 halt를 전달한다. |
| 160 | <code>        .i_alu_branch_taken  (branch_taken),</code> | 계산된 branch 조건을 전달한다. |
| 161 | <code>        .i_clu_jump          (clu_jump),</code> | 무조건 jump 여부를 전달한다. |
| 162 | <code>        .i_clu_targetSrc     (clu_target_src),</code> | JALR이면 rs1을 기준 주소로 사용하도록 한다. |
| 163 | <code>        .i_rf_rs1_rdata      (rs1_rdata),</code> | JALR 목표 계산에 필요한 rs1 값을 전달한다. |
| 164 | <code>        .i_imm_o_immediate   (immediate),</code> | 분기·점프 오프셋 immediate를 전달한다. |
| 165 | <code>        .i_clu_trap          (trap),</code> | trap이면 redirect를 적용하지 않도록 알린다. trap 처리 주소로 이동시키는 입력은 없다. |
| 166 | <code>        .o_instr_mem_rd_addr (o_imem_raddr),</code> | fetch의 instruction 주소를 최상위 instruction memory 주소 출력에 직접 연결한다. |
| 167 | <code>        .o_pc_plus_4         (pc_plus_4),</code> | PC+4를 받아 점프 write-back용 operand로도 사용한다. |
| 168 | <code>        .o_target            (target_addr),</code> | 목표 주소를 받아 위 trap 정렬 검사에 사용한다. |
| 169 | <code>        .o_redirect          (redirect),</code> | trap 적용 전 redirect 요구를 받아 정렬 검사의 조건으로 쓴다. |
| 170 | <code>        .o_next_pc           (next_pc),</code> | 다음 PC 후보를 next_pc에 받는다. |
| 171 | <code>        .PC                  (pc)</code> | 실제 PC 레지스터 값을 내부 pc 연결선으로 받는다. 출력 포트 이름 PC의 대소문자도 일치해야 한다. |
| 172 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 173 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 174 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 175 | <code>    // Data memory interface</code> | 데이터 메모리의 mask·store 배치·load 확장 구간 제목. |
| 176 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 177 | <code>    wire [31:0] load_data;</code> | 메모리 버스에서 선택·확장된 load 결과의 32비트 연결선. |
| 178 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 179 | <code>    dmem_mask_gen u_mask_gen (</code> | 마스크와 메모리 정렬 오류를 계산할 인스턴스를 만든다. |
| 180 | <code>        .i_funct3     (inst[13:12]),</code> | funct3 중 하위 2비트만 전달한다. signed/unsigned 여부는 크기와 관계없다. |
| 181 | <code>        .i_offset     (alu_result[1:0]),</code> | word 정렬로 내리기 전 유효 주소의 하위 2비트를 전달한다. |
| 182 | <code>        .i_is_mem     (clu_mem_read &#124; clu_mem_write),</code> | load 또는 store일 때만 메모리 정렬 오류를 유효하게 만든다. |
| 183 | <code>        .o_mask       (o_dmem_mask),</code> | 마스크 결과를 CPU 외부 o_dmem_mask에 직접 연결한다. |
| 184 | <code>        .o_misaligned (mem_misaligned)</code> | 정렬 오류를 mem_misaligned에 받아 trap에 포함한다. |
| 185 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 186 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 187 | <code>    store_align u_store_align (</code> | store 데이터를 lane으로 옮기는 인스턴스. |
| 188 | <code>        .i_rs2_data (rs2_rdata),</code> | 원래 저장할 값인 rs2 데이터를 전달한다. |
| 189 | <code>        .i_funct3   (inst[13:12]),</code> | SB/SH/SW 크기를 전달한다. |
| 190 | <code>        .i_offset   (alu_result[1:0]),</code> | word 내부 byte offset을 전달한다. |
| 191 | <code>        .o_wdata    (o_dmem_wdata)</code> | 정렬된 쓰기 데이터를 외부 메모리 출력에 직접 연결한다. |
| 192 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 193 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 194 | <code>    load_format u_load_format (</code> | load 선택·확장 인스턴스. |
| 195 | <code>        .i_dmem_rdata (i_dmem_rdata),</code> | 외부 메모리의 aligned 32비트 버스 값을 전달한다. |
| 196 | <code>        .i_funct3     (funct3),</code> | 전체 funct3를 전달해 LB/LBU, LH/LHU를 구분한다. |
| 197 | <code>        .i_offset     (alu_result[1:0]),</code> | 유효 주소의 byte offset을 전달해 어느 lane인지 선택한다. |
| 198 | <code>        .o_load_data  (load_data)</code> | 확장한 결과를 load_data로 받는다. |
| 199 | <code>    );</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 200 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 201 | <code>    assign o_dmem_addr = {alu_result[31:2], 2'b00};</code> | 유효 주소의 하위 2비트를 00으로 바꿔 4바이트 정렬 base를 출력한다. 원래 offset은 mask와 format 모듈에 따로 보존돼 있다. |
| 202 | <code>    assign o_dmem_ren  = clu_mem_read  &amp; ~trap;</code> | load raw 제어가 있고 trap이 없을 때만 실제 메모리 읽기를 허용한다. reset gating은 없다. |
| 203 | <code>    assign o_dmem_wen  = clu_mem_write &amp; ~trap;</code> | store raw 제어가 있고 trap이 없을 때만 실제 메모리 쓰기를 허용한다. reset 중 외부 쓰기를 직접 막는 조건은 없다. |
| 204 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 205 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 206 | <code>    // Write-back</code> | 최종 결과와 레지스터 쓰기 허용을 결정하는 구간 제목. |
| 207 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 208 | <code>    assign rd_wdata = clu_mem_to_reg ? load_data : alu_result;</code> | load면 확장한 load_data, 아니면 ALU 결과를 write-back 데이터로 선택한다. |
| 209 | <code>    assign rf_wen   = clu_reg_write &amp; ~trap;</code> | 주 제어기의 레지스터 쓰기 요청을 trap이 없을 때만 허용한다. reset은 rf 내부에서 우선 처리한다. |
| 210 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 211 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 212 | <code>    // Retire interface</code> | 명령 실행을 외부에서 관측하는 retire 인터페이스 구간 제목. |
| 213 | <code>    // ------------------------------------------------------------------</code> | 주석 구간을 시각적으로 나누는 구분선. 회로는 생성하지 않는다. |
| 214 | <code>    assign o_retire_valid     = 1'b1;</code> | retire valid를 상수 1로 둔다. reset/halt/trap 시에도 자동으로 0이 되지 않으므로 외부 관측 시 주의한다. |
| 215 | <code>    assign o_retire_inst      = inst;</code> | 현재 instruction word를 retire에 보여 준다. |
| 216 | <code>    assign o_retire_trap      = trap;</code> | 현재 trap 조합 결과를 보여 준다. |
| 217 | <code>    assign o_retire_halt      = clu_halt;</code> | 현재 EBREAK 판별 결과를 halt로 보여 준다. |
| 218 | <code>    assign o_retire_rs1_raddr = rs1_addr;</code> | 원본 명령의 rs1 필드를 그대로 출력한다. rs1을 사용하지 않는 형식에도 의미 없는 번호가 나올 수 있다. |
| 219 | <code>    assign o_retire_rs2_raddr = rs2_addr;</code> | 원본 명령의 rs2 필드를 그대로 출력한다. 사용 여부를 opcode와 함께 해석한다. |
| 220 | <code>    assign o_retire_rs1_rdata = rs1_rdata;</code> | 레지스터 파일의 첫 읽기 값을 관측 출력에 연결한다. |
| 221 | <code>    assign o_retire_rs2_rdata = rs2_rdata;</code> | 레지스터 파일의 둘째 읽기 값을 관측 출력에 연결한다. |
| 222 | <code>    assign o_retire_rd_waddr  = rf_wen ? rd_addr : 5'd0;</code> | 실제 rf 쓰기 요청이 있으면 rd를 출력하고, 없으면 0을 출력한다. x0를 쓰는 명령도 0이므로 관측상 쓰기 없음으로 보인다. |
| 223 | <code>    assign o_retire_rd_wdata  = rd_wdata;</code> | write-back 후보 값을 항상 보여 준다. rd_waddr=0인 사이클에는 유효한 쓰기로 해석하면 안 된다. |
| 224 | <code>    assign o_retire_pc        = pc;</code> | 현재 PC 상태를 관측 출력으로 연결한다. |
| 225 | <code>    assign o_retire_next_pc   = next_pc;</code> | 계산된 다음 PC 후보를 관측한다. halt 시 PC는 유지되지만 이 값은 PC+4일 수 있다. |
| 226 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 227 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |
| 228 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 229 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `1eec10abf1465442198a9d7d0a102a92bdb9fc36a66d0863d3736e5714368b92`
