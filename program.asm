STACKPTR equ 0x1FF

IRQ_SAVE_WREG equ 0x0005
IRQ_SAVE_ZC   equ 0x0006
IRQ_SAVE_INDA equ 0x0007

IRQ_TEMP0 equ 0x0008
IRQ_TEMP1 equ 0x0009

WREG equ 0x200  // W Register
CARRY equ 0x201  // Carry Register
ZERO equ 0x202  // Zero Register
INDV equ 0x203  // Indirect Value Register
INDA equ 0x204  // Indirect Pointer Register

W equ 0
w equ 0
M equ 1
m equ 1

TMR0_CTL_PRE_MASK equ 0xff00
TMR0_CTL_PRE_OFFSET equ 8
TMR0_CTL_IRQEN_OFFSET equ 2
TMR0_CTL_RELOAD_OFFSET equ 1
TMR0_CTL_RUN_OFFSET equ 0

SW equ 0x300
SW_dir equ 0x301
SW_irq_en equ 0x302
SW_irq equ 0x303

LEDR equ 0x304
LEDR_dir equ 0x305
LEDR_irq_en equ 0x306
LEDR_irq equ 0x307

TIMER_0_count equ 0x308
TIMER_0_period equ 0x308
TIMER_0_control equ 0x308
TIMER_0_status equ 0x308

ORG 0x0000
RESET: gol STARTUP

ORG 0x0004
INTERRUPT_VECTOR: gol __IRQ

// I could have put the IRQ function here, but didn't want to renumber everthing in program.mem

ORG 0x0005
STARTUP:
// initialize stack
    mlw (STACKPTR - 1)  // 0x1FE is top of stack
    mwm STACKPTR
//int i = 0;
    i equ 0x0000
    mlw .0
    mwm i

//int j = 20;
    j equ 0x0001
    mlw .20
    mwm j

//int k = 0;
    k equ 0x0002
    mlw .0
    mwm k

//int l[10];
    l equ 0x0003
    l_end equ (l + 10 - 1) // l_end = 0x000C
    gol MAIN

//uint16_t sw_prescale;
    sw_prescale equ 0x0004
    mlw 0
    mwm sw_prescale



//void main(void) {
ORG 0x0010
MAIN:
//  for (i = 0; i < 10; i++) {
//    l[i] = add(&j, i);
//  }
    MAIN_TEMP_0 equ 0x000D
    MAIN_TEMP_1 equ 0x000E
    mm STACKPTR,w // get top of stack
    mwm MAIN_TEMP_0 // save original stack position
    mwm INDA  // point the Indirect access at the stack
    mlw MAIN_ADD_RETURN // return address
    mwm INDV
    mlw .1
    sub INDA,M // next stack address
    // load args right to left
    mm i,w
    mwm INDV
    mlw .1
    sub INDA,M // next stack address
    mlw j // &j
    mwm INDV
    mm INDA,w
    mwm STACKPTR
    gol ADD

MAIN_ADD_RETURN:
    mm STACKPTR,w
    mwm INDA
    mm INDV,w  // load return value
    mwm MAIN_TEMP_1  // save return value
    mm MAIN_TEMP_0,w // load previous STACKPTR value
    mwm STACKPTR  // "pop" function args off stack
    mlw l
    mwm INDA
    mm i,w
    add INDA,m
    mm MAIN_TEMP_1,w
    mwm INDV

    // i < 10 ?
    mlw .1
    add i,m
    mlw .10
    sub i,w
    sms CARRY  // skip if carry set
    gol MAIN  // i < 10

    // out of for loop
//  i = i - j;
    mm j,w
    sub i,m

//  if (i >= 10) {
//    j = 0xaa;
//  } else {
//    j = 0x55;
//  }
    mlw .10
    mwm MAIN_TEMP_1
    rlm i,w
    smc CARRY // If carry set, number is negative
    // borrow check doesn't work with mixed signs. Since
    // 10 is a positive literal the "compiler" knows that if i is negative,
    // i < 10
    gol MAIN_I_SIGN_NEG
    
    mm i,w
    sub MAIN_TEMP_1,w
    mlw 0x55  // assume not
    sms CARRY
    mlw 0xaa  // i > 10
    smc ZERO
    mlw 0xaa // i == 10
    gol MAIN_I_SIGN_END

