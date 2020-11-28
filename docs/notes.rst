===========
ISA Project
===========

Goals
=====

* Minimal cpi low cost RISC
 * 16 bit words.
 * max 16 instructions.
 * linear address 2^10 memory bytes, word addressable (2^9 words?)
   - 1 for mem/reg address (if applicable)
   - 1 for w/m (if applicable)
   - 4 for opcode 16 possible ops)
 * "Compile" C operations to asm, machine code:
   - add, subtract, and, or
   - assignment
   - control flow (if-else, while, for, w/ operators ==, !=, >, <=, <, >=)
   - 2's complement signed 16bit int (int a;)
   - 1D array of signed int (int a[10];)

Instructions
============

Instruction Word decoding
-------------------------

Each instruction consists of a 5 bit opcode and an 11 bit literal value.

+--------+---------+
| Opcode | Literal |
+--------+---------+
| 15:11  | 10:0    |
+--------+---------+

The Opcode is further broken down into

+------------+------------+
| Instr_code | Dest (W/M) |
+------------+------------+
| 15:12      | 11         |
+------------+------------+

Instruction Listing
-------------------

+------------+----------+---------------------------------------------+---------------------+------------+
| Instr_code | Mnemonic | Description                                 | Affects Status Regs | Ex         |
+------------+----------+---------------------------------------------+---------------------+------------+
| 0          | mm       | move mem/reg to w or self                   | Zero                | mm 0x21,w  |
|            |          | moving into self can be used to check       |                     | mm 0x22,m  |
|            |          | for Zero value of mem/reg                   |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| 1          | mwm      | move w into mem/reg                         |                     | mwm 0x21   |
+------------+----------+---------------------------------------------+---------------------+------------+
| 2          | mlw      | move 11bit sign extended literal into       |                     |            |
|            |          | W register                                  |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| 3          | rlm      | rotate mem/reg left (through carry)         | Carry               | slm 0x20,w |
|            |          | store result in w or mem/reg                |                     | slm 0x21,m |
+------------+----------+---------------------------------------------+---------------------+------------+
| 4          | rrm      | rotate mem/reg right (through carry)        | Carry               | srm 0x20,w |
|            |          | store result in w or mem/reg                |                     | srm 0x21,m |
+------------+----------+---------------------------------------------+---------------------+------------+
| 5          | awm      | bitwise AND w with mem/reg                  | Zero                | awm 0x21,m |
|            |          | store result in w or mem/reg                |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| 6          | owm      | bitwise OR w with mem/reg                   | Zero                | owm 0x21,m |
|            |          | store result in w or mem/reg                |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| 7          | xwm      | bitwise XOR w with mem/reg                  | Zero                | xwm 0x21,m |
|            |          | store result in w or mem/reg                |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| 8          | add      | add w with mem/reg                          | Carry, Zero         | add 0x20,w |
|            |          | store result in w or mem/reg                |                     | add 0x21,m |
+------------+----------+---------------------------------------------+---------------------+------------+
| 9          | sub      | subtract w from mem/reg (mem/reg - w)       | Carry, Zero         | sub 0x20,w |
|            |          | store result in w or mem/reg                |                     | sub 0x21,m |
+------------+----------+---------------------------------------------+---------------------+------------+
| A          | sms      | skip next instruction if value at mem/reg   |                     |            |
|            |          | address is nonzero                          |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| B          | smc      | skip next instruction if value at mem/reg   |                     |            |
|            |          | address is zero                             |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| C          | gol      | goto literal instruction mem address        |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| D          | gow      | goto instruction mem address held in w      |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| E          | wfi      | Halt Program execution until next interrupt |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+
| F          | rfi      | return from interrupt (restores PC to       |                     |            |
|            |          | previous value + 2)                         |                     |            |
+------------+----------+---------------------------------------------+---------------------+------------+

Instruction Decode Outputs
--------------------------

The Instruction Decode module.

The decode module determines the control register outputs based on the Opcode portion of the instruction.
Both the Instruction code and the Destination bit portions of the Op code are used in this determination.
The table below enumerates the Instruction Decode module's outputs. Values marked with 'x' indicate that the input value is ignored, the default value produced by the assembler is indicated in parenthesis.

