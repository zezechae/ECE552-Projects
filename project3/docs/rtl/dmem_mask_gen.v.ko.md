# dmem_mask_gen.v — 전체 줄별 해설

[분석 안내로 돌아가기](../README.ko.md) · [원본 파일](../../rtl/dmem_mask_gen.v)

원본 물리적 줄 수: **47줄**. 아래 표는 빈 줄과 주석을 포함한 모든 줄을 다룬다. 여러 줄 표현식의 각 행은 앞뒤 행과 이어서 읽는다.

유효 주소의 하위 2비트로 32비트 데이터 버스 중 어느 바이트를 사용할지 결정한다. mask[0]은 bits 7:0, mask[3]은 bits 31:24에 대응한다. 주소 자체는 hart에서 4바이트 경계로 내린다.

| 크기 | 허용 offset | mask | 정렬 오류 |
|---|---|---|---|
| byte | 0/1/2/3 | 0001/0010/0100/1000 | 없음 |
| half | 0/2 | 0011/1100 | offset 1/3 |
| word | 0 | 1111 | offset 1/2/3 |

misaligned인 경우에도 mask는 만들어지지만 hart가 실제 읽기·쓰기를 차단한다. 비메모리 명령에서도 mask는 0이 아닐 수 있으며 enable과 함께 해석해야 한다.

## 줄별 해설

