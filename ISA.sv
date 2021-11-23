//`timescale  1ns/100ps

module ISA(input wire CLOCK_50);

// Registers
reg InterruptController;  // Represents the output of an unimplemented interrupt controller. always 0.
reg reset_bar;

// Busses
wire [15:0] instruction;  // output of program memory
wire[4:0] opcode;  // opcode portion (upper bits) of instruction. split here for convenience.
wire[10:0] literal;  // literal portion (lower bits) of instruction. split here for convenience.

// Control Wires
wire control_int_mux;
wire[1:0] control_pc_mux;
wire control_pc_save;
wire[1:0] control_w_mux;
wire control_mem_write;
wire[3:0] control_alu_op;
wire control_skipmux;

// Hookup-Wires
wire[10:0] pc_mux_out, skipmux_out, add_out, pc_save_out, pc_in, pc_out;
wire[15:0] wreg_out, sign_ext_out, alu_out, mem_out, wreg_in;
wire instr_clock, mem_clock, carry_mem_in, carry_mem_out, zero_mem_in, zero_mem_out;

Multi_Clock multi_clock(CLOCK_50, instr_clock, mem_clock, reset_bar);
Program_Counter program_counter(pc_in, pc_out, instr_clock, reset_bar);
Program_Memory program_memory(pc_out, instruction, instr_clock);
Instruction_Decoder instruction_decoder(opcode, InterruptController, control_int_mux, control_pc_mux, control_pc_save, control_w_mux, control_mem_write, control_alu_op);
PC_Save pc_save(pc_out, control_pc_save, pc_save_out);
Mux2_11bit interrupt_mux(pc_mux_out, 11'h004, control_int_mux, pc_in);
Mux2_11bit skip_mux(11'h1, 11'h2, control_skipmux, skipmux_out);
Mux4_11bit pc_mux(add_out, wreg_out[10:0], literal, pc_save_out, control_pc_mux, pc_mux_out);
Adder_10bit pc_add(pc_out, skipmux_out, add_out);
Sign_Extend sign_extend(literal, sign_ext_out);
wreg w_reg(wreg_in, wreg_out, mem_clock);
ram data_memory(literal, alu_out, mem_out, mem_clock, control_mem_write, wreg_out, carry_mem_in, zero_mem_in, carry_mem_out, zero_mem_out, reset_bar);
alu alu1(mem_out, wreg_out, carry_mem_out, zero_mem_out, control_alu_op, alu_out, carry_mem_in, zero_mem_in, control_skipmux);
Mux4_16bit w_mux(alu_out, mem_out, sign_ext_out, wreg_out, control_w_mux, wreg_in);

assign opcode = instruction[15:11];  // opcode portion of the instruction
assign literal = instruction[10:0];  // Literal value portion of the instruction


initial
begin
	$dumpfile("ISA.vcd");
	$dumpvars;
	//$monitor($time, " PC= %H, instruction = %H", ProgramCounter, instruction);
	$monitor("%d: opcode %b, controls: w_mux %b, mem_write %b, pc_mux %b, pc_save %b, int_mux %b, ALU %b, newPC %h", $time, opcode, control_w_mux, control_mem_write, control_pc_mux, control_pc_save, control_int_mux, control_alu_op, pc_in);
	InterruptController = 1'b0;
	reset_bar = 1'b1;

	// test reset
	//#56 reset_bar = 1'b0;
	//#10 reset_bar = 1'b1;
end

//always @(posedge instr_clock)
always @*
	$display($time,"PC = %H, instruction = %H", pc_out, instruction);

always @(opcode)
	if (opcode == (4'he << 1)) // wfi, aka halt
		#50 $finish;
endmodule
