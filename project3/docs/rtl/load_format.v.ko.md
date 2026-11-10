# load_format.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/load_format.v)

원본 물리적 줄 수: **37줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

32비트 메모리 버스에서 원하는 byte/half를 선택해 32비트 레지스터 값으로 확장한다. funct3[1:0]은 크기, funct3[2]는 byte/half의 unsigned 여부이다.

| 명령 | funct3 | 변환 |
|---|---|---|
| LB | 000 | byte를 부호 확장 |
| LH | 001 | half를 부호 확장 |
| LW | 010 | 32비트 그대로 |
| LBU | 100 | byte를 0 확장 |
| LHU | 101 | half를 0 확장 |

예: 유효 주소 0x102에서 메모리 byte가 0x80이면, tb는 aligned word의 lane 2인 bits 23:16에 이 값을 둔다. LB는 0xffffff80, LBU는 0x00000080을 만든다. 나머지 lane이 X여도 선택한 lane만 확장하면 정상값이 나온다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>module load_format</code> | load 값 선택·확장 모듈 선언. |
| 3 | <code>(</code> | 포트 목록 시작. |
| 4 | <code>    input wire[31:0] i_dmem_rdata,</code> | 정렬된 word 주소 기준으로 배치된 32비트 메모리 데이터. |
| 5 | <code>    input wire[2:0]  i_funct3,</code> | 전체 3비트 funct3. 크기뿐 아니라 signed/unsigned도 필요하다. |
| 6 | <code>    input wire[1:0]  i_offset,</code> | 원래 유효 주소의 word 내부 byte offset. |
| 7 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 8 | <code>    output reg[31:0] o_load_data</code> | 레지스터에 기록할 최종 32비트 load 값. 조합 블록에서 대입하므로 reg 선언이다. |
| 9 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 10 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 11 | <code>always @(*) begin</code> | 조합 계산 블록 시작. |
| 12 | <code>    case({i_funct3[1:0], i_offset})</code> | funct3 하위 2비트와 offset을 연결해 크기·위치별로 처리한다. |
| 13 | <code>        4'b00_00: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[7:0]} : </code> | byte offset=0: unsigned이면 lane 0을 0 확장한다. `:` 뒤 signed 처리는 다음 줄에 이어진다. |
| 14 | <code>                                              {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]};</code> | signed이면 bit 7을 24번 반복해 상위에 붙인다. 24+8=32비트이며 LB의 부호 확장이다. |
| 15 | <code>        4'b00_01: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[15:8]} : </code> | byte offset=1: unsigned이면 bits 15:8을 0 확장한다. |
| 16 | <code>                                              {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]};</code> | signed이면 선택한 byte의 부호 bit 15를 24번 복제해 확장한다. |
| 17 | <code>        4'b00_10: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[23:16]} : </code> | byte offset=2: unsigned이면 bits 23:16을 0 확장한다. |
| 18 | <code>                                              {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]};</code> | signed이면 선택한 byte의 부호 bit 23을 복제한다. |
| 19 | <code>        4'b00_11: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[31:24]} : </code> | byte offset=3: unsigned이면 bits 31:24를 0 확장한다. |
| 20 | <code>                                              {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]};</code> | signed이면 byte 부호 bit 31을 복제해 상위 24비트에 채운다. |
| 21 | <code>        4'b01_00,</code> | half offset=0을 다음 offset=1과 묶는다. |
| 22 | <code>        4'b01_01: o_load_data = i_funct3[2] ? {16'b0, i_dmem_rdata[15:0]} : </code> | 하위 half bits 15:0을 선택한다. unsigned이면 상위 16비트를 0으로 채운다. offset=1은 hart에서 trap 처리된다. |
| 23 | <code>                                              {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]};</code> | signed half이면 bit 15를 16번 반복해 상위 16비트를 채운다. |
| 24 | <code>        4'b01_10,</code> | half offset=2를 다음 offset=3과 묶는다. |
| 25 | <code>        4'b01_11: o_load_data = i_funct3[2] ? {16'b0, i_dmem_rdata[31:16]} : </code> | 상위 half bits 31:16을 선택해 unsigned이면 0 확장한다. offset=3은 trap이다. |
| 26 | <code>                                              {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]};</code> | signed half이면 bit 31을 16번 복제해 부호 확장한다. |
| 27 | <code>        4'b10_00,</code> | word offset=0을 뒤 항목들과 묶는다. |
| 28 | <code>        4'b10_01,</code> | word offset=1도 같은 데이터 선택을 하지만 실제 접근은 trap으로 막힌다. |
| 29 | <code>        4'b10_10,</code> | word offset=2도 같은 word 선택 그룹이다. 실제 접근은 trap이다. |
| 30 | <code>        4'b10_11: o_load_data = i_dmem_rdata;</code> | word이면 32비트를 그대로 전달한다. 정상 주소는 offset=0이다. |
| 31 | <code>        default : o_load_data = 32'b0;</code> | 나머지 크기나 미정 선택값은 결과를 0으로 정한다. illegal 여부의 판단은 이 모듈이 아니라 제어기이다. |
| 32 | <code>    endcase</code> | case 선택 구문을 닫는다. 앞에서 선택된 한 항목의 대입으로 결과가 결정된다. |
| 33 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 34 | <code>end</code> | 가장 가까운 begin으로 연 블록을 닫는다. 여기서는 always 조합 블록의 끝이다. |
| 35 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 36 | <code>endmodule </code> | 현재 모듈 정의를 끝낸다. |
| 37 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `05171448a378699b160a0bdfbe0006ba819c4bef24fc86b1cb533967477a6e6c`
