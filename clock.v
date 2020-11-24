module clock(output reg clock);

initial
	clock = 1'b0;

always
	#10 clock = ~clock;

//shutdown after 1k cycles
initial
	#1000 $finish;

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
