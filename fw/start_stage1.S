#include "or32_defs.h"
#include "spr_defs.h"

        // variables defined elsewhere
        .extern         __stack
        .extern         __data_start
        .extern         __data_end
        .extern         __data_ram
        .extern         __text_start
        .extern         __rom_size

        // stack space
        .section        .stack, "aw", @nobits
        .space          OR32_STACK_SIZE
_stack:

        // vectors
        .section        .vectors, "ax"

        // this word holds firmware length
        .org    0
        .word   __rom_size

        // reset procedure
        .org    OR32_RESET_VECTOR

        // reset vector
_reset:
real_reset:
        // clear r0
        l.movhi r0, 0x0

        // go into supervisor mode
        l.addi  r3,r0,SPR_SR_SM
        l.mtspr r0,r3,SPR_SR

        // stack initialization
        l.movhi r1,hi(__stack)
        l.ori   r1,r1,lo(__stack)

        // text section
        .section        .text, "ax"

        // bss initialization
        l.movhi r2, hi(__bss_start)
        l.ori   r2,r2,lo(__bss_start)
        l.movhi r3, hi(__bss_end)
        l.ori   r3,r3,lo(__bss_end)
bss_init_start:
        l.sfgeu r2,r3
        l.bf    bss_init_end
        l.nop
        l.sw    0(r2),r0
        l.addi  r2,r2,4
        l.bnf   bss_init_start
        l.nop
bss_init_end:
        // jump to main
        l.movhi r3,hi(main)
        l.ori   r3,r3,lo(main)
        l.jr    r3
        l.nop

// or1200 soft mul & soft div
#define L_mulsi3
//#define L_divsi3
//#define L_modsi3
//#define L_udivsi3
//#define L_umodsi3
//#define HW_DIV

#include "or32.S"
