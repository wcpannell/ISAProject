// 1KB 16bit word addressable ram (divide raw byte address by 2)
// Addresses beyond 0x1FF are register access
// Carry is currently broken
module ram(
	input[9:0] addr,
	input[15:0] in_data,
	output reg [15:0] out_data,
	input clk,
	input select,
	input write_enable,
	input [15:0] wreg,
	inout carry,
	input zero
);

reg[15:0] memory[0:516];
wire carry_in;
reg carry_out, carry_en;

//output assignment for inout drivers
assign carry = (carry_en) ? carry_out : 1'bz;

//input assignment for inout drivers
assign carry_in = (carry_en) ? carry : 1'bz;

parameter wreg_addr = 16'h200;
parameter carry_addr = 16'h201;
parameter zero_addr = 16'h202;
parameter indv_addr = 16'h203; // Indirect value
parameter inda_addr = 16'h204; // Indirect pointer

initial
begin
	carry_en = 1'b0;
	memory[inda_addr] = 0;
end

// read on leading edge and write on trailing edge
always @(posedge clk)
begin
	// Update register values

	// Return 0 if trying to trigger infinite indirection
	if (memory[inda_addr] == indv_addr)
		memory[indv_addr] = 16'h0000;
	else
		memory[indv_addr] = memory[memory[inda_addr]];

	memory[wreg_addr] = wreg;
	memory[carry_addr] = 15'd0 + carry_in;
	memory[zero_addr] = 15'd0 + zero;
	carry_en = 1'b0; // assume not coercing
	
	// handle memory reads
	if (select)
		out_data = memory[addr];
	else
		out_data = 16'hz;
end

always @(negedge clk)
begin
	if (select & write_enable)
		if (addr != zero_addr)
			if (addr == carry_addr)
			begin
				memory[addr] = in_data & 16'h0001;
				carry_out = in_data & 16'h0001;
				carry_en = 1'b1;
			end
			else if (addr == indv_addr)
			begin
				if (memory[inda_addr] != indv_addr)
					memory[memory[inda_addr]] = in_data;
			end
			else if (addr == inda_addr)
				memory[addr] = in_data & 16'h1FF;
			else
				memory[addr] = in_data;
end

endmodule

module test_ram;

wire[15:0] out_data;
reg[15:0] in_data, wreg;
reg[9:0] addr;
reg select, write_enable, zero;
wire carry, carry_in, clk;
reg carry_out, carry_write;

clock clk1(clk);
ram ram1(.addr(addr), .in_data(in_data), .out_data(out_data), .clk(clk), .select(select), .write_enable(write_enable), .wreg(wreg), .carry(carry), .zero(zero));

assign carry_in = carry;
assign carry = (carry_write) ? carry_out : 1'bz;

initial
begin
	$dumpfile("test.vcd");
	$dumpvars;
	$monitor($time, " in_data = %h, out_data = %h, clk = %b, cs = %b, we = %b", in_data, out_data, clk, select, write_enable);
end

initial
begin
	carry_write = 1'b0;
	wreg = 0;
	addr = 9'h00;
	in_data = 16'hDEAD;
	select = 1'b0;
	#15 select = 1'b1;
	write_enable = 1'b1;  // write 0xDEAD
	#10 write_enable = 1'b0; // read 0xDEAD
	#10 select = 1'b0;
	addr = 9'h01; // write 0xBEEF
	#30 select = 1'b1;
	#10 write_enable = 1'b1;
	in_data = 16'hbeef;
	#10 write_enable = 1'b0;  // read 0xBEEF
	#10 addr = 9'h00; // read 0xDEAD
	#20 select = 1'b0; // read hi-z

	// Test Indirect
	#40 select = 1'b1;
	addr = 10'h204;
	write_enable = 1'b1;
	in_data = 16'h0001;
	#20 write_enable = 1'b0;
	addr = 10'h203; // read 0xBEEF

	// Test regs
	#20 carry_out = 1'b0;
	carry_write = 1'b1;
	wreg = 16'hc0de;
	zero = 1'b0;
	addr = 10'h200;
	#40 addr = 10'h201;
	#20 carry_out = 1'b1;
	#20 in_data = 16'h0;
	write_enable = 1'b1;
	carry_write = 1'b0;
	#20 write_enable = 1'b0;
	#20 addr = 10'h202;
	#20 zero = 1'b1;

end

endmodule
