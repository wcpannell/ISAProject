// Testbench for programcounter.sv

`default_nettype none

module test_programcounter(input var logic CLOCK_50);

logic [10:0] pc_in;
logic [10:0] pc_out;
logic clock, reset_bar;

Program_Counter program_counter(pc_in, pc_out, clock, reset_bar);

always #10 clock = ~clock;

initial begin
  clock = 1'b0;
  reset_bar = 1'b0;
  pc_in = 11'd1337;
  #100 reset_bar = 1'b1;  // release from reset
  #100 reset_bar = 1'b0;  // reset
  #100 reset_bar = 1'b1;  // run

end
endmodule
