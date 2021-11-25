// uses the clock module to output trigger signals for the instr_clock and
// mem_clock
// reset_bar when low holds the instr clock high and the mem clock low
//
// Effective clock is 1/4 speed of input clock to handle each stage.
// Suggest a 4x PLL to compensate if desired

`default_nettype none


module Multi_Clock (
  input var logic clk,
  output var logic instr_clock,
  output var logic mem_clock,
  input var logic reset_n
);

// state counter
logic [1:0] state;

parameter logic [1:0] INSTR_H = 2'd0;
parameter logic [1:0] MEM_H = 2'd1;
parameter logic [1:0] MEM_L = 2'd2;
parameter logic [1:0] INSTR_L = 2'd3;

// Statemachine
always_ff @(posedge clk or negedge reset_n) begin
  if (~reset_n) begin
    // in reset!
    instr_clock <= 1'b0;
    mem_clock <= 1'b0;
    state <= INSTR_H;
  end else begin
    case (state)

      // Instruction clock goes high first (decode instruction)
      INSTR_H: begin
        instr_clock <= 1'b1;
        mem_clock <= 1'b0;
        state <= MEM_H;
      end

      // Mem clock goes next (load operands)
      MEM_H: begin
        instr_clock <= 1'b1;
        mem_clock <= 1'b1;
        state <= MEM_L;
      end

      // Mem clock set high ()
      MEM_L: begin
        instr_clock <= 1'b1;
        mem_clock <= 1'b0;
        state <= INSTR_L;
      end

      // Instruction clock goes low last (load next instr)
      INSTR_L: begin
        instr_clock <= 1'b0;
        mem_clock <= 1'b0;
        state <= INSTR_H;
      end

      // Same as initial state, probably not required unless indeterminate in sim
      default: begin
        instr_clock <= 1'b0;
        mem_clock <= 1'b0;
        state <= INSTR_H;
      end
    endcase
  end
end
endmodule
