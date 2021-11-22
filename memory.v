// 1KB 16bit word addressable ram (divide raw byte address by 2)
// Addresses beyond 0x1FF are register access
module ram(
	input[10:0] addr,
	input[15:0] in_data,
	output reg [15:0] out_data,
	input clk,
	input write_enable,
	input [15:0] wreg,
	input carry_in,
	input zero_in,
	output reg carry_out,
	output reg zero_out,
	input reset_bar
);

parameter wreg_addr = 16'h200;
parameter carry_addr = 16'h201;
parameter zero_addr = 16'h202;
parameter indv_addr = 16'h203; // Indirect value
parameter inda_addr = 16'h204; // Indirect pointer
parameter end_of_mem = 16'h204;  // nothing beyond this point

reg[15:0] memory[0:end_of_mem];
reg carry, zero;

initial
begin
	// initialization
	carry_out = 1'b0;
	carry = 1'b0;
	zero_out = 1'b0;
	zero = 1'b0;
	memory[wreg_addr] = 16'h0;
	memory[carry_addr] = 1'b0;
	memory[zero_addr] = 1'b0;
	// Make sure that inda isn't pointed at itself at startup.
	memory[inda_addr] = 16'h0;
end

// Read on leading edge
always @(posedge clk or negedge reset_bar)
begin
  if (~reset_bar) begin
    carry_out = 1'b0;
    zero_out = 1'b0;
    memory[wreg_addr] = 16'h0;
    memory[carry_addr] = 1'b0;
    memory[zero_addr] = 1'b0;
  end else begin
    // Update register values
    memory[wreg_addr] = wreg;
    memory[carry_addr] = {15'd0, carry};
    memory[zero_addr] = {15'd0, zero};
    
    // handle memory reads
    // Return 0xDEAD when reading past the end
    if (addr > end_of_mem) out_data = 16'hDEAD;
    else if (addr == indv_addr) begin
      // Return 0 if trying to trigger infinite indirection
      if (memory[inda_addr] == indv_addr) out_data = 16'h0000;
      // Return indirect value, no need to actually map it to memory
      else out_data = memory[memory[inda_addr]];
      // return requested memory
    end else out_data = memory[addr];

    // Output Status Bit Values
    carry_out = carry;
    zero_out = zero;
  end
end

// Write on trailing edge
always @(negedge clk or negedge reset_bar)
begin
  if (~reset_bar) begin
    // re-initialize
    carry = 1'b0;
    zero = 1'b0;
  end else begin
    // update Status bits values
    carry = carry_in;
    zero = zero_in;

    // Handle Memory Writes
    if (write_enable)
    begin
      if ((addr == carry_addr) || ((addr == indv_addr) && (memory[inda_addr] == carry_addr)))
      begin
        // Ignore value of carry write except for LSB
        memory[addr] = in_data & 16'h0001;
        carry = in_data[0];
      end
      else if ((addr == zero_addr) || ((addr == indv_addr) && (memory[inda_addr] == zero_addr)))
      begin
        // Ignore value of zero write except for LSB
        memory[addr] = in_data & 16'h0001;
        zero = in_data[0];
      end
      else if (addr == indv_addr)
      begin
        if (memory[inda_addr] != indv_addr)
          memory[memory[inda_addr]] = in_data;
        // ignore writes if pointer (somehow) points
        // to indv
      end
      else if (addr == inda_addr)
        memory[addr] = in_data & 16'h1FF;
      else
        memory[addr] = in_data;

      // It's okay to overwrite wreg value in memory, the
      // value will be stomped before the next read outputs
    end
  end
end

endmodule