+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| Instr_code | Mnemonic | Dest  | W_Mux[1:0] | Mem_Write | PC_Mux[1:0] | PC_Save | Int_Mux | ALU_Op[3:0] |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 0          | mm       | 0 (W) | W_MEM      | 0         | PC_ADD      | 0       | 0       | ZeroTest    |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 0          | mm       | 1 (M) | W_WREG     | 1         | PC_ADD      | 0       | 0       | ZeroTest    |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 1          | mwm      | x (0) | W_WREG     | 1         | PC_ADD      | 0       | 0       | Nop         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 2          | mlw      | x (0) | W_LIT      | 0         | PC_ADD      | 0       | 0       | Nop         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 3          | rlm      | 0     | W_ALU      | 0         | PC_ADD      | 0       | 0       | RotL        |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 3          | rlm      | 1     | W_WREG     | 1         | PC_ADD      | 0       | 0       | RotL        |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 4          | rrm      | 0     | W_ALU      | 0         | PC_ADD      | 0       | 0       | RotR        |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 4          | rrm      | 1     | W_WREG     | 1         | PC_ADD      | 0       | 0       | RotR        |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 5          | awm      | 0     | W_ALU      | 0         | PC_ADD      | 0       | 0       | And         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 5          | awm      | 1     | W_WREG     | 1         | PC_ADD      | 0       | 0       | And         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 6          | owm      | 0     | W_ALU      | 0         | PC_ADD      | 0       | 0       | Or          |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 6          | owm      | 1     | W_WREG     | 1         | PC_ADD      | 0       | 0       | Or          |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 7          | xwm      | 0     | W_ALU      | 0         | PC_ADD      | 0       | 0       | Xor         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 7          | xwm      | 1     | W_WREG     | 1         | PC_ADD      | 0       | 0       | Xor         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 8          | add      | 0     | W_ALU      | 0         | PC_ADD      | 0       | 0       | Add         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 8          | add      | 1     | W_WREG     | 1         | PC_ADD      | 0       | 0       | Add         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 9          | sub      | 0     | W_ALU      | 0         | PC_ADD      | 0       | 0       | Sub         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| 9          | sub      | 1     | W_WREG     | 1         | PC_ADD      | 0       | 0       | Sub         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| A          | sms      | x (0) | W_WREG     | 0         | PC_ADD      | 0       | 0       | PCZero      |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| B          | smc      | x (0) | W_WREG     | 0         | PC_ADD      | 0       | 0       | PCZerobar   |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| C          | gol      | x (0) | W_WREG     | 0         | PC_LIT      | 0       | 0       | Nop         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| D          | gow      | x (0) | W_WREG     | 0         | PC_WREG     | 0       | 0       | Nop         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| E          | wfi      | x (0) | W_WREG     | 0         | PC_SAVE     | 1       | 0       | Nop         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+
| F          | rfi      | x (0) | W_WREG     | 0         | PC_SAVE     | 0       | 0       | Nop         |
+------------+----------+-------+------------+-----------+-------------+---------+---------+-------------+

The enumeration for the ALU_Op values can be found in the ALU section below. The Enumerations for W_Mux and PC_Mux are as follows:

+--------+-------+--+---------+-------+
| W_Mux  | value |  | PC_Mux  | value |
+--------+-------+--+---------+-------+
| W_ALU  | 0     |  | PC_ADD  | 0     |
+--------+-------+--+---------+-------+
| W_MEM  | 1     |  | PC_WREG | 1     |
+--------+-------+--+---------+-------+
| W_LIT  | 2     |  | PC_LIT  | 2     |
+--------+-------+--+---------+-------+
| W_WREG | 3     |  | PC_SAVE | 3     |
+--------+-------+--+---------+-------+

The ALU
=======

The ALU accepts 6 inputs:
 * 1 8bit operation control input
 * 2 one bit status registers (Carry, Zero)

The ALU produces 4 outputs:
 * 1 control signal (Skip_Mux)
 * 2 one bit status registers (Carry, Zero)
 * 1 16bit result output

The carry and zero bits are status registers. These status bits can be used by both the ALU and by users (they are mapped in data memory) to make decisions about the state of arithmatic. For example, if performing 32bit addition in software, the carry bit will be monitored by the program to determine when the lower byte has overflowed, necessitating an increment of the high bytes. The carry bit is also used as an inverted borrow bit for subtraction, allowing the program to determine that an operation underflowed in order to compare magnitude of the two values (<, >). Likewise, a set Zero bit after subtraction indicates equality of the values.

