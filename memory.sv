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

logic [15:0] memory[0:end_of_mem];
logic carry, zero;

logic [7:0] peri_addr;
logic peri_read, peri_read_out, peri_write, peri_write_out, peri_irq;
logic [15:0] peri_out;
// logic [15:0] peri_in;  // not required, can share bus w/ memory

// Registers
logic [15:0] inda_value;
logic irq_en;

// only 8 bits in peripheral address.
// use peri_read to ignore out of bounds writes
assign peri_addr = addr[7:0];

// Disable peri_read outside of read cycle
assign peri_read_out = (clk) ? peri_read : 1'b0;

// Disable peri_write outside of write cycle.
// write_enable may not be providing any value?
assign peri_write_out = (~clk && write_enable) ? peri_write : 1'b0;

// interrupt signal
assign interrupt = (irq_en) ? peri_irq : 1'b0;

Peribus_Controller peribus_controller(
  .addr(peri_addr),
  .write_data(in_data),
  .read_data(peri_out),
  .write_enable(peri_write_out),
  .read_enable(peri_read_out),
  .clock(peribus_clock),
  .reset_n(reset_bar),
  .irq(peri_irq),
  .bidir0(bidir0),
  .bidir1(bidir1)
);


initial
begin
  // initialization
  // carry_out = 1'b0;
  // carry = 1'b0;
  // zero_out = 1'b0;
  // zero = 1'b0;
  inda_value = 16'h0;
  //irq_en = 1'b0;
  // memory[wreg_addr] = 16'h0;
  // memory[carry_addr] = 1'b0;
  // memory[zero_addr] = 1'b0;
  // memory[inda_addr] = 16'h0;
end

// Read on leading edge
always_ff @(posedge clk or negedge reset_bar)
begin
  if (~reset_bar) begin
    // In Reset!
    carry_out <= 1'b0;
    zero_out <= 1'b0;
    peri_read <= 1'b0;
    // memory[wreg_addr] <= 16'h0;
    // memory[carry_addr] <= 1'b0;
    // memory[zero_addr] <= 1'b0;
  end else begin
    // Running!

    // Output Status Bit Values
    carry_out <= carry;
    zero_out <= zero;

    // memory read interface
    // case (addr) inside  // QUARTUS LITE DOESNT SUPPORT THIS ARGGGGGGGGGGGGGG
    // Memory Read
    //[11'd0:end_of_mem]: begin
    if (addr <= end_of_mem) begin
      // TODO: rework all peripherals into TIPs
      out_data <= memory[addr];  // read from memory (or TIPs)
      peri_read <= 1'b0;
    end

    // memory[wreg_addr] <= wreg;
    //wreg_addr: begin
    else if (addr == wreg_addr) begin
      peri_read <= 1'b0;
      out_data <= wreg;
    end

    // memory[carry_addr] <= {15'd0, carry};
    //carry_addr: begin
    else if (addr == carry_addr) begin
      peri_read <= 1'b0;
      out_data <= {15'd0, carry};
    end

    // memory[zero_addr] <= {15'd0, zero};
    //zero_addr: begin
    else if (addr == zero_addr) begin
      peri_read <= 1'b0;
      out_data <= {15'd0, zero};
    end

    // Indirect Read Peripheral
    //indv_addr: begin
    else if (addr == indv_addr) begin
      peri_read <= 1'b0;
      if (inda_value >= end_of_mem) out_data <= 16'hDEAD;
      // Return 0 if trying to trigger infinite indirection
      else if (inda_value == indv_addr) out_data <= 16'h0000;
      // Return indirect value, no need to actually map it to memory
      else out_data <= memory[inda_value];
      // return requested memory
    end

    // Indirect Read Address
    //inda_addr: begin
    else if (addr == inda_addr) begin
      peri_read <= 1'b0;
      out_data <= inda_value;
    end

    //irq_addr: begin
    else if (addr == irq_addr) begin
      peri_read <= 1'b0;
      out_data <= {14'd0, irq_en, peri_irq};
    end

    // read from Peribus
    // [PERI_ADDR_START:(PERI_ADDR_START + PERI_ADDR_WIDTH - 1)] : begin
    else if ((addr >= PERI_ADDR_START) && (addr <= (PERI_ADDR_START + PERI_ADDR_WIDTH - 1))) begin
      //else if (addr >= PERI_ADDR_START) begin
      out_data <= peri_out;
      peri_read <= 1'b1;
    end

    // Invalid region gets 0xDEAD
    //default: begin
    else begin
      //if (addr > (end_of_mem + PERI_ADDR_WIDTH - 1)) begin
      out_data <= 16'hDEAD;
      peri_read <= 1'b0;
    end
    //endcase
  end
end

// Write on trailing edge
always_ff @(negedge clk or negedge reset_bar) begin
  // We'll never read on write edge
  if (~reset_bar) begin
    // re-initialize
    carry <= 1'b0;
    zero <= 1'b0;
    peri_write <= 1'b0;
  end else begin
    // update Status bits values
    carry <= carry_in;
    zero <= zero_in;

    // Handle Memory Writes
    if (write_enable) begin

      // Write to memory
      if (addr <= end_of_mem) begin
        memory[addr] <= in_data;
        peri_write <= 1'b0;
      end

      // Writing to wreg not supported

      // Ignore value of carry write except for LSB
      // Direct or Indirect has same result
      else if ((addr == carry_addr) || ((addr == indv_addr) && (inda_value == carry_addr))) begin
        carry <= in_data[0];
        peri_write <= 1'b0;
      end

      // Ignore value of zero write except for LSB
      // Direct or Indirect has same result
      else if ((addr == zero_addr) || ((addr == indv_addr) && (inda_value == zero_addr))) begin
        zero <= in_data[0];
        peri_write <= 1'b0;
      end

      // Indirect Write
      else if (addr == indv_addr) begin
        peri_write <= 1'b0;
        if (inda_value != indv_addr) memory[inda_value] <= in_data;
        // ignore writes if pointer (somehow) points
        // to indv
      end

      // Indirect Write Address
      else if (addr == inda_addr) begin
        memory[addr] <= in_data & 16'h1FF;
        peri_write <= 1'b0;
      end

      // IRQ. Writing to peri_irq has no effect
      else if (addr == irq_addr) begin
        peri_write <= 1'b0;
        irq_en <= in_data[1];
      end

      // Write to peripheral
      else if ((addr >= PERI_ADDR_START) && (addr <= (PERI_ADDR_START + PERI_ADDR_WIDTH))) begin
        peri_write <= 1'b1;
      end

      // Ignore writes to unimplemented memory
      else begin
        peri_write <= 1'b0;
      end

    end
  end
end

endmodule
