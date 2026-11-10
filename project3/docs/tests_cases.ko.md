# 공개 어셈블리 테스트의 전체 55개 case


[테스트 해설](testing.ko.md) · [분석 안내](README.ko.md)


아래 표는 원본 .asm에서 추출했다. 기대값은 테스트 작성자가 지정한 값이며, 실제 HDL 실행 결과를 뜻하지 않는다. `gp`는 현재 case 번호를 담고 `bne`는 값이 다르면 fail로 이동한다. label에 붙은 번호가 연속되지 않는 파일도 있다.


입력 설정에는 검사 대상 연산 이전의 li를 표시한다. LUI 테스트의 lui/srai는 연산 열에 함께 표시한다. 원본 줄은 test label의 시작 위치이다.


## 01add.asm — 18개

[원본](../tests/asm/01add.asm)

| case | 원본 줄 | 입력 설정 | 검사 연산 | 기대값 설정 | 실패 시 이동 조건 |
|---|---:|---|---|---|---|
| test_2 / gp=2 | 7 | `li x1, 0x00000000`<br>`li x2, 0x00000000` | `add x30, x1, x2` | `li x29, 0x00000000` | `bne x30, x29, fail` |
| test_3 / gp=3 | 16 | `li x1, 0x00000001`<br>`li x2, 0x00000001` | `add x30, x1, x2` | `li x29, 0x00000002` | `bne x30, x29, fail` |
| test_4 / gp=4 | 25 | `li x1, 0x00000003`<br>`li x2, 0x00000007` | `add x30, x1, x2` | `li x29, 0x0000000a` | `bne x30, x29, fail` |
| test_5 / gp=5 | 35 | `li x1, 0x00000000`<br>`li x2, 0xffff8000` | `add x30, x1, x2` | `li x29, 0xffff8000` | `bne x30, x29, fail` |
| test_6 / gp=6 | 44 | `li x1, 0x80000000`<br>`li x2, 0x00000000` | `add x30, x1, x2` | `li x29, 0x80000000` | `bne x30, x29, fail` |
| test_7 / gp=7 | 53 | `li x1, 0x80000000`<br>`li x2, 0xffff8000` | `add x30, x1, x2` | `li x29, 0x7fff8000` | `bne x30, x29, fail` |
| test_8 / gp=8 | 63 | `li x1, 0x00000000`<br>`li x2, 0x00007fff` | `add x30, x1, x2` | `li x29, 0x00007fff` | `bne x30, x29, fail` |
| test_9 / gp=9 | 72 | `li x1, 0x7fffffff`<br>`li x2, 0x00000000` | `add x30, x1, x2` | `li x29, 0x7fffffff` | `bne x30, x29, fail` |
| test_10 / gp=10 | 81 | `li x1, 0x7fffffff`<br>`li x2, 0x00007fff` | `add x30, x1, x2` | `li x29, 0x80007ffe` | `bne x30, x29, fail` |
| test_11 / gp=11 | 91 | `li x1, 0x80000000`<br>`li x2, 0x00007fff` | `add x30, x1, x2` | `li x29, 0x80007fff` | `bne x30, x29, fail` |
| test_12 / gp=12 | 100 | `li x1, 0x7fffffff`<br>`li x2, 0xffff8000` | `add x30, x1, x2` | `li x29, 0x7fff7fff` | `bne x30, x29, fail` |
| test_13 / gp=13 | 110 | `li x1, 0x00000000`<br>`li x2, 0xffffffff` | `add x30, x1, x2` | `li x29, 0xffffffff` | `bne x30, x29, fail` |
| test_14 / gp=14 | 119 | `li x1, 0xffffffff`<br>`li x2, 0x00000001` | `add x30, x1, x2` | `li x29, 0x00000000` | `bne x30, x29, fail` |
| test_15 / gp=15 | 128 | `li x1, 0xffffffff`<br>`li x2, 0xffffffff` | `add x30, x1, x2` | `li x29, 0xfffffffe` | `bne x30, x29, fail` |
| test_16 / gp=16 | 138 | `li x1, 0x00000001`<br>`li x2, 0x7fffffff` | `add x30, x1, x2` | `li x29, 0x80000000` | `bne x30, x29, fail` |
| test_17 / gp=17 | 152 | `li x1, 13`<br>`li x2, 11` | `add x1, x1, x2` | `li x29, 24` | `bne x1, x29, fail` |
| test_18 / gp=18 | 161 | `li x1, 14`<br>`li x2, 11` | `add x2, x1, x2` | `li x29, 25` | `bne x2, x29, fail` |
| test_19 / gp=19 | 170 | `li x1, 13` | `add x1, x1, x1` | `li x29, 26` | `bne x1, x29, fail` |

