// Just the Add block for incrementing the PC. It felt cleaner to split it
// out into it's own module, even though it's trivial.

module Adder_10bit(input[10:0] arg1, input[10:0] arg2, output[10:0] result);

assign result = arg1 + arg2;

endmodule

//module quicktest_adder;
//
//reg[10:0] arg1,arg2;
//wire[10:0] result;
//
//Adder10bit addymcaddface(arg1, arg2, result);
//
//initial begin
//	arg1 = 1;
//	arg2 = 3;
//	$display(arg1, arg2, result);
//	#10 arg1 = 5;
//	$display(arg1, arg2, result);
//	#10 $finish;
//end
//endmodule
