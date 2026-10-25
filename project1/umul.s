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
    addi x5, x0, 0  ## i
    addi x6, x0, 32 ## maximum iteration
    addi x7, x0, 0  ## sum

loop:
    bge x5, x6, end
    andi x28, a1, 1
    beq x28, 1, skip
    add x7, x7, a0

skip:
    slli a0, a0, 1
    srli a1, a1, 1
    addi x5, x5, 1
    jal x0, loop

end:
    addi a0, x7, 0
    jalr x0, 0(ra)
