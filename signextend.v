module Sign_Extend(
	input[10:0] in,
	output[15:0] out
);

assign out = $signed(in);
endmodule

//module Test_Sign_Extend;
//
//reg [10:0] in;
//wire [15:0] out;
//
//Sign_Extend asdf(in, out);
//
//initial
//begin
//	$monitor($time, ": in = %h, %d, out = %h, %d", in,in, out, out);
//	in = 10'h0;
//	#10 in = -1;
//	#10 in = 1;
//	#10 in = 11'h7ff;
//	#10 in = 11'h3ff;
//	#10 $finish;
//end
//endmodule
