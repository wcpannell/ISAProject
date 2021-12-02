// 1KB 16bit word addressable ram (divide raw byte address by 2)
// Addresses beyond 0x1FF are register access
// All Tightly Integrated Peripherals (TIPs) are controlled by the memory unit.

`default_nettype none

module ram(
  input var logic [10:0] addr,
  input var logic [15:0] in_data,
  input var logic clk,
  input var logic write_enable,
  input var logic [15:0] wreg,
  input var logic carry_in,
  input var logic zero_in,
  input var logic reset_bar,
  input var logic peribus_clock,
  output var logic carry_out,
  output var logic zero_out,
  output var logic [15:0] out_data,
  output var logic interrupt,
  inout tri [15:0] bidir0,
  inout tri [15:0] bidir1
);

// TIPS
// TODO: Rework to not  use memory block
parameter end_of_mem = 11'h1FF;  // nothing beyond this point
parameter wreg_addr = 16'h200;
parameter carry_addr = 16'h201;
parameter zero_addr = 16'h202;
parameter indv_addr = 16'h203; // Indirect value
parameter inda_addr = 16'h204; // Indirect pointer
parameter irq_addr = 11'h205;
parameter PERI_ADDR_START = 11'h300;
parameter PERI_ADDR_WIDTH = 11'h100;

// used for identifying active region
localparam MEM_UPPER = 3'b00?;
localparam TIP_UPPER = 3'b010;
localparam PERI_UPPER = 3'b011;

// active region types
localparam MEM_ACTIVE = 2'b00;
localparam TIP_ACTIVE = 2'b01;
localparam PERI_ACTIVE = 2'b10;
localparam BAD_ACTIVE = 2'b11;

//TIP lower bit values
localparam WREG_ADDR_LOWER = wreg_addr[2:0];
localparam CARRY_ADDR_LOWER = carry_addr[2:0];
localparam ZERO_ADDR_LOWER = zero_addr[2:0];
localparam INDV_ADDR_LOWER = indv_addr[2:0];
localparam INDA_ADDR_LOWER = inda_addr[2:0];
localparam IRQ_ADDR_LOWER = irq_addr[2:0];


// logic [15:0] memory[0:end_of_mem];
logic carry, zero;

logic [7:0] peri_addr;
logic peri_read, peri_read_out, peri_write, peri_write_out, peri_write_inhibit, peri_irq;
logic [15:0] peri_out;
// logic [15:0] peri_in;  // not required, can share bus w/ memory

// Registers
logic [10:0] inda_value;
logic [15:0] indv_read_value;
logic irq_en;

logic [15:0] memory_out;
logic indirect_write, mem_write;

logic [1:0] region_active;
logic [15:0] tip_out;

// select correct write interface
assign mem_write = (region_active == MEM_ACTIVE) ? write_enable : 1'b0;
assign indirect_write = (
  (region_active == TIP_ACTIVE) &&
  (addr[2:0] == INDV_ADDR_LOWER)
) ? write_enable : 1'b0;
assign peri_write = (region_active == PERI_ACTIVE) ? write_enable : 1'b0;

// Memory_block memory (
//   .clk(clk),
//   .write_en(mem_write),
//   .indv_write_en(indirect_write),
//   .addr(addr[9:0]),
//   .inda_addr(inda_value[9:0]),
//   .write_in(in_data),
//   .indv_write_in(in_data),
//   .read_out(memory_out),
//   .indv_out(indv_read_value)
// );
// Drive the ram clocks
logic ram_wr_clk, ram_clk, ram_read, ram_write, ram_rd_dly, ram_wr_dly;
assign ram_wr_clk = ~clk;

// sets delay at the next peribus_clock falling edge after posedge clk
always_ff @(negedge peribus_clock)
  ram_rd_dly <= clk;

// sets delay until the next peribus_clock falling edge after posedge ram_wr_clk
always_ff @(negedge peribus_clock)
  ram_wr_dly <= ram_wr_clk;

// pulse on clk rising edge, half period of peribus_clock
assign ram_read = clk & ~ram_rd_dly;

// pulse on clk falling edge, half period of peribus_clock
// must be combined with write_enable
assign ram_write = ram_wr_clk & ~ram_wr_dly;

// double pulse to drive the ram clock. first pulse for read, second for write
assign ram_clk = ram_read | ram_write;

ipram2port ipram2port_inst (
  .address_a ( addr[8:0] ),
  .address_b ( inda_value[8:0] ),
  .data_a ( in_data ),
  .data_b ( in_data ),
  .clock ( ram_clk ),
  .rden_a ( ram_read ),
  .rden_b ( ram_read ),
  .wren_a ( ram_write & mem_write ),
  .wren_b ( ram_write & indirect_write ),
  .q_a ( memory_out ),
  .q_b ( indv_read_value )
);


// only 8 bits in peripheral address.
// use peri_read to ignore out of bounds writes
assign peri_addr = addr[7:0];

// Disable peri_read outside of read cycle
//assign peri_read_out = (clk) ? peri_read : 1'b0;
assign peri_read_out = (reset_bar) ? 1'b1 : 1'b0;

// Disable peri_write outside of write cycle.
//
// peri_write needs to go positive as early as the positive edge of the mem_clock
// and late as the negedge of mem_clock if write_enable and addr is in range
// peri_write needs to go negative on the next positive edge of peribus_clock
// peri_write cannot go positive again until the first condition

// assign peri_addr_range = ((addr >= PERI_ADDR_START) && (addr <= (PERI_ADDR_START + PERI_ADDR_WIDTH - 1))) ? 1'b1 : 1'b0;

// always_ff @(posedge peribus_clock or posedge clk) begin
//   if (clk) peri_write_inhibit <= 1'b0;
//   else peri_write_inhibit <= 1'b1;
// end
// 
// // not inhibited and in peripheral address range? peri_write = write_enable,
// // else no write.
// assign peri_write_out = (~peri_write_inhibit && (region_active == PERI_ACTIVE)) ? write_enable : 1'b0;

// interrupt signal
assign interrupt = (irq_en) ? peri_irq : 1'b0;

Peribus_Controller peribus_controller(
  .addr(peri_addr),
  .write_data(in_data),
  .read_data(peri_out),
  .write_enable(peri_write & ram_write),
  .read_enable(peri_read_out),
  .clock(peribus_clock),
  .reset_n(reset_bar),
  .irq(peri_irq),
  .bidir0(bidir0),
  .bidir1(bidir1)
);

// Read output mux
Mux4_16bit output_mux(
  .in0(memory_out),
  .in1(tip_out),
  .in2(peri_out),
  .in3(16'hDEAD),
  .control(region_active),
  .out(out_data)
);

// Which memory portion is active?
always_comb begin
  casez (addr[10:8])
    MEM_UPPER: region_active = MEM_ACTIVE;
    TIP_UPPER: region_active = TIP_ACTIVE;
    PERI_UPPER: region_active = PERI_ACTIVE;
    default: region_active = BAD_ACTIVE;
  endcase
end

// Tightly Integrated Peripherals (TIP)
//
// The name was chosen before the memory was broken into its own block
// these registers were written into and read from memory
always_comb begin
  case(addr[2:0])
    WREG_ADDR_LOWER: tip_out = wreg;
    CARRY_ADDR_LOWER: tip_out = {15'd0, carry};
    ZERO_ADDR_LOWER: tip_out = {15'd0, zero};
    INDV_ADDR_LOWER: tip_out = indv_read_value;
    INDA_ADDR_LOWER: tip_out = inda_value;
    //IRQ_ADDR_LOWER
    default:  tip_out = {14'd0, irq_en, peri_irq};
  endcase
end

// Carry Out on Read
always_ff @(posedge clk or negedge reset_bar) begin
  if (~reset_bar) carry_out <= 1'b0;
  else carry_out <= carry;
end
always_ff @(posedge clk or negedge reset_bar) begin
  if (~reset_bar) zero_out <= 1'b0;
  else zero_out <= zero;
end

// carry in on write edge
always_ff @(negedge clk or negedge reset_bar) begin
  // re-initialize
  if (~reset_bar) carry <= 1'b0;
  else if ((write_enable && region_active == TIP_ACTIVE) && (addr[2:0] == CARRY_ADDR_LOWER)) carry <= in_data[0];
  else carry <= carry_in;
end

// zero in on write edge
always_ff @(negedge clk or negedge reset_bar) begin
  // re-initialize
  if (~reset_bar) zero <= 1'b0;
  else if (
    write_enable &&
    (region_active == TIP_ACTIVE) &&
    (addr[2:0] == ZERO_ADDR_LOWER)
  ) zero <= in_data[0];
  else zero <= zero_in;
end

// write to indv
// handled in assign near Memory_block

// inda in on write edge
always_ff @(negedge clk or negedge reset_bar) begin
  // re-initialize
  if (~reset_bar) inda_value <= 11'd0;
  else if (
    write_enable &&
    (region_active == TIP_ACTIVE) &&
    (addr[2:0] == INDA_ADDR_LOWER)
  ) inda_value <= (in_data != indv_addr) ? in_data[10:0] : 11'd0;  // only write within limits
end

// IRQ. Writing to peri_irq has no effect
always_ff @(negedge clk or negedge reset_bar) begin
  // re-initialize
  if (~reset_bar) irq_en <= 1'b0;
  else if (
    write_enable &&
    (region_active == TIP_ACTIVE) &&
    (addr[2:0] == IRQ_ADDR_LOWER)
  ) irq_en <= in_data[1];
end
endmodule

// not used in favor of IP ram module
module Memory_block #(
  parameter WORDS = 512,
  parameter WORD_SIZE = 16
) (
  input var logic clk,  // write on negedge
  input var logic write_en,
  input var logic indv_write_en,
  input var logic [$clog2(WORDS) - 1:0] addr,
  input var logic [$clog2(WORDS) - 1:0] inda_addr,
  input var logic [WORD_SIZE - 1:0] write_in,
  input var logic [WORD_SIZE - 1:0] indv_write_in,
  output var logic [WORD_SIZE - 1:0] read_out,
  output var logic [WORD_SIZE - 1:0] indv_out
);

logic [WORD_SIZE - 1:0] memory[WORDS - 1:0];

always_ff @(negedge clk) begin
  if (write_en) memory[addr] <= write_in;
end

always_ff @(negedge clk) begin
  if (write_en) memory[inda_addr] <= indv_write_in;
end

// if writing indirectly, address write function with inda_addr, else normal addr
always_ff @(posedge clk) begin
  read_out <= memory[addr];
  indv_out <= memory[inda_addr];
end
endmodule