ALU Instructions
----------------

Status bits pass through unless listed in the affects Status box

+--------+-----------+----------------------------------------+-----------+---------+---------+
| Opcode | Operation | Description                            | UsedBy    | Affects | PC_Skip |
|        |           |                                        |           | Status  |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x0    | RotL      | Shift Mem 1 bit left, bit shifted out  | slm       | Carry   | 0       |
|        |           | goes to Carry_in, Carry_out is shifted |           |         |         |
|        |           | into the LSB of the result, W Unused.  |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x1    | RotR      | Shift Mem 1 bit right, bit shifted out | srm       | Carry   | 0       |
|        |           | goes to Carry_in, Carry_out is shifted |           |         |         |
|        |           | into the MSB of the result, W Unused.  |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x2    | Add       | Adds W to Mem, Carry value is value of | add       | Carry,  | 0       |
|        |           | 17th bit of result (stripped to 16 bit |           | Zero    |         |
|        |           | output), Zero set if result is 0.      |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x3    | Sub       | Subtracts W from Mem (Mem - W),        | sub       | Carry,  | 0       |
|        |           | Carry cleared if result is negative,   |           | Zero    |         |
|        |           | Zero set if result is 0.               |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x4    | And       | Bitwise AND W and Mem, zero set if     | awm       | Zero    | 0       |
|        |           | result is 0                            |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x5    | Or        | Bitwise inclusive OR W and Mem, zero   | owm       | Zero    | 0       |
|        |           | set if result is 0                     |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x6    | Xor       | Bitwise exclusive OR W and Mem, zero   | xwm       | Zero    | 0       |
|        |           | set if result is 0                     |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x7    | ZeroTest  | Passes Mem to result, Zero set if Mem  | mm        | Zero    |         |
|        |           | is 0                                   |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x8    | PCZero    | Sets PC_Skip if Mem is nonzero,        | sms       |         | ?       |
|        |           | else clear                             |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0x9    | PCZerobar | Sets PC_Skip if Mem is zero,           | zmc       |         | ?       |
|        |           | else clear                             |           |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+
| 0xA-F  | Nop       | Passes W to result, No other operation | mwm, mlw, |         | 0       |
|        |           |                                        | gol, gow, |         |         |
|        |           |                                        | wfi, rfi  |         |         |
+--------+-----------+----------------------------------------+-----------+---------+---------+

Memory and Registers
--------------------

All Data Memory, Program Memory and registers are word addressable only. For example 0x0000 and 0x0001 are two different 16bit words, as opposed to two bytes comprising a 16 bit word.

 * Wreg:
   - Working Register
   - Memory mapped to 0x0200
 * Carry:
   - Memory mapped to 0x0201
   - Least significant bit is set high on addition overflow, set low otherwise.
   - Also functions as inverted Borrow register. Carry set low on subtraction underflow.
   - All other bits are read as 0
   - Writes to the 15 most significant bits are ignored
 * Zero:
   - Memory mapped to 0x0202
   - Least significant bit is set high when operation produces a zero, set low otherwise.
   - All other bits are read as 0
   - Writes to the 15 most significant bits are ignored
 * Indv:
   - Indirect Value Register
   - Memory mapped to 0x0203
   - Holds value of memory location pointed to by Inda
 * Inda:
   - Indirect Address.
   - Memory mapped to 0x0204
   - Address pointer for Indv

Calling Convention
 * There is no enforced calling convention.
 * For writing assembly, If the function is called from more than one place it is recommended to use the W register to pass the return address (PC + 2) (callee saved if the W register is needed). However, it is just as valid to implement a call stack and use W to pass the first parameter. If memory use allows, further parameters can be passed using fixed memory locations either shared amongst all functions or per-function. If gol is used to return, then the W register can be used to pass the return value.
 * For C compilers, it is recommended to setup a stack as part of the runtime starting from 0x1FF, moving up (numerically down). Use this stack to pass the return address and function parameters. The caller handles loading and cleaning the stack before and after calls. The order of arguments will depend upon the compiler, but the calling convention used in the samples provided is push the return address followed by the arguments from right to left, and then the return value.
