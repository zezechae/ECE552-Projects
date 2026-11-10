# store_align.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/store_align.v)

원본 물리적 줄 수: **28줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

SB/SH의 rs2 하위 데이터를 쓰기 대상 lane으로 옮긴다. 저장할 크기를 잘라내는 최종 책임은 mask에 있다. 따라서 출력의 비활성 lane에 값이 남아 있어도 문제가 없다.

예: rs2=0x11223344, 유효 주소=0x103인 SB는 o_dmem_addr=0x100, mask=1000, wdata=0x44000000을 만든다. tb는 dmem[0x103]에 0x44만 기록한다.

SH에서 offset=1/3인 case가 있다고 해서 비정렬 half 저장을 지원하는 것은 아니다. 해당 접근은 dmem_mask_gen과 hart가 막는다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>module store_align</code> | 저장 데이터 정렬 모듈 선언. |
| 3 | <code>(</code> | 포트 목록 시작. |
| 4 | <code>    input  wire [31:0] i_rs2_data,</code> | store할 원래 rs2의 32비트 값. |
| 5 | <code>    input  wire [1:0]  i_funct3,    // inst[13:12]: 00 sb, 01 sh, 10 sw</code> | 명령어 funct3 하위 2비트. SB=00, SH=01, SW=10. |
| 6 | <code>    input  wire [1:0]  i_offset,    // alu result [1:0]</code> | 원래 유효 주소의 하위 2비트로 바이트 위치를 받는다. |
| 7 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 8 | <code>    output reg  [31:0] o_wdata</code> | lane 배치 후 32비트 쓰기 데이터. reg이지만 조합 회로 출력이다. |
| 9 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 10 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 11 | <code>// Move the store data into the byte lane the access targets</code> | store 데이터를 대상 byte lane으로 이동한다는 설명. |
| 12 | <code>// (the same lane that dmem_mask_gen enables). Constant shift amounts only.</code> | mask 생성기가 고른 lane과 맞추며 고정 이동량만 사용한다는 설명. |
| 13 | <code>always @(*) begin</code> | 쓰기 데이터 배치를 조합식으로 계산한다. |
| 14 | <code>    case ({i_funct3, i_offset})</code> | 크기와 offset을 연결한 4비트 선택값으로 분기한다. |
| 15 | <code>        4'b00_00: o_wdata = i_rs2_data;</code> | SB offset=0은 rs2를 그대로 내보낸다. mask=0001이므로 하위 8비트만 실제 저장한다. |
| 16 | <code>        4'b00_01: o_wdata = {i_rs2_data[23:0], 8'b0};</code> | SB offset=1: 하위 8비트를 lane 1로 옮긴다. 표현식은 전체 32비트를 8비트 왼쪽 이동한 것과 같고 mask=0010이다. |
| 17 | <code>        4'b00_10: o_wdata = {i_rs2_data[15:0], 16'b0};</code> | SB offset=2: 16비트 왼쪽 이동해 하위 byte를 lane 2에 배치한다. mask=0100. |
| 18 | <code>        4'b00_11: o_wdata = {i_rs2_data[7:0], 24'b0};</code> | SB offset=3: 하위 byte를 최상위 lane 3에 놓는다. mask=1000. |
| 19 | <code>        4'b01_00,</code> | SH offset=0과 다음 offset=1의 처리 문장을 공유한다. |
| 20 | <code>        4'b01_01: o_wdata = i_rs2_data;</code> | SH offset=0/1에서 원래 rs2를 출력한다. 정상 offset=0에서는 하위 16비트만 저장하며 1은 trap으로 차단한다. |
| 21 | <code>        4'b01_10,</code> | SH offset=2와 다음 offset=3 항목을 묶는다. |
| 22 | <code>        4'b01_11: o_wdata = {i_rs2_data[15:0], 16'b0};</code> | SH offset=2/3에서 하위 16비트를 상위 half로 옮긴다. 정상 offset=2의 mask는 1100이고 3은 trap이다. |
| 23 | <code>        default : o_wdata = i_rs2_data;</code> | SW 및 나머지 입력에서는 rs2를 그대로 출력한다. SW의 정상 offset은 0이며 다른 offset의 접근은 차단된다. |
| 24 | <code>    endcase</code> | case 선택 구문을 닫는다. 앞에서 선택된 한 항목의 대입으로 결과가 결정된다. |
| 25 | <code>end</code> | 가장 가까운 begin으로 연 블록을 닫는다. 여기서는 always 조합 블록의 끝이다. |
| 26 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 27 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |
| 28 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `602e0c44569b85a4e0e4f874563b0bba17777264c5ce457b8ebc1dd1150a746b`
