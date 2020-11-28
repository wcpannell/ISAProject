module test_decoder;

reg[4:0] opcode;
reg[3:0] instr;
reg dest;
reg interrupt;
wire int_mux;
wire[1:0] pc_mux;
wire pc_save;
wire[1:0] w_mux;
wire mem_write;
wire[3:0] alu_op;

Instruction_Decoder decode_1(opcode, interrupt, int_mux, pc_mux, pc_save, w_mux, mem_write, alu_op);
assign opcode = {instr, dest};

initial
begin
	$dumpfile("test_decoder.vcd");
	$dumpvars;
	$monitor($time, " opcode %b, dest %b, w_mux %b, mem_write %b, pc_mux %b, pc_save %b, int_mux %b, ALU %b", opcode, dest, w_mux, mem_write, pc_mux, pc_save, int_mux, alu_op);
	interrupt = 1'b0;
	instr = 4'h0;
	dest = 1'b0;
	#10 dest = 1'b1;
	#10 instr = 4'h8;
	#10 dest = 1'b0;
	#10 $finish;
	
end
endmodule
