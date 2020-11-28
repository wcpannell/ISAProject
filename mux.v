// 2 and 4 way mux

module mux2(input[1:0] in, input control, output out);

assign out = in[control];

endmodule

module mux4(input[3:0] in, input[1:0] control, output out);

assign out = in[control];

endmodule

module Mux2_11bit(input[10:0] in0, input[10:0] in1, input control, output[10:0] out);

assign out = control ? in1 : in0;

endmodule

module Mux4_16bit(
	input[15:0] in0,
	input[15:0] in1,
	input[15:0] in2,
	input[15:0] in3,
	input[1:0] control,
	output reg[15:0] out
);

always @(*)
begin
	case (control)
		2'b00 : out = in0;
		2'b01 : out = in1;
		2'b10 : out = in2;
		2'b11 : out = in3;
	endcase
end
endmodule

module Mux4_11bit(
	input[10:0] in0,
	input[10:0] in1,
	input[10:0] in2,
	input[10:0] in3,
	input[1:0] control,
	output reg[10:0] out
);

always @(*)
begin
	case (control)
		2'b00 : out = in0;
		2'b01 : out = in1;
		2'b10 : out = in2;
		2'b11 : out = in3;
	endcase
end
endmodule
