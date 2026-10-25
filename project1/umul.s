## Author: Jewoo Chae
##
## You may implement the following with any of the instructions in the RV32I instruction set
## and described in the reference sheet. Do not use any of the mul[h][s][u] instructions which
## are *not* described in the reference sheet. Remember to respect the calling convention - if
## you choose to use any of the callee saved registers s[0-11], remember to save them to the
## stack before reusing them (note, you should not need to do this but are free to do so).
##
## [Description]
## Multiplies two 32-bit *unsigned* numbers and provides a 32-bit *unsigned* result
## consisting of the lower 32 bits of the product.
##
## [Arguments]
## a0 = multiplicand
## a1 = multiplier
##
## [Returns]
## a0 = 32-bit product
    .text
    .globl umul
umul:
    addi x5, x0, 0
    addi x6, x0, 32

loop:
    bge x5, x6, end
    andi x7, a1, 1
    srli a1, a1, 1
    bne x7, 1, loop
    sll a0, a0, x5+1
    add a0, a0, a0
    addi x5, x5, 1

end:
