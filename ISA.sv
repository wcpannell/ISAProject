//`timescale  1ns/100ps
`default_nettype none

module ISA(
  input var logic CLOCK_50,
  inout tri [17:0] SW,
  inout tri [17:0] LEDR
);

// Registers
logic reset_bar;
assign reset_bar = SW[17];

// Busses
logic [15:0] instruction;  // output of program memory
logic [4:0] opcode;  // opcode portion (upper bits) of instruction. split here for convenience.
logic [10:0] literal;  // literal portion (lower bits) of instruction. split here for convenience.

// Control Wires
logic [1:0] control_pc_mux;
logic [1:0] control_w_mux;
logic control_mem_write;
logic [3:0] control_alu_op;
logic control_skipmux;
logic irq;
logic [10:0] pc_save;

// Hookup-Wires
logic [10:0] pc_mux_out, skipmux_out, add_out, pc_save_out, pc_in, pc_out;
logic [15:0] wreg_out, sign_ext_out, alu_out, mem_out, wreg_in;
logic instr_clock, mem_clock, carry_mem_in, carry_mem_out, zero_mem_in, zero_mem_out;

Multi_Clock multi_clock(CLOCK_50, instr_clock, mem_clock, reset_bar);
Program_Counter program_counter(pc_in, pc_out, instr_clock, reset_bar);

Program_Memory program_memory(pc_out, instruction, instr_clock);

Instruction_Decoder instruction_decoder(
  .opcode(opcode),
  .mem_clock(mem_clock),
  .reset_bar(reset_bar),
  .pc_mux(control_pc_mux),
  .w_mux(control_w_mux),
  .mem_write(control_mem_write),
  .alu_op(control_alu_op)
);

Interrupt interrupt_controller(
  .irq(irq),
  .instr_clock(instr_clock),
  .reset_n(reset_bar),
  .pc_mux_control(control_pc_mux),
  .pc_next(pc_mux_out),
  .pc_out(pc_in),
  .pc_save(pc_save)
);

Mux2_11bit skipmux(
  .in0(11'h1),
  .in1(11'h2),
  .control(control_skipmux),
  .out(skipmux_out)
);

Mux4_11bit pc_mux(
  .in0(add_out),
  .in1(wreg_out[10:0]),
  .in2(literal),
  .in3(pc_save),
  .control(control_pc_mux),
  .out(pc_mux_out)
);

Adder_10bit pc_add(pc_out, skipmux_out, add_out);
Sign_Extend sign_extend(literal, sign_ext_out);
wreg w_reg(wreg_in, wreg_out, mem_clock);
ram data_memory(
  .addr(literal),
  .in_data(alu_out),
  .out_data(mem_out),
  .clk(mem_clock),
  .write_enable(control_mem_write),
  .wreg(wreg_out),
  .carry_in(carry_mem_in),
  .zero_in(zero_mem_in),
  .carry_out(carry_mem_out),
  .zero_out(zero_mem_out),
  .reset_bar(reset_bar),
  .interrupt(irq),  // For now, sole driver of interrupts (from peribus)
  .bidir0(SW[15:0]),
  .bidir1(LEDR[15:0]),
  .peribus_clock(CLOCK_50)
);
alu alu1(mem_out, wreg_out, carry_mem_out, zero_mem_out, control_alu_op, alu_out, carry_mem_in, zero_mem_in, control_skipmux);
Mux4_16bit w_mux(alu_out, mem_out, sign_ext_out, wreg_out, control_w_mux, wreg_in);

assign opcode = instruction[15:11];  // opcode portion of the instruction
assign literal = instruction[10:0];  // Literal value portion of the instruction

/*
* for testing
initial
begin
  $dumpfile("ISA.vcd");
  $dumpvars;
  //$monitor($time, " PC= %H, instruction = %H", ProgramCounter, instruction);
  $monitor("%d: opcode %b, controls: w_mux %b, mem_write %b, pc_mux %b, pc_save %b, int_mux %b, ALU %b, newPC %h", $time, opcode, control_w_mux, control_mem_write, control_pc_mux, control_pc_save, control_int_mux, control_alu_op, pc_in);
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
*/
endmodule

