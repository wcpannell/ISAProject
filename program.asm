STACKPTR equ 0x1FF

WREG equ 0x200  // W Register
CARRY equ 0x201  // Carry Register
ZERO equ 0x202  // Zero Register
INDV equ 0x203  // Indirect Value Register
INDA equ 0x204  // Indirect Pointer Register

W equ 0
w equ 0
M equ 1
m equ 1

ORG 0x0000
RESET: gol STARTUP

ORG 0x0004
INTERRUPT_VECTOR: rfi  // Interrupts not used

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

END_OF_PROGRAM:
	wfi // effectively a halt if there's no interrupt
		// and/or the interrupt handler just does rfi

ADD:
// return addr = *(STACKPTR + 2)
// by_ref = *(STACKPTR)
// by_val = *(STACKPTR + 1)
// return value = *(STACKPTR - 1)

//	int add(int *by_ref, int by_val) {
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
//	  *by_ref = *by_ref + by_val;
	add INDV,m

//	  return by_val;
//	}
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
