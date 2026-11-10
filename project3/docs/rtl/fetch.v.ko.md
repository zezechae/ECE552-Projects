# fetch.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/fetch.v)

원본 물리적 줄 수: **42줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

PC라는 32비트 상태를 보관하고 다음 주소를 계산한다. 모듈 이름이 fetch이지만 instruction memory 자체는 포함하지 않고 PC를 메모리 주소로 내보낸다.

- 순차 실행: PC+4.
- taken branch/JAL: PC+immediate.
- JALR: (rs1+immediate)의 bit0을 0으로 정리.
- trap: redirect를 막고 PC+4를 선택.
- EBREAK halt: 실제 PC 레지스터 갱신 중지.

reset은 rst_n=0이 유효한 동기 reset이다. hart의 active-high i_rst를 반전해 연결한다. JALR에서 bit0을 지우는 것은 bit1까지 지우는 4바이트 정렬과 다르며 bit1=1은 hart에서 trap이 된다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>module fetch #(</code> | 매개변수 목록을 가진 fetch 모듈을 선언한다. 이 파일 자체에는 default_nettype none 지시문이 없다. |
| 2 | <code>    parameter RESET_ADDR = 32'h00000000</code> | reset 시 시작 PC의 기본값은 0이다. |
| 3 | <code>) (</code> | parameter 목록을 닫고 포트를 연다. |
| 4 | <code>    input  wire        clk,</code> | PC 갱신용 클록. |
| 5 | <code>    input  wire        rst_n,                 // active-low, synchronous</code> | active-low 동기 reset. 이름의 _n은 낮을 때 유효하다는 관례이다. |
| 6 | <code>    input  wire        i_clu_branch,</code> | 조건 분기 명령인지 받는다. |
| 7 | <code>    input  wire        i_clu_halt,</code> | halt일 때 PC를 유지한다. |
| 8 | <code>    input  wire        i_alu_branch_taken,</code> | ALU 비교를 바탕으로 만든 분기 조건의 참/거짓 입력. |
| 9 | <code>    input  wire        i_clu_jump,            // JAL or JALR</code> | JAL/JALR 무조건 점프 입력. |
| 10 | <code>    input  wire        i_clu_targetSrc,       // 1 = JALR (rs1 + imm), 0 = PC + imm</code> | 목표 기준 선택: 1이면 rs1, 0이면 현재 PC. |
| 11 | <code>    input  wire [31:0] i_rf_rs1_rdata,</code> | JALR의 기준 주소에 필요한 rs1 값. |
| 12 | <code>    input  wire [31:0] i_imm_o_immediate,</code> | 분기·점프 주소 오프셋 immediate. |
| 13 | <code>    input  wire        i_clu_trap,</code> | 현재 명령의 trap. redirect를 차단한다. |
| 14 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 15 | <code>    output wire [31:0] o_instr_mem_rd_addr,</code> | instruction memory에 내보낼 현재 PC 주소. |
| 16 | <code>    output wire [31:0] o_pc_plus_4,           // rd write-back for JAL/JALR</code> | 점프의 rd에 기록할 복귀 주소 PC+4. |
| 17 | <code>    output wire [31:0] o_target,              // branch/jump target (for misalignment trap)</code> | trap 검사에도 필요한 원래 목표 주소. |
| 18 | <code>    output wire        o_redirect,            // 1 when branch/jump is actually taken</code> | 명령의 분기 조건상 redirect할지 나타낸다. 아직 trap으로 차단되기 전이다. |
| 19 | <code>    output wire [31:0] o_next_pc,             // goes to o_retire_next_pc</code> | 조합식 다음 PC 후보. halt에 의한 실제 PC 유지까지 반영한 값은 아니다. |
| 20 | <code>    output reg  [31:0] PC</code> | PC 상태를 output reg로 선언한다. 내부 상태이면서 외부에도 보인다. |
| 21 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 22 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 23 | <code>    wire [31:0] base = i_clu_targetSrc ? i_rf_rs1_rdata : PC;</code> | JALR이면 rs1, 아니면 PC를 목표 주소 계산 기준으로 고른다. |
| 24 | <code>    wire [31:0] sum  = base + i_imm_o_immediate;</code> | 기준 주소에 부호 확장된 immediate를 더한다. 결과는 32비트이다. |
| 25 | <code>    assign o_target  = i_clu_targetSrc ? {sum[31:1], 1'b0} : sum;</code> | JALR이면 sum의 bit0만 0으로 바꾼다. branch/JAL은 sum을 그대로 사용한다. |
| 26 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 27 | <code>    assign o_pc_plus_4 = PC + 32'd4;</code> | 현재 PC에 4바이트를 더한 순차 주소. |
| 28 | <code>    assign o_redirect  = i_clu_jump &#124; (i_clu_branch &amp; i_alu_branch_taken);</code> | 무조건 점프이거나 조건 분기이면서 taken이면 redirect 요구가 1이다. |
| 29 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 30 | <code>    wire   pc_redirect = o_redirect &amp; ~i_clu_trap; </code> | trap이 없을 때만 redirect를 실제 PC 선택에 적용한다. |
| 31 | <code>    assign o_next_pc   = pc_redirect ? o_target : o_pc_plus_4;</code> | 유효 redirect면 목표 주소, 그 외에는 PC+4를 다음 PC 후보로 선택한다. |
| 32 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 33 | <code>    always @(posedge clk) begin</code> | PC를 저장하는 상승 에지 순차 블록. |
| 34 | <code>        if (!rst_n)</code> | rst_n=0이면 reset한다. sensitivity에 negedge rst_n이 없으므로 비동기 reset은 아니다. |
| 35 | <code>            PC &lt;= RESET_ADDR;</code> | reset이 유효한 클록 에지에 PC를 RESET_ADDR로 갱신 예약한다. |
| 36 | <code>        else if (!i_clu_halt)</code> | reset이 아니며 halt가 0일 때만 정상 갱신한다. halt=1이면 대입이 없어 PC를 유지한다. |
| 37 | <code>            PC &lt;= o_next_pc;</code> | 선택한 다음 주소를 PC 상태로 기록한다. |
| 38 | <code>    end</code> | PC를 저장하는 상승 에지 순차 always 블록을 닫는다. reset이나 halt 조건에 따라 상태 갱신 또는 유지가 결정된다. |
| 39 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 40 | <code>    assign o_instr_mem_rd_addr = PC;</code> | 현재 PC를 instruction memory 읽기 주소에 연속 연결한다. |
| 41 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 42 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |

원본 SHA-256: `e44504410989796b80d40177fbe42921a41599d75f00762a5d178a5f6dfc5f9f`