| 원본 줄 | 원문 | 한국어 설명 및 문법 |
|---:|---|---|
| 1 | <code>&#96;default_nettype none</code> | 선언하지 않은 신호를 암묵적 wire로 만드는 기능을 금지한다. 신호 이름 오타 검출에 유용한 컴파일 지시문이다. |
| 2 | <code>module dmem_mask_gen</code> | 바이트 마스크 생성 모듈 이름을 선언한다. |
| 3 | <code>(</code> | 다음 줄부터 포트 목록을 연다. |
| 4 | <code>    input wire[1:0] i_funct3,</code> | 이름은 funct3이지만 폭은 2비트이다. hart가 inst[13:12]만 넣으므로 00=byte, 01=half, 10=word이다. |
| 5 | <code>    input wire[1:0] i_offset,</code> | 원래 유효 주소의 하위 2비트. word 내부 바이트 위치 0~3이다. |
| 6 | <code>    input wire      i_is_mem, //load or store</code> | 현재 명령이 load/store인지 나타낸다. 정렬 오류 보고에만 사용한다. |
| 7 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 8 | <code>    output reg[3:0] o_mask,   </code> | 4개 바이트의 사용 여부를 담는 조합 출력 변수. |
| 9 | <code>    output wire     o_misaligned</code> | 자연 정렬 조건을 어기는 메모리 접근이면 1인 출력. |
| 10 | <code>);</code> | 현재 포트 선언 또는 인스턴스 연결 목록을 닫고 문장을 끝낸다. |
| 11 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 12 | <code>//For byte o_mask : 0001, 0010, 0100, 1000</code> | byte 접근은 offset에 따라 네 mask 중 하나를 사용한다는 주석. |
| 13 | <code>//For half word   : 0011, 1100</code> | half 접근은 하위 또는 상위 두 byte를 함께 선택한다는 주석. |
| 14 | <code>//For word        : 1111</code> | word 접근은 네 byte 모두를 선택한다는 주석. |
| 15 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 16 | <code>//i_offset</code> | 아래에 byte offset과 크기 인코딩을 설명한다는 주석. |
| 17 | <code>//i_funct3 : 000 =&gt; byte, 001 =&gt; half-word, 010 =&gt; word</code> | 주석에는 원래 3비트 funct3 표기가 있지만 실제 입력은 그 하위 2비트만 받는다. LB/LBU와 LH/LHU는 여기서 같은 크기이다. |
| 18 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 19 | <code>/*o_misaligned:</code> | 여러 줄 주석의 시작. 다음 줄들에서 misaligned 조건을 문장으로 설명한다. |
| 20 | <code>Half is misaligned when offset[0] == 1.</code> | half 접근은 offset의 bit0=1이면 비정렬이라는 설명. |
| 21 | <code>Word is misaligned when offset[1:0] != 2'b00.</code> | word 접근은 offset 00 이외이면 비정렬이라는 설명. |
| 22 | <code>Byte is never misaligned.</code> | byte 접근에는 자연 정렬 오류가 없다는 설명. |
| 23 | <code>The result is valid only when i_is_mem is set, so it stays 0 for non-memory instructions.*/</code> | 정렬 오류는 메모리 명령일 때만 유효하고 그 외에는 0이어야 한다는 설명 및 주석 종료. |
| 24 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 25 | <code>assign o_misaligned = (((i_funct3 == 2'b01) &amp; i_offset[0]) &#124; </code> | half 크기이며 offset[0]=1인 경우를 정렬 오류로 판단한다. 다음 줄의 word 오류 조건과 OR한다. |
| 26 | <code>                      ((i_funct3 == 2'b10) &amp; (i_offset[1:0]!=2'b00))) &amp; i_is_mem;</code> | word 크기에서 offset!=0이면 오류. 최종 AND i_is_mem으로 비메모리 명령의 오검출을 막는다. |
| 27 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 28 | <code>always @(*) begin</code> | 입력 변화에 반응하는 조합 블록. 플립플롭을 만들지 않는다. |
| 29 | <code>    case ({i_funct3, i_offset})</code> | 2비트 크기와 2비트 offset을 연결해 4비트 case 선택값으로 만든다. |
| 30 | <code>        4'b00_00: o_mask = 4'b0001;</code> | byte, offset=0: 가장 낮은 lane 0만 사용한다. |
| 31 | <code>        4'b00_01: o_mask = 4'b0010;</code> | byte, offset=1: lane 1만 사용한다. |
| 32 | <code>        4'b00_10: o_mask = 4'b0100;</code> | byte, offset=2: lane 2만 사용한다. |
| 33 | <code>        4'b00_11: o_mask = 4'b1000;</code> | byte, offset=3: lane 3만 사용한다. |
| 34 | <code>        4'b01_00,</code> | half, offset=0 항목. 쉼표로 다음 항목과 처리 문장을 공유한다. |
| 35 | <code>        4'b01_01: o_mask = 4'b0011;</code> | half, offset=0 또는 1이면 하위 두 lane을 켠다. offset=1은 misaligned로 실제 접근이 막힌다. |
| 36 | <code>        4'b01_10,</code> | half, offset=2 항목으로 다음 줄과 처리 문장을 공유한다. |
| 37 | <code>        4'b01_11: o_mask = 4'b1100;</code> | half, offset=2 또는 3이면 상위 두 lane을 켠다. offset=3은 정렬 오류이다. |
| 38 | <code>        4'b10_00,</code> | word, offset=0을 다음 항목들과 묶는다. |
| 39 | <code>        4'b10_01,</code> | word, offset=1도 같은 mask를 생성하지만 정렬 오류가 별도로 발생한다. |
| 40 | <code>        4'b10_10,</code> | word, offset=2도 같은 mask를 생성하지만 정렬 오류이다. |
| 41 | <code>        4'b10_11: o_mask = 4'b1111;</code> | word의 모든 offset에 mask=1111. 실제 유효한 offset은 0뿐이다. |
| 42 | <code>        default : o_mask = 4'b0000;</code> | 지원하지 않는 크기 또는 미정 선택값은 모든 lane을 끈다. |
| 43 | <code>    endcase</code> | case 선택 구문을 닫는다. 앞에서 선택된 한 항목의 대입으로 결과가 결정된다. |
| 44 | <code>end</code> | 가장 가까운 begin으로 연 블록을 닫는다. 여기서는 always 조합 블록의 끝이다. |
| 45 | <code>(빈 줄)</code> | 가독성을 위해 구간을 나눈 빈 줄. 회로 동작에는 영향이 없다. |
| 46 | <code>endmodule</code> | 현재 모듈 정의를 끝낸다. |
| 47 | <code>&#96;default_nettype wire</code> | 뒤에 처리할 코드의 기본 net 종류를 wire로 되돌리는 컴파일 지시문이다. |

원본 SHA-256: `4247ef4d86d2cf9e70ff6c51cffb1adedfc6dfa2801a47d6475b783d705ccfcd`
