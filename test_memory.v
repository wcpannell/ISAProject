// Uses clk.v for clock signal, wreg.v for wreg value, and obviously
// memory.v for the ram.
//
// wreg value will always be the same as ram1's outdata, one period behind
//
module test_ram;

wire[15:0] out_data, wreg;
reg[15:0] in_data;
reg[10:0] addr;
reg write_enable;
wire carry_out, zero_out, clk, reset_bar;
reg carry_in, zero_in;

clock clk1(clk);
wreg wreg1(.in_data(out_data), .out_data(wreg), .clk(clk));
ram ram1(.addr(addr), .in_data(in_data), .out_data(out_data), .clk(clk), .write_enable(write_enable), .wreg(wreg), .carry_in(carry_in), .carry_out(carry_out), .zero_in(zero_in), .zero_out(zero_out), .reset_bar(reset_bar));

assign reset_bar = 1'b1;
initial
begin
	$dumpfile("test_mem.vcd");
	$dumpvars;
	$monitor($time, " in_data = %h, out_data = %h, clk = %b, we = %b", in_data, out_data, clk, write_enable);
end

initial
begin
	carry_in = 1'b0;
	zero_in = 1'b0;
	addr = 11'h00;
	in_data = 16'hDEAD;
	#15write_enable = 1'b1;  // write 0xDEAD
	#10 write_enable = 1'b0; // read 0xDEAD
	#10 addr = 11'h01; // write 0xBEEF
	#40 write_enable = 1'b1;
	in_data = 16'hbeef;
	#10 write_enable = 1'b0;  // read 0xBEEF
	#10 addr = 11'h00; // read 0xDEAD

	// Test Indirect
	#40 addr = 11'h204;
	write_enable = 1'b1;
	in_data = 16'h0001;
	#20 write_enable = 1'b0;
	addr = 11'h203; // read 0xBEEF

	// Test regs
	#20 addr = 11'h200; // Read Wreg
	// wreg = 16'hc0de;
	#40 addr = 11'h201; // Read Carry
	#20 carry_in = 1'b1;
	zero_in = 1'b1;
	#20 in_data = 16'h0;
	write_enable = 1'b1; // Write 0 to Carry
	#20 write_enable = 1'b0;
	#20 addr = 11'h202; // Read Zero (1)
	#20 write_enable = 1'b1; // Write Zero (0), Read Zero (0)
	#20 write_enable = 1'b0; // Read Zero (1)

end

endmodule

