// GPIO Peribus test
//
// This is an interactive test (because I really wanted to see lights blink)
// See below for assignments

`default_nettype none
module test_gpio(
  input [17:0] SW,
  inout [17:0] LEDR,
  output [7:0] LEDG,
  input CLOCK_50,
  input [3:0] KEY
);
logic [15:0] read_data;
logic chipsel;

Gpio gpio_0(
  .addr(SW[17:16]),
  .write_data(SW[15:0]),
  .write_en(~KEY[1]),
  .read_en(~KEY[0]),
  .clock(CLOCK_50),
  .reset_n(KEY[2]),
  .chipselect(chipsel),
  .read_data(read_data),
  .irq(LEDR[17]),
  .bidir_port(LEDR[15:0])
);

assign LEDG[7:0] = KEY[3] ? read_data[7:0] : read_data[15:8];
assign chipsel = 1'b1;

endmodule