## 02addi.asm — 18개

[원본](../tests/asm/02addi.asm)

| case | 원본 줄 | 입력 설정 | 검사 연산 | 기대값 설정 | 실패 시 이동 조건 |
|---|---:|---|---|---|---|
| test_2 / gp=2 | 7 | `li x1, 0x00000000` | `addi x30, x1, 0x000` | `li x29, 0x00000000` | `bne x30, x29, fail` |
| test_3 / gp=3 | 14 | `li x1, 0x00000001` | `addi x30, x1, 0x001` | `li x29, 0x00000002` | `bne x30, x29, fail` |
| test_4 / gp=4 | 21 | `li x1, 0x00000003` | `addi x30, x1, 0x007` | `li x29, 0x0000000a` | `bne x30, x29, fail` |
| test_5 / gp=5 | 28 | `li x1, 0x00000000` | `addi x30, x1, 0xfffff800` | `li x29, 0xfffff800` | `bne x30, x29, fail` |
| test_6 / gp=6 | 35 | `li x1, 0x80000000` | `addi x30, x1, 0x000` | `li x29, 0x80000000` | `bne x30, x29, fail` |
| test_7 / gp=7 | 42 | `li x1, 0x80000000` | `addi x30, x1, 0xfffff800` | `li x29, 0x7ffff800` | `bne x30, x29, fail` |
| test_8 / gp=8 | 49 | `li x1, 0x00000000` | `addi x30, x1, 0x7ff` | `li x29, 0x000007ff` | `bne x30, x29, fail` |
| test_9 / gp=9 | 56 | `li x1, 0x7fffffff` | `addi x30, x1, 0x000` | `li x29, 0x7fffffff` | `bne x30, x29, fail` |
| test_10 / gp=10 | 63 | `li x1, 0x7fffffff` | `addi x30, x1, 0x7ff` | `li x29, 0x800007fe` | `bne x30, x29, fail` |
| test_11 / gp=11 | 70 | `li x1, 0x80000000` | `addi x30, x1, 0x7ff` | `li x29, 0x800007ff` | `bne x30, x29, fail` |
| test_12 / gp=12 | 77 | `li x1, 0x7fffffff` | `addi x30, x1, 0xfffff800` | `li x29, 0x7ffff7ff` | `bne x30, x29, fail` |
| test_13 / gp=13 | 84 | `li x1, 0x00000000` | `addi x30, x1, 0xffffffff` | `li x29, 0xffffffff` | `bne x30, x29, fail` |
| test_14 / gp=14 | 91 | `li x1, 0xffffffff` | `addi x30, x1, 0x001` | `li x29, 0x00000000` | `bne x30, x29, fail` |
| test_15 / gp=15 | 98 | `li x1, 0xffffffff` | `addi x30, x1, 0xffffffff` | `li x29, 0xfffffffe` | `bne x30, x29, fail` |
| test_16 / gp=16 | 105 | `li x1, 0x7fffffff` | `addi x30, x1, 0x001` | `li x29, 0x80000000` | `bne x30, x29, fail` |
| test_17 / gp=17 | 115 | `li x1, 13` | `addi x1, x1, 11` | `li x29, 24` | `bne x1, x29, fail` |
| test_24 / gp=24 | 122 | 없음 | `addi x1, x0, 32` | `li x29, 32` | `bne x1, x29, fail` |
| test_25 / gp=25 | 128 | `li x1, 33` | `addi x0, x1, 50` | `li x29, 0` | `bne x0, x29, fail` |

## 03and.asm — 7개

[원본](../tests/asm/03and.asm)

