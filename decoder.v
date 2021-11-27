module Instruction_Decoder(
	input[4:0] opcode,
  input mem_clock,
  input reset_bar,
	output reg[1:0] pc_mux,
	output reg[1:0] w_mux,
	output reg mem_write,
	output reg[3:0] alu_op
);

parameter W_ALU = 2'h0;
parameter W_MEM = 2'h1;
parameter W_LIT = 2'h2;
parameter W_WREG = 2'h3;

parameter PC_ADD = 2'h0;
parameter PC_WREG = 2'h1;
parameter PC_LIT = 2'h2;
parameter PC_SAVE = 2'h3;

parameter ALU_ROTL = 4'h0;
parameter ALU_ROTR = 4'h1;
parameter ALU_ADD = 4'h2;
parameter ALU_SUB = 4'h3;
parameter ALU_AND = 4'h4;
parameter ALU_OR = 4'h5;
parameter ALU_XOR = 4'h6;
parameter ALU_ZEROT = 4'h7;
parameter ALU_PCZERO = 4'h8;
parameter ALU_PCZEROBAR = 4'h9;
parameter ALU_NOP = 4'hA;

// initial
// begin
// 	pc_mux = 0;
// 	w_mux = 0;
// 	mem_write = 0;
// 	alu_op = 0;
// end

always @(opcode)
begin
	case (opcode[4:1])
		// mm
		4'h0 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_MEM;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_ZEROT;
		end

		// mwm
		4'h1 :
		begin
			w_mux = W_WREG;
			mem_write = 1'b1;
			pc_mux = PC_ADD;
			alu_op = ALU_NOP;
		end

		//mlw
		4'h2 :
		begin
			w_mux = W_LIT;
			mem_write = 1'b0;
			pc_mux = PC_ADD;
			alu_op = ALU_NOP;
		end

		// rlm
		4'h3 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_ALU;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_ROTL;
		end

		//rrm
		4'h4 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_ALU;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_ROTR;
		end

		//awm
		4'h5 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_ALU;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_AND;
		end

		// owm
		4'h6 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_ALU;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_OR;
		end

		// xwm
		4'h7 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_ALU;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_XOR;
		end

		// add
		4'h8 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_ALU;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_ADD;
		end

		// sub
		4'h9 :
		begin
			if (opcode[0])
				w_mux = W_WREG;
			else
				w_mux = W_ALU;
			mem_write = opcode[0];
			pc_mux = PC_ADD;
			alu_op = ALU_SUB;
		end

		// sms
		4'hA :
		begin
			w_mux = W_WREG;
			mem_write = 1'b0;
			pc_mux = PC_ADD;
			alu_op = ALU_PCZERO;
		end

		// smc
		4'hB :
		begin
			w_mux = W_WREG;
			mem_write = 1'b0;
			pc_mux = PC_ADD;
			alu_op = ALU_PCZEROBAR;
		end

		// gol
		4'hC :
		begin
			w_mux = W_WREG;
			mem_write = 1'b0;
			pc_mux = PC_LIT;
			alu_op = ALU_NOP;
		end

		// gow
		4'hD :
		begin
			w_mux = W_WREG;
			mem_write = 1'b0;
			pc_mux = PC_WREG;
			alu_op = ALU_NOP;
		end

		// wfi
		4'hE :
		begin
			w_mux = W_WREG;
			mem_write = 1'b0;
			pc_mux = PC_SAVE;
			alu_op = ALU_NOP;
		end

		// rfi
		4'hF :
		begin
			w_mux = W_WREG;
			mem_write = 1'b0;
			pc_mux = PC_SAVE;
			alu_op = ALU_NOP;
		end
	endcase
end
endmodule
