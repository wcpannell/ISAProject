/// This test program exercises all the cores functionality
// Then drops into a an interrupt driven counting demo

#define TMR0_CTL_PRE_MASK 0xff00
#define TMR0_CTL_PRE_OFFSET 8
#define TMR0_CTL_IRQEN_OFFSET 2
#define TMR0_CTL_RELOAD_OFFSET 1
#define TMR0_CTL_RUN_OFFSET 0

volatile uint16_t *SW = (uint16_t *)0x300;
volatile uint16_t *SW_dir = (uint16_t *)0x301;
volatile uint16_t *SW_irq_en = (uint16_t *)0x302;
volatile uint16_t *SW_irq = (uint16_t *)0x303;

volatile uint16_t *LEDR = (uint16_t *)0x304;
volatile uint16_t *LEDR_dir = (uint16_t *)0x305;
volatile uint16_t *LEDR_irq_en = (uint16_t *)0x306;
volatile uint16_t *LEDR_irq = (uint16_t *)0x307;

volatile uint16_t *TIMER_0_count = (uint16_t *)0x308;
volatile uint16_t *TIMER_0_period = (uint16_t *)0x308;
volatile uint16_t *TIMER_0_control = (uint16_t *)0x308;
volatile uint16_t *TIMER_0_status = (uint16_t *)0x308;

void __attribute__((interrupt)) __irq(void) {

  // on timer interrupt decrement software prescaler, on zero update the
  // count and increment the display
  if (*TIMER_0_status != 0) {
    *TIMER_0_status = 0; // clear interrupt
    sw_prescale--;
    if (sw_prescale == 0) {
      sw_prescale = (*SW >> 8) & 0xff;
      *LEDR++;
    }
  }
  if (*SW_irq != 0) {
    *SW_irq = 0; // Clear all, doesn't matter how many changed, we'll update the
                 // whole port

    // Software prescale gets upper 8 bits
    sw_prescale = (*SW >> 8) & 0xff;

    // Timer periph prescale gets lower 8 bits
    *TIMER_0_control =
        (*TIMER_0_control & (~TMR0_CTL_PRE_MASK)) | ((*SW & 0xff) << 8);
  }
}

// Simple function call
int add(int *by_ref, int by_val) {
  *by_ref = *by_ref + by_val;
  return by_val;
}

// globals
int i;
int j;
int k;
int l[10];
uint16_t sw_prescale;

void main(void) {
  i = 0;
  j = 20;
  k = 0;
  for (i = 0; i < 10; i++) {
    l[i] = add(&j, i);
  }
  i = i - j;
  if (i >= 10) {
    j = 0xaa;
  } else {
    j = 0x55;
  }
  k = 0x55a9;
  while ((j & k) != 0) {
    k++;
  }
  i = (j | k) == -1;
  i = j > k;
  i = j <= k;

  // Prep the Blinkenlitez
  *SW_dir = 0x0000;      // All inputs
  *SW_irq_en = 0x0000;   // No interrutps (for now)
  *LEDR_irq_en = 0x0000; // no interrupts
  *LEDR_dir = 0xFFFF;    // All outputs
  *TIMER_0_period = 0xFFFF;

  // Show off what we've got
  // This sets the LEDR to the state of its SW
  // set all SW high to exit first demo
  while (*SW != 0xFFFF) {
    *LEDR = *SW;
  }

  // Prep counting blinkenlitez
  *SW_irq_en = 0xFFFF; // Interupt on change
  *TIMER_0_period = 0xFFFF;
  *TIMER_0_control = (0xff << TMR0_CTL_PRE_OFFSET) |
                     (1 << TMR0_CTL_IRQEN_OFFSET) |
                     (1 << TMR0_CTL_IRQEN_OFFSET) | (1 << TMR0_CTL_RUN_OFFSET);

  // Show counting blinkenlitez, see __irq
  while (1) {
  }
}
