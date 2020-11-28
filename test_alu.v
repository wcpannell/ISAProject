module test_alu;

reg signed[15:0] mem, wreg;
reg carry_in, zero_in;
reg[3:0] alu_op;
wire signed[15:0] result;
wire carry_out, zero_out, pc_skip;

alu alu1(mem, wreg, carry_in, zero_in, alu_op, result, carry_out, zero_out, pc_skip);

assign carry_in = carry_out;
assign zero_in = zero_out;

initial
begin
	$dumpfile("test_alu.vcd");
	$dumpvars;
	$monitor($time, " S=%b, C=%b, Z=%b, op = %H, mem = %H, wreg = %H, result = %h", pc_skip, carry_in, zero_in, alu_op, mem, wreg, result);
	alu_op = 4'h9;
	mem = 16'hAA55;
	wreg = 16'hC0DE;
	#10 alu_op = 4'h0; // ShiftL
	#10 mem = result;
	#10 mem = -4;  // carry set on output
	#10 mem = result;

	// 50
	#10 alu_op = 4'hF;  // Nop
	#10 alu_op = 4'h1; // ShiftR
	mem = 16'hAA55;
	#10 mem = result;
	#10 mem = -4;
	#10 mem = result;

	// 100
	#10 alu_op = 4'h2; // Add Wreg + Mem
	#0 $display("Add: mem + Wreg, %d + %d = %d", mem, wreg, result);
	#10 mem = result;
	#0 $display("Add: mem + Wreg, %d + %d = %d", mem, wreg, result);
	#10 mem = result;
	#0 $display("Add: mem + Wreg, %d + %d = %d", mem, wreg, result);
	#10 wreg = -1;
	#0 $display("Add: mem + Wreg, %d + %d = %d", mem, wreg, result);
	#10 mem = result;
	#0 $display("Add: mem + Wreg, %d + %d = %d", mem, wreg, result);

	// 150
	#10 alu_op = 4'h3; // Subtract 
	mem = -32767; // largest negative
	wreg = -32767;
	#0 $display("Sub: mem - Wreg, -32767 - -32767 = 0", mem, wreg, result);
	$display("Z=1, C=1 (no borrow occurred)");
	#10 mem = 32767;
	#0 $display("Sub: mem - Wreg, 32767 - -32767 = 0", mem, wreg, result);
	$display("Z=0, C=0 (borrow occurred)");
	#10 mem = 1;
	wreg = 1; // zero set, carry set
	#0 $display("Sub: mem - Wreg, 1 - 1 = 0", mem, wreg, result);
	$display("Z=1, C=1 (no borrow)");
	#10 wreg = 2; // zero clear
	#0 $display("Sub: mem - Wreg, 1 - 2 = -1", mem, wreg, result);
	$display("Z=0, C=0 (borrow)");
	#10 mem = result;
	#0 $display("Sub: mem - Wreg, -1 - 2 = -3", mem, wreg, result);
	$display("Z=0, C=1 (no borrow)");

	// 200
	#10 wreg = result;
	#0 $display("Sub: mem - Wreg, -1 - -3 = 2", mem, wreg, result);
	$display("Z=0, C=0 ( borrow)");
	#10 alu_op = 4'h2;
	wreg = 16'hffff;
	mem = 16'h1;
	$display("Add (2) to set carry and zero");
	#10 alu_op = 4'h4;
	mem = 16'haa55;
	$display("And (4), result = AA55, zero clear, carry still set");
	#10 mem = 16'haa55;
	wreg = 16'h55aa;
	$display("\tresult = 0x0000, zero set, carry still set");
	#10 alu_op = 4'h5;
	$display("Inclusive Or (5), result = 0xff, zero clear, carry still set");

	// 250
	#10 wreg = 16'h0000;
	$display("\tresult = 0xAA55, zero clear, carry still set");
	#10 mem = 16'h0000; 
	$display("\tresult = 0x0000, zero set, carry still set");
	#10 alu_op = 4'h6;
	mem = 16'haa55;
	wreg = 16'h55aa;
	$display("XOR (6), result = 0xffff, Zero clear, Carry still set");
	#10 wreg = 16'haa55;
	$display("\tresult = 0x0000, zero set, carry still set.");
	#10 alu_op = 4'h7;
	$display("ZeroTest (7), result = mem, zero clear, carry still set");

	// 300
	#10 mem = 16'h0;
	$display("\tresult = mem = 0, zero set, carry still set");
	#10 alu_op = 4'h8;
	$display("PCZero (8), mem = 0, Z still set, S clear");
	#10 alu_op = 4'h2;
	$display("Add to clear zero, carry");
	#10 alu_op = 4'h8;
	$display("PCZero (8), mem = 0, Z still clear, S clear");
	#10 mem = 16'h2;
	$display("\t mem = 2, Z still clear, S set");

	// 350
	#10 alu_op = 4'h9;
	$display("PCZerobar (9), mem = 2, Zstill clear, S clear");
	#10 mem = 16'h1;
	wreg = 16'hFFFF;
	alu_op = 4'h2;
	$display("Add to set carry and Z");
	#10 alu_op = 4'h9;
	mem = 16'h0;
	$display("PCZerobar (9), mem 0, Z still set, Carry still set, S set");
	#10 alu_op = 4'hA;
	$display("Nop (A), skip cleared, result = wreg, everything else same");
	#10 $finish;
end
endmodule
