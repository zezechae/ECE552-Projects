# Project 3 한국어 분석 안내

이 문서는 현재 프로젝트의 실제 소스를 기준으로 작성한 학습용 해설이다. RTL과 테스트 원본은 수정하지 않았다. `test`라는 폴더는 없으며 실제 이름은 `tests`이다.

## 읽는 순서

1. [전체 구조와 Verilog 문법](architecture.ko.md): 단일 사이클 CPU의 동작, 신호 흐름, 문법, 명령어 실행 예제.
2. [hart.v 전체 줄별 해설](rtl/hart.v.ko.md): 하위 모듈을 연결하는 최상위 CPU.
3. [control_unit.v](rtl/control_unit.v.ko.md), [imm.v](rtl/imm.v.ko.md), [rf.v](rtl/rf.v.ko.md): 명령어 해석, 즉시값, 레지스터.
4. [alu_control.v](rtl/alu_control.v.ko.md), [alu.v](rtl/alu.v.ko.md): 연산 제어와 실제 연산.
5. [fetch.v](rtl/fetch.v.ko.md): PC와 분기·점프.
6. [dmem_mask_gen.v](rtl/dmem_mask_gen.v.ko.md), [store_align.v](rtl/store_align.v.ko.md), [load_format.v](rtl/load_format.v.ko.md): 바이트 단위 메모리 접근.
7. [tb와 tests 분석](testing.ko.md): 시뮬레이션 환경, 테스트별 검증 항목, Makefile, 실행 방법과 한계.
8. [구현상 주의점과 검증 범위](review.ko.md): 실제 코드와 주석의 차이, 잠재 문제, 확인한 범위.

## 줄별 해설의 기준

RTL 10개 파일의 **물리적 805줄 전부**를 원래 줄 번호와 함께 다룬다. 빈 줄·주석·괄호도 생략하지 않는다. 각 파일은 먼저 역할과 핵심 동작을 설명하고, 다음 표에서 `줄 번호 / 원문 / 설명`을 일대일로 대응시킨다. 이어진 표현식도 각 줄이 담당하는 부분을 구분한다.

`reg`라는 선언만으로 플립플롭이라고 판단하지 말자. 이 프로젝트에서 `always @(*)`에 대입되는 `reg`는 조합 회로 결과이고, `always @(posedge ...)`에서 갱신되는 PC와 레지스터 배열은 상태를 저장한다.

분석은 정적 소스 검토에 기반한다. 실제 HDL 시뮬레이션 실행 여부와 문서의 줄 대응 검증 결과는 [검증 범위](review.ko.md)에 구분해서 기록한다.
