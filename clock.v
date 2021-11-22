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
always_ff @(posedge clk or posedge reset_n) begin
  if (reset_n) begin
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

  end else begin
    // in reset!
    instr_clock <= 1'b0;
    mem_clock <= 1'b0;
    state <= INSTR_H;
  end
end
endmodule




// module old_Multi_Clock
// logic hold;
// initial
// begin
//   instr_clock = 1'b1;
//   mem_clock = 1'b0;
//   hold = 1'b1;
// end
// 
// always @(posedge clk)
// begin
//     instr_clock = clk;
//   if (reset_bar)  // Don't go high if in reset, wait for negedge to start output
//     if (!hold)
//       mem_clock = #5 clk;
// 
// end
// always @(negedge clk)
// begin
//   mem_clock = clk;
//   if (reset_bar)  // Don't go low if in reset
//   begin
//     instr_clock = #5 clk;
//     hold = 1'b0;  // clear hold if not in reset, ready for mem_clock
//   end
//   else
//     hold = 1'b1; // set hold if in reset
// end
// endmodule

// test
module clock (input var logic CLOCK_50);

logic instr, mem, reset;

Multi_Clock clk1(.clk(CLOCK_50), .instr_clock(instr), .mem_clock(mem), .reset_n(reset));

initial
begin
  $dumpfile("test.vcd");
  $dumpvars;
  $monitor($time, "clock level = %b, instr = %b, mem = %b, reset_n = %b", CLOCK_50, instr, mem, reset);

  reset = 1'b0;
  #100 reset = 1'b1;
  #400 reset = 1'b0;
  #200 reset = 1'b1;
end
endmodule
