module clock(output reg clock);

initial
	clock = 1'b0;

always
	#10 clock = ~clock;

//shutdown after 1k cycles
//initial
//	#1000 $finish;

endmodule

// uses the clock module to output trigger signals for the instr_clock and
// mem_clock
// reset_bar when low holds the instr clock high and the mem clock low
module Multi_Clock (
	output reg instr_clock,
	output reg mem_clock,
	input reset_bar
);

reg clk, hold;

clock base_clk(clk);

initial
begin
	instr_clock = 1'b1;
	mem_clock = 1'b0;
	hold = 1'b1;
end

always @(posedge clk)
begin
		instr_clock = clk;
	if (reset_bar)  // Don't go high if in reset, wait for negedge to start output
		if (!hold)
			mem_clock = #5 clk;

end
always @(negedge clk)
begin
	mem_clock = clk;
	if (reset_bar)  // Don't go low if in reset
	begin
		instr_clock = #5 clk;
		hold = 1'b0;  // clear hold if not in reset, ready for mem_clock
	end
	else
		hold = 1'b1; // set hold if in reset
end
endmodule

/* test
module test_clock;

wire clk;

clock clk1(clk);

initial
begin
	$dumpfile("test.vcd");
	$dumpvars;
	$monitor($time, "clock level = %b", clk);
end
endmodule
*/
