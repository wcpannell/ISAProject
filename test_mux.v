module test_mux;

reg[3:0] ways;
reg control0, control1;
wire out2, out4;
reg[10:0] in0, in1, in2, in3;
wire[10:0] outintmux;
wire[15:0] outpcmux;

mux2 mux2_1(.in(ways[1:0]), .control(control0), .out(out2));
mux4 mux4_1(.in(ways[3:0]), .control({control1 , control0}), .out(out4));
Mux2_11bit intmux(in0, in1, control0, outintmux);
Mux4_16bit pcmux(in0, in1, in2, in3, {control1, control0}, outpcmux);

initial
begin
	$dumpfile("test_mux.vcd");
	$dumpvars;
	$monitor($time, " ways = %b, controls = %b%b, out2 = %b, out4 = %b, intmux = %h, pcmux=%h", ways, control1, control0, out2, out4, outintmux, outpcmux);
	control0 <= 0;
	control1 <= 0;
	ways <= 4'h0; // outs should be 0
	in0 = 11'h7FF;
	in1 = 11'h5AA;
	in2 = 11'hdea;
	in3 = 11'hdee;
	#10 ways = 4'h1; // outs should be 1
	#10 control0 = 1'b1;  // outs 0
	#10 ways = 4'h2;  // outs 1
	#10 control0 = 1'b0;
	control1 = 1'b1; // outs 0

	// 50
	#10 ways = 4'h4; // out4 1, out2 0
	#10 control0 = 1'b1;  //outs 0
	#10 ways = 4'h8; // out4 = 1, out2 = 0
	#10 ways = 4'hA; // outs = 1;
	#10 ways = 4'h5; // outs = 0;

	// 100
	#10 control0 = 1'b0; // outs = 1;
	#10 $finish;
end
endmodule
