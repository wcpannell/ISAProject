// Register Definition file for LUC16
//
// Include this file in an assembly program to provide definitions for register locations.

// Typical location for stack pointer is at the end of program memory
STACKPTR equ 0x1FF

// TIPs Registers
WREG equ 0x200  // W Register
CARRY equ 0x201  // Carry Register
ZERO equ 0x202  // Zero Register
INDV equ 0x203  // Indirect Value Register
INDA equ 0x204  // Indirect Pointer Register
IRQ equ 0x205	// Interrupt Control Register

// Interrupt Control Register Bits
IRQ_EN_OFFSET equ 1  // Global Enable / Disable Interrupts
PB_IRQ equ 0  // PeriBus Peripheral Requesting Interrupt

// Result Storage operand definitions
W equ 0
w equ 0
M equ 1
m equ 1

// GPIO 0 Register Locations
GPIO_0_state equ 0x300
GPIO_0_dir equ 0x301
GPIO_0_irq_en equ 0x302
GPIO_0_irq equ 0x303

// GPIO 1 Register Locations
GPIO_1_state equ 0x304
GPIO_1_dir equ 0x305
GPIO_1_irq_en equ 0x306
GPIO_1_irq equ 0x307

// Timer 0 Register Locations
TIMER_0_count equ 0x308
TIMER_0_period equ 0x309
TIMER_0_control equ 0x30A
TIMER_0_status equ 0x30B

// Timer 1 Register Locations
TIMER_1_count equ 0x30C
TIMER_1_period equ 0x30D
TIMER_1_control equ 0x30E
TIMER_1_status equ 0x30F

// Timer Peripheral Control Bits
TMR_CTL_PRE_MASK equ 0xff00
TMR_CTL_PRE_OFFSET equ 8
TMR_CTL_IRQEN_OFFSET equ 2
TMR_CTL_RELOAD_OFFSET equ 1
TMR_CTL_RUN_OFFSET equ 0

// Vector Definitions. These definitions can be used in the ORG directives to place the label that follows it in the appropriate location. These vector names are not required to be used. The programmer may substitue their own vector names and locations as desired. However, regardless of programming, the processor will always load PC value of 0 after reset and a PC value of 4 at the start of an interrupt.

// Reset Vector. Upon exiting the reset state the program counter will be set to 0x0000
VECTOR_RESET equ 0

// Interrupt Vector. Upon Entering the Interrupt state the program counter with be set to 0x0004.
VECTOR_INTERRUPT equ 0x0004

// Start Vector. This is the Vector that the reset vector should jump to once any other reset operations are complete. Any memory intializations that are required before entering main should be done at this vector
VECTOR_START equ 0x0008
