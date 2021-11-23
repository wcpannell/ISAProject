// Controller unit for Peribus
`default_nettype none

module Peribus_Controller #(
  parameter MAX_PERIPHERALS=8,  // Maximum number of peripherals on bus
  parameter PERI_ADDR_WIDTH='h100,  // width of address space
  parameter MAX_PERI_REGS=8  // maximum number of memory words per peripheral
) (
  input var logic [7:0] addr,
  input var logic [15:0] write_data,
  output var logic [15:0] read_data,
  input var logic CLOCK_50,  // bus uses own CLOCK_50
  input var logic write_enable,  // interface async
  input var logic read_enable,  // interface async
  input var logic reset_n,
  output var logic irq,

  // Peripheral output stuff
  inout tri [17:0] SW,
  inout tri [17:0] LEDR
);

// Number of address lines on peripheral bus
localparam MAX_PERI_REGS_BITS = $clog2(MAX_PERI_REGS);

logic [MAX_PERIPHERALS:0] irq_lines = 0;
logic [MAX_PERIPHERALS:0] chipselects;
logic [MAX_PERI_REGS_BITS:0] peri_addr;  // per-peripheral addresses

// trigger an IRQ if any of the lines are set
assign irq = |irq_lines;

// GPIO_0 slider switches
localparam GPIO_0_START = 'h0;
localparam GPIO_0_WIDTH = 'h4;
localparam GPIO_0_LINE = 'd0;
logic [15:0] gpio_0_read_data;
Gpio gpio_0(
  .addr(addr[1:0]),
  .write_data(write_data),
  .write_en(write_enable),
  .read_en(read_enable),
  .clock(CLOCK_50),
  .reset_n(reset_n),
  .chipselect(chipselects[GPIO_0_LINE]),
  .read_data(gpio_0_read_data),
  .irq(irq_lines[GPIO_0_LINE]),
  .bidir_port(SW[15:0])
);

// GPIO_1
localparam GPIO_1_START = 'h4;
localparam GPIO_1_WIDTH = 'h4;
localparam GPIO_1_LINE = 'd1;
logic [15:0] gpio_1_read_data;
Gpio gpio_1(
  .addr(addr[1:0]),
  .write_data(write_data),
  .write_en(write_enable),
  .read_en(read_enable),
  .clock(CLOCK_50),
  .reset_n(reset_n),
  .chipselect(chipselects[GPIO_1_LINE]),
  .read_data(gpio_1_read_data),
  .irq(irq_lines[GPIO_1_LINE]),
  .bidir_port(LEDR[15:0])
);

// TIMER_0
localparam TIMER_0_START = 'h8;
localparam TIMER_0_WIDTH = 'h4;
localparam TIMER_0_LINE = 'd2;
logic[15:0] timer_0_read_data;

// TIMER_1
localparam TIMER_1_START = 'hC;
localparam TIMER_1_WIDTH = 'h4;
localparam TIMER_1_LINE = 'd3;
logic[15:0] timer_1_read_data;


// Address used inside each peripheral
assign peri_addr = addr[MAX_PERI_REGS_BITS:0];

// This block uses the requested address to multiplex the chipselect and
// read_data lines
always_comb begin
  // this would be much nicer if Quartus lite allowed "case (addr) inside"

  // GPIO_0
  if (addr < (GPIO_0_START + GPIO_0_WIDTH)) begin
    chipselects = 'd1 << GPIO_0_LINE;
    read_data = gpio_0_read_data;
  end

  // GPIO_1
  else if ((addr >= GPIO_1_START) && (addr < (GPIO_1_START + GPIO_1_WIDTH))) begin
    chipselects = 'd1 << GPIO_1_LINE;
    read_data = gpio_1_read_data;
  end

  // TIMER_0
  else if ((addr >= TIMER_0_START) && (addr < (TIMER_0_START + TIMER_0_WIDTH))) begin
    chipselects = 'd1 << TIMER_0_LINE;
    read_data = timer_0_read_data;
  end

  // TIMER_1
  else if ((addr >= TIMER_1_START) && (addr < (TIMER_1_START + TIMER_1_WIDTH))) begin
    chipselects = {MAX_PERIPHERALS{1'd1}} << TIMER_1_LINE;
    read_data = timer_1_read_data;
  end

  // Unknown. don't do anything
  else begin
    chipselects = 0;
    read_data = 16'dx;
  end
end

endmodule