| case | 원본 줄 | 입력 설정 | 검사 연산 | 기대값 설정 | 실패 시 이동 조건 |
|---|---:|---|---|---|---|
| test_2 / gp=2 | 7 | `li x1, 0xff00ff00`<br>`li x2, 0x0f0f0f0f` | `and x30, x1, x2` | `li x29, 0x0f000f00` | `bne x30, x29, fail` |
| test_3 / gp=3 | 16 | `li x1, 0x0ff00ff0`<br>`li x2, 0xf0f0f0f0` | `and x30, x1, x2` | `li x29, 0x00f000f0` | `bne x30, x29, fail` |
| test_4 / gp=4 | 25 | `li x1, 0x00ff00ff`<br>`li x2, 0x0f0f0f0f` | `and x30, x1, x2` | `li x29, 0x000f000f` | `bne x30, x29, fail` |
| test_5 / gp=5 | 34 | `li x1, 0xf00ff00f`<br>`li x2, 0xf0f0f0f0` | `and x30, x1, x2` | `li x29, 0xf000f000` | `bne x30, x29, fail` |
| test_6 / gp=6 | 48 | `li x1, 0xff00ff00`<br>`li x2, 0x0f0f0f0f` | `and x1, x1, x2` | `li x29, 0x0f000f00` | `bne x1, x29, fail` |
| test_7 / gp=7 | 57 | `li x1, 0x0ff00ff0`<br>`li x2, 0xf0f0f0f0` | `and x2, x1, x2` | `li x29, 0x00f000f0` | `bne x2, x29, fail` |
| test_8 / gp=8 | 66 | `li x1, 0xff00ff00` | `and x1, x1, x1` | `li x29, 0xff00ff00` | `bne x1, x29, fail` |

## 04andi.asm — 7개

[원본](../tests/asm/04andi.asm)

| case | 원본 줄 | 입력 설정 | 검사 연산 | 기대값 설정 | 실패 시 이동 조건 |
|---|---:|---|---|---|---|
| test_2 / gp=2 | 7 | `li x1, 0xff00ff00` | `andi x30, x1, 0xffffff0f` | `li x29, 0xff00ff00` | `bne x30, x29, fail` |
| test_3 / gp=3 | 15 | `li x1, 0x0ff00ff0` | `andi x30, x1, 0x0f0` | `li x29, 0x000000f0` | `bne x30, x29, fail` |
| test_4 / gp=4 | 23 | `li x1, 0x00ff00ff` | `andi x30, x1, 0x70f` | `li x29, 0x0000000f` | `bne x30, x29, fail` |
| test_5 / gp=5 | 31 | `li x1, 0xf00ff00f` | `andi x30, x1, 0x0f0` | `li x29, 0x00000000` | `bne x30, x29, fail` |
| test_6 / gp=6 | 44 | `li x1, 0xff00ff00` | `andi x1, x1, 0x0f0` | `li x29, 0x00000000` | `bne x1, x29, fail` |
| test_13 / gp=13 | 51 | 없음 | `andi x1, x0, 0x0f0` | `li x29, 0` | `bne x1, x29, fail` |
| test_14 / gp=14 | 58 | `li x1, 0x00ff00ff` | `andi x0, x1, 0x70f` | `li x29, 0` | `bne x0, x29, fail` |

## 05lui.asm — 5개

[원본](../tests/asm/05lui.asm)

| case | 원본 줄 | 입력 설정 | 검사 연산 | 기대값 설정 | 실패 시 이동 조건 |
|---|---:|---|---|---|---|
| test_2 / gp=2 | 7 | 없음 | `lui x1, 0x00000` | `li x29, 0x00000000` | `bne x1, x29, fail` |
| test_3 / gp=3 | 14 | 없음 | `lui x1, 0xfffff`<br>`srai x1,x1,1` | `li x29, 0xfffff800` | `bne x1, x29, fail` |
| test_4 / gp=4 | 22 | 없음 | `lui x1, 0x7ffff`<br>`srai x1,x1,20` | `li x29, 0x000007ff` | `bne x1, x29, fail` |
| test_5 / gp=5 | 30 | 없음 | `lui x1, 0x80000`<br>`srai x1,x1,20` | `li x29, 0xfffff800` | `bne x1, x29, fail` |
| test_6 / gp=6 | 39 | 없음 | `lui x0, 0x80000` | `li x29, 0` | `bne x0, x29, fail` |