// If i is negative, it's obviously less than 10
MAIN_I_SIGN_NEG:
    mlw 0x55

MAIN_I_SIGN_END:
    mwm j

//  k = 0x55a9;
    mlw (0x55a9 >> 5) // staying under sign ext.
    add k,m  // could use mwm, but we know the memory is zeroed, and this assures that carry is cleared in one op
    rlm k,m // 1
    rlm k,m // 2
    rlm k,m // 3
    rlm k,m // 4
    rlm k,m // 5
    mlw 0x9
    add k,m

//  while ((j & k) != 0) {
//    k++;
//  }
    mm k,w
    awm j,w
    smc ZERO
    gol MAIN_WHILE_LOOP_END // (j & k) == 0
MAIN_WHILE_LOOP:
    mlw .1
    add k,m
    mm k,w
    awm j,w
    sms ZERO
    gol MAIN_WHILE_LOOP

MAIN_WHILE_LOOP_END:
//  i = (j | k) == -1;
    mm k,w
    owm j,w
    mwm MAIN_TEMP_1
    mlw .-1
    sub MAIN_TEMP_1,w
    mm ZERO,w  // if temp == -1, zero = 1, else 0
    mwm i;

//  i = j > k;
    mm j,w
    sub k,w  // CARRY clear if Wreg > Mem
    mlw 1  // assume true
    smc CARRY
    mlw 0
    mwm i

//  i = j <= k;
    mm j,w
    sub k,w  // CARRY set if Wreg <= Mem
    mm CARRY,w
    mwm i


//  // Prep the Blinkenlitez
//  *SW_dir = 0x0000;      // All inputs
//  *SW_irq_en = 0x0000;   // No interrutps (for now)
//  *LEDR_irq_en = 0x0000; // no interrupts
//  *LEDR_dir = 0xFFFF;    // All outputs
//  *TIMER_0_period = 0xFFFF;
//

    mlw 0
    mwm SW_dir
    mwm SW_irq_en
    mwm LEDR_irq_en
    mlw -1  // sign extend 0x7FF -> 0xFFFF
    mwm LEDR_dir
    mwm TIMER_0_period

//  // Show off what we've got
//  // This sets the LEDR to the state of its SW
//  // set all SW high to exit first demo
//  while (*SW != 0xFFFF) {

    sub SW,w
    smc ZERO  // Skip if Zero is clear (SW != 0xFFFF)
    gol MAIN_SW_LOOP_END

//    *LEDR = *SW;
//  }

MAIN_SW_LOOP:
    mm SW,w
    mwm LEDR

//  while (*SW != 0xFFFF) {

    mlw -1
    sub SW,w
    sms ZERO  // Skip if Zero is set (SW == 0xFFFF)
    gol MAIN_SW_LOOP

MAIN_SW_LOOP_END:

//  // Prep counting blinkenlitez
//  *SW_irq_en = 0xFFFF; // Interupt on change
//  *TIMER_0_period = 0xFFFF;

    mlw -1
    mwm SW_irq_en
    mwm TIMER_0_period

//  *TIMER_0_control = (0xff << TMR0_CTL_PRE_OFFSET) |
//                     (1 << TMR0_CTL_IRQEN_OFFSET) |
//                     (1 << TMR0_CTL_IRQEN_OFFSET) | (1 << TMR0_CTL_RUN_OFFSET);

// optimized => *TIMER_0_control = 0xFF03
    
    mlw -249  // = 703 -> sign ext -> 0xFF03
    mwm TIMER_0_control

//  // Show counting blinkenlitez, see __irq
//  while (1) {
//  }

MAIN_FOREVER_LOOP:
    gol MAIN_FOREVER_LOOP

//}

END_OF_PROGRAM:
    wfi // effectively a halt if there's no interrupt
        // and/or the interrupt handler just does rfi

ADD:
// return addr = *(STACKPTR + 2)
// by_ref = *(STACKPTR)
// by_val = *(STACKPTR + 1)
// return value = *(STACKPTR - 1)

//  int add(int *by_ref, int by_val) {
    ADD_TEMP_0 equ 0x000F

    mm STACKPTR,w
    mwm INDA
    mlw .1
    add INDA,m  // by_val
    mm INDV,w
    mwm ADD_TEMP_0 // by_val
    mm STACKPTR, w
    mwm INDA,m  // by_ref
    mm INDV,w  // by_ref pointer value loaded in W
    mwm INDA  // by_ref pointer value loaded into indirect
    mm ADD_TEMP_0,w  // by_val
