// test Multi_Clock module
`default_nettype none
module test_clock (input var logic CLOCK_50);

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

