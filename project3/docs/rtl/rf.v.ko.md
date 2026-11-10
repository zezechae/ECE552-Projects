# rf.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/rf.v)

원본 물리적 줄 수: **93줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

32비트 레지스터 32개를 담는다. 두 읽기 포트는 조합식, 한 쓰기 포트는 상승 에지에서 동작한다. reset은 동기식 active-high이다. x0의 읽기는 강제로 0이고 쓰기는 무시한다.

BYPASS_EN=1이면 같은 주소를 읽고 쓰는 순간 현재 write data가 곧바로 read data로 전달된다. 단일 사이클에서 `addi x1,x1,1`의 write data는 read data+1이므로 bypass를 켜면 read→ALU→write→read의 조합 피드백이 생긴다. hart는 이 때문에 BYPASS_EN=0으로 인스턴스화한다.

reset은 x0까지 32개를 모두 지우지만, 일반 동작에서 x0를 유지하는 직접적인 장치는 쓰기 주소 0 차단과 읽기 주소 0 강제 출력이다. `TODO` 주석 아래에 이미 구현이 존재한다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 3 | <code>// The register file is effectively a single cycle memory with 32-bit words</code> | 레지스터 파일의 원소 폭이 32비트라는 모듈 설명. |
| 4 | <code>// and depth 32. It has two asynchronous read ports, allowing two independent</code> | 깊이가 32개이고 비동기 읽기 포트가 두 개라는 설명. |
| 5 | <code>// registers to be read at the same time combinationally, and one synchronous</code> | 두 레지스터를 조합식으로 동시에 읽고 한 포트로 동기 쓰기한다는 설명. |
| 6 | <code>// write port, allowing a register to be written to on the next clock edge.</code> | 쓰기는 다음 활성 클록 에지에서 저장 상태에 반영된다는 설명. |
| 7 | <code>// The register &#96;x0&#96; is hardwired to zero, and writes to it are ignored.</code> | x0 읽기는 0이고 x0 쓰기는 무시한다는 아키텍처 규칙. |
| 8 | <code>module rf #(</code> | 매개변수 있는 rf 모듈 선언. `#(`는 포트가 아니라 parameter 목록의 시작이다. |
| 9 | <code>    // When this parameter is set to 1, "RF bypass" mode is enabled. This</code> | 매개변수를 1로 하면 bypass 모드를 활성화한다는 설명. |
| 10 | <code>    // allows data at the write port to be observed at the read ports</code> | bypass에서는 write 포트의 값을 read 포트가 볼 수 있다는 설명. |
| 11 | <code>    // immediately without having to wait for the next clock edge. This is</code> | 이 우회 전달은 클록 에지를 기다리지 않고 조합식으로 동작한다는 설명. |
| 12 | <code>    // a common forwarding optimization in a pipelined core (project 5), but</code> | 파이프라인에서 forwarding 최적화로 사용할 수 있다는 설명. |
| 13 | <code>    // will cause a single-cycle processor to behave incorrectly.</code> | 현재 단일 사이클에서는 bypass가 잘못된 동작을 유발할 수 있다는 경고. |
| 14 | <code>    //</code> | 주석 안의 빈 구분 줄. 동작하는 문장이 아니다. |
| 15 | <code>    // You are required to implement and test both modes. In project 3 and 4,</code> | 원래 과제는 두 모드를 구현하고 검증하도록 요구한다는 주석. |
| 16 | <code>    // you will set this to 0, before enabling it in project 5.</code> | project3/4에서는 0, project5에서는 1을 사용하도록 안내하는 과제 주석. |
| 17 | <code>    parameter BYPASS_EN = 0</code> | 우회 전달 기능의 기본값은 0. 인스턴스에서 변경할 수 있는 elaboration 시점 설정이다. |
| 18 | <code>) (</code> | parameter 목록을 닫고 실제 포트 목록을 연다. |
| 19 | <code>    // Global clock.</code> | 다음 포트가 전체 클록이라는 주석. |
| 20 | <code>    input  wire        i_clk,</code> | 레지스터 쓰기 및 reset을 샘플링하는 클록 입력. |
| 21 | <code>    // Synchronous active-high reset.</code> | 다음 reset이 동기식 active-high라는 주석. |
| 22 | <code>    input  wire        i_rst,</code> | 동기식 active-high reset 입력. |
| 23 | <code>    // Both read register ports are asynchronous (zero-cycle). That is, read</code> | 두 읽기 포트가 비동기식이라는 설명. 여기서 비동기는 별도의 비동기 클록이라는 뜻이 아니다. |
| 24 | <code>    // data is visible combinationally without having to wait for a clock.</code> | 읽기 주소 변화에 조합적으로 반응해 클록 대기 없이 데이터가 나온다는 뜻이다. 실제 전파 지연은 존재한다. |
| 25 | <code>    //</code> | 주석 안의 빈 구분 줄. 동작하는 문장이 아니다. |
| 26 | <code>    // Register read port 1, with input address [0, 31] and output data.</code> | 첫 번째 읽기 포트의 주소 범위가 0~31임을 설명한다. |
| 27 | <code>    input  wire [ 4:0] i_rs1_raddr,</code> | 읽기 포트 1의 5비트 주소. 2^5=32개를 선택한다. |
| 28 | <code>    output wire [31:0] o_rs1_rdata,</code> | 읽기 포트 1의 32비트 데이터 출력. |
| 29 | <code>    // Register read port 2, with input address [0, 31] and output data.</code> | 두 번째 읽기 포트도 주소 0~31과 데이터 출력을 가진다는 주석. |
| 30 | <code>    input  wire [ 4:0] i_rs2_raddr,</code> | 읽기 포트 2의 5비트 주소. |
| 31 | <code>    output wire [31:0] o_rs2_rdata,</code> | 읽기 포트 2의 32비트 데이터 출력. |
| 32 | <code>    // The register write port is synchronous. When write is enabled, the</code> | 쓰기 포트는 읽기와 달리 클록에 동기화한다는 설명. |
| 33 | <code>    // write data is visible after the next clock edge.</code> | 활성 클록 에지 뒤에 저장된 쓰기 결과가 읽기 포트에 보인다는 설명. |
| 34 | <code>    //</code> | 주석 안의 빈 구분 줄. 동작하는 문장이 아니다. |
| 35 | <code>    // Write register enable, address [0, 31] and input data.</code> | 다음 세 입력이 쓰기 허용·주소·데이터임을 설명한다. |
| 36 | <code>    input  wire        i_rd_wen,</code> | 쓰기 허용 입력. 1인 상승 에지에서만 기록한다. |
| 37 | <code>    input  wire [ 4:0] i_rd_waddr,</code> | 쓸 레지스터 번호 5비트. |
| 38 | <code>    input  wire [31:0] i_rd_wdata</code> | 쓸 데이터 32비트. |
| 39 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 40 | <code>    // TODO: Fill in your implementation here.</code> | 초기 템플릿의 TODO 주석이 남아 있다. 아래에 구현이 있으므로 미구현 상태라는 뜻은 아니다. |
| 41 | <code>    reg [31:0] register_file [0:31];</code> | `[31:0]`은 각 원소 폭, 이름 뒤 `[0:31]`은 배열 인덱스이다. 32비트 32개, 총 1024비트 상태이다. |
| 42 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 43 | <code>    always @(posedge i_clk) begin</code> | 클록 상승 에지에서만 실행되는 순차 블록. |
| 44 | <code>        if(i_rst) begin</code> | reset이 1이면 일반 쓰기보다 우선해서 전체 레지스터를 0으로 갱신 예약한다. |
| 45 | <code>            register_file[0] &lt;= 32'b0;</code> | reset 시 x0의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 46 | <code>            register_file[1] &lt;= 32'b0;</code> | reset 시 x1의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 47 | <code>            register_file[2] &lt;= 32'b0;</code> | reset 시 x2의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 48 | <code>            register_file[3] &lt;= 32'b0;</code> | reset 시 x3의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 49 | <code>            register_file[4] &lt;= 32'b0;</code> | reset 시 x4의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 50 | <code>            register_file[5] &lt;= 32'b0;</code> | reset 시 x5의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 51 | <code>            register_file[6] &lt;= 32'b0;</code> | reset 시 x6의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 52 | <code>            register_file[7] &lt;= 32'b0;</code> | reset 시 x7의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 53 | <code>            register_file[8] &lt;= 32'b0;</code> | reset 시 x8의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 54 | <code>            register_file[9] &lt;= 32'b0;</code> | reset 시 x9의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 55 | <code>            register_file[10] &lt;= 32'b0;</code> | reset 시 x10의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 56 | <code>            register_file[11] &lt;= 32'b0;</code> | reset 시 x11의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 57 | <code>            register_file[12] &lt;= 32'b0;</code> | reset 시 x12의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 58 | <code>            register_file[13] &lt;= 32'b0;</code> | reset 시 x13의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 59 | <code>            register_file[14] &lt;= 32'b0;</code> | reset 시 x14의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 60 | <code>            register_file[15] &lt;= 32'b0;</code> | reset 시 x15의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 61 | <code>            register_file[16] &lt;= 32'b0;</code> | reset 시 x16의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 62 | <code>            register_file[17] &lt;= 32'b0;</code> | reset 시 x17의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 63 | <code>            register_file[18] &lt;= 32'b0;</code> | reset 시 x18의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 64 | <code>            register_file[19] &lt;= 32'b0;</code> | reset 시 x19의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 65 | <code>            register_file[20] &lt;= 32'b0;</code> | reset 시 x20의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 66 | <code>            register_file[21] &lt;= 32'b0;</code> | reset 시 x21의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 67 | <code>            register_file[22] &lt;= 32'b0;</code> | reset 시 x22의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 68 | <code>            register_file[23] &lt;= 32'b0;</code> | reset 시 x23의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 69 | <code>            register_file[24] &lt;= 32'b0;</code> | reset 시 x24의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 70 | <code>            register_file[25] &lt;= 32'b0;</code> | reset 시 x25의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 71 | <code>            register_file[26] &lt;= 32'b0;</code> | reset 시 x26의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 72 | <code>            register_file[27] &lt;= 32'b0;</code> | reset 시 x27의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 73 | <code>            register_file[28] &lt;= 32'b0;</code> | reset 시 x28의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 74 | <code>            register_file[29] &lt;= 32'b0;</code> | reset 시 x29의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 75 | <code>            register_file[30] &lt;= 32'b0;</code> | reset 시 x30의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 76 | <code>            register_file[31] &lt;= 32'b0;</code> | reset 시 x31의 저장 원소를 32비트 0으로 갱신 예약한다. `<=`는 nonblocking 대입이며 여기서는 비교 연산자가 아니다. |
| 77 | <code>        end</code> | 32개 reset 대입을 담은 if 블록을 닫는다. |
| 78 | <code>        else if(i_rd_wen &amp;&amp; (i_rd_waddr != 5'b00000)) begin</code> | reset이 아니고 write enable이 1이며 주소가 x0가 아닐 때만 일반 쓰기를 한다. `&&`는 논리 AND이다. |
| 79 | <code>            register_file[i_rd_waddr] &lt;= i_rd_wdata;</code> | 쓰기 주소로 지정한 배열 원소에 입력 값을 nonblocking 대입한다. 클록 에지에서 RHS를 읽고 NBA 단계에서 상태를 갱신한다. |
| 80 | <code>        end</code> | 일반 쓰기 조건 블록 끝. |
| 81 | <code>    end</code> | 순차 always 블록 끝. 쓰지 않는 경우 기존 값이 유지되는 것이 의도된 저장 동작이다. |
| 82 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 83 | <code>    assign o_rs1_rdata = (i_rs1_raddr == 5'b0) ? 32'b0 : </code> | 읽기 주소 1이 0이면 저장 배열과 무관하게 0을 출력한다. |
| 84 | <code>                         (i_rs1_raddr == i_rd_waddr &amp;&amp; BYPASS_EN &amp;&amp; i_rd_wen) ? i_rd_wdata : </code> | 주소 일치·bypass 허용·쓰기 허용이 모두 참이면 아직 클록에 저장되지 않은 write data를 즉시 전달한다. |
| 85 | <code>                         register_file[i_rs1_raddr];</code> | 우회 조건이 아니면 배열의 현재 값을 비동기식으로 읽는다. |
| 86 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 87 | <code>    assign o_rs2_rdata = (i_rs2_raddr == 5'b0) ? 32'b0 : </code> | 두 번째 읽기 포트도 x0를 가장 우선해서 0으로 출력한다. |
| 88 | <code>                         (i_rs2_raddr == i_rd_waddr &amp;&amp; BYPASS_EN &amp;&amp; i_rd_wen) ? i_rd_wdata : </code> | 포트 2의 주소가 쓰기 주소와 같고 bypass가 활성화되면 write data를 전달한다. |
| 89 | <code>                         register_file[i_rs2_raddr];</code> | 그 외에는 두 번째 주소의 배열 값을 읽는다. 두 포트는 독립적으로 동시에 동작한다. |
| 90 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 91 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |
| 92 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 93 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `62e821f3a691a20c816ee96299848876f669cb627a5321b2aa3709881855267c`
