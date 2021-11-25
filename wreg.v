// W Register
// This module reads out its value on positive clock edges, and writes its
// value on negative clock edges. It's effectively a 1 word memory

module wreg(input[15:0] in_data, output reg[15:0] out_data, input clk);

reg[15:0] wreg;

// initial
// 	wreg = 16'h0000;

always @(posedge clk)
	out_data = wreg;

always @(negedge clk)
	wreg = in_data;

endmodule
