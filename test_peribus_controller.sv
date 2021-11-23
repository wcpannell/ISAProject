// Test bench for peribus controller

`default_nettype none
module test_peribus_controller(input var logic CLOCK_50);
logic [7:0] addr;
logic [15:0] write_data;
logic [15:0] read_data;
logic write_enable;  // interface async
logic read_enable;  // interface async
logic reset_n;
logic irq;
tri [17:0] sw;
tri [17:0] ledr;

Peribus_Controller peribus(
  addr,
  write_data,
  read_data,
  CLOCK_50,  // bus uses own CLOCK_50
  write_enable,  // interface async
  read_enable,  // interface async
  reset_n,
  irq,
  sw,
  ledr
);

logic [15:0] switches;

initial begin
  reset_n = 1'b0;
  addr = 8'd0;  // Switch state port
  write_data = 16'd0;
  write_enable = 1'b0;
  read_enable = 1'b0;
  #20 reset_n = 1'b1;
  #10 read_enable = 1'b1;
  #10 switches = read_data;
  #10 read_enable = 1'b0;
  #10 addr = 8'h05;  // LEDR Direction port
  write_data = 16'hAA55;
  write_enable = 1'b1;
  #10 write_enable = 1'b0;
  write_data = switches;
  #10 addr = 8'h04;  // LEDR state port
  #10 write_enable = 1'b1;
  #10 write_enable = 1'b0;
end

endmodule