//    *by_ref = *by_ref + by_val;
    add INDV,m

//    return by_val;
//  }
    mm STACKPTR,w
    mwm INDA,m
    mlw .1
    sub INDA,m  // return value
    mm ADD_TEMP_0,w
    mwm INDV
    mm INDA,w
    mwm STACKPTR // update STACKPTR
    mlw .3
    add INDA,m  // return adress
    mm INDV,w
    gow  // return

__IRQ:
// void __attribute__((interrupt)) __irq(void) {

// SAVE STATE
    mwm IRQ_SAVE_WREG  // save WREG, ZERO/CARRY unaffected
    mm ZERO,w  // ZERO set to value of ZERO, unaffected
    mwm IRQ_SAVE_ZC
    rlm IRQ_SAVE_ZC,m  // Rotate carry bit in

//   // on timer interrupt decrement software prescaler, on zero update the
//   // count and increment the display
//   if (*TIMER_0_status != 0) {
//     *TIMER_0_status = 0; // clear interrupt

    sms TIMER_0_status  // goto __IRQ_SW if TIMER_0_status == 0
    gol __IRQ_SW

//     sw_prescale--;

    mlw 1
    sub sw_prescale,m

//     if (sw_prescale == 0) {

    smc sw_prescale  // goto __IRQ_SW if sw_prescale != 0
    gol __IRQ_SW

//       sw_prescale = (*SW >> 8) & 0xff;

    mm SW,w
    mwm sw_prescale
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m  // everything rotated in is in upper 8 bits
    mlw 0xff
    awm sw_prescale,m  // which gets masked out, so don't need to clear carry
                       // for logical shift 

//       *LEDR++;

    mlw 1
    add LEDR,m

//     }
//   }

__IRQ_SW:
//   if (*SW_irq != 0) {

    smc SW_irq  // goto __IRQ_RESTORE if SW_irq == 0
    gol __IRQ_RESTORE

//     *SW_irq = 0; // Clear all, doesn't matter how many changed, we'll update the
//                  // whole port

    mlw 0
    mwm SW_irq

//     // Software prescale gets upper 8 bits
//     sw_prescale = (*SW >> 8) & 0xff;

    mm SW,w
    mwm sw_prescale
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m
    rrm sw_prescale,m  // everything rotated in is in upper 8 bits
    mlw 0xff
    awm sw_prescale,m  // which gets masked out, so don't need to clear carry
                       // for logical shift 

//     // Timer periph prescale gets lower 8 bits
//     *TIMER_0_control =
//         (*TIMER_0_control & (~TMR0_CTL_PRE_MASK)) | ((*SW & 0xff) << 8);
//   }
// optimized => IRQ_TEMP0 = TIMER_0_control & 0xff
// optimized => IRQ_TEMP1 = ((*SW & 0xff) << 8) => (*SW << 8) & 0xff00
// optimized => TIMER_0_control = IRQ_TEMP0 | IRQ_TEMP1
    mm TIMER_0_control,w
    mwm IRQ_TEMP0
    mlw 0x0ff
    awm IRQ_TEMP0,m

    mm SW,w
    mwm IRQ_TEMP1
    rlm IRQ_TEMP1,m
    rlm IRQ_TEMP1,m
    rlm IRQ_TEMP1,m
    rlm IRQ_TEMP1,m
    rlm IRQ_TEMP1,m
    rlm IRQ_TEMP1,m
    rlm IRQ_TEMP1,m
    rlm IRQ_TEMP1,m  // lower bits that are rotated in get masked
    mlw -256  // 0xff00 => 0x700, sign ext => -256
    awm IRQ_TEMP1,w

    owm IRQ_TEMP0,w
    mwm TIMER_0_control

// }

__IRQ_RESTORE:
// RESTORE STATE and Return from interrupt
    mm IRQ_SAVE_INDA,w
    mwm INDA  // Restore INDA
    rrm IRQ_SAVE_ZC,m  // rotate carry back to its position
    mm IRQ_SAVE_WREG,w  // restore WREG
    mm IRQ_SAVE_ZC,m  // restore ZERO
    rfi
