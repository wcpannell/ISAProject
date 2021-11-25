module alu(
	input signed[15:0] mem,
	input signed[15:0] wreg,
	input carry_in,
	input zero_in,
	input[3:0] alu_op,
	output reg signed[15:0] result,
	output reg carry_out,
	output reg zero_out,
	output reg pc_skip
);

// initial
// begin
// 	#0 carry_out = 1'b0;
// 	#0 zero_out = 1'b0;
// 	pc_skip = 1'b0;
// 	result = 16'bz;
// end

always @(mem, wreg, alu_op, carry_in, zero_in)
begin
	// Default bit outputs
	// handle them as needed in cases.
	pc_skip = 1'b0;
	zero_out = zero_in;
	carry_out = carry_in;

	case (alu_op)
		// RotL
		// 4'h0 : {carry_out, result} = (mem << 1) + carry_in;
		4'h0 : {carry_out, result} = {mem, carry_in};

		// RotR
		4'h1 : begin
			// result = {carry_in, mem} >> 1;
			// carry_out = mem[0]; // has to go after so it doesn't change carry_in in tests
			{result, carry_out} = {carry_in, mem};
		end

		// Add
		4'h2 : begin
			{carry_out, result} = (mem & 17'h0ffff) + (wreg & 17'h0ffff); // don't sign extend operands to 17 bits.
			zero_out = ~|result;
		end

		// Sub
		4'h3 : begin
			{carry_out, result} = (mem & 17'h0ffff) + ((~wreg + 1) & 17'h0ffff); // Don't sign extend the operands to 17 bits. verified correct for unsigned.
			//result = mem - wreg;
			//carry_out = (wreg > mem) ? 1'b0 : 1'b1;
			zero_out = ~|result;
		end

		// And
		4'h4 : begin
			result = mem & wreg;
			zero_out = ~|result;
		end

		// Or
		4'h5 : begin
			result = mem | wreg;
			zero_out = ~|result;
		end

		// Xor
		4'h6 : begin
			result = mem ^ wreg;
			zero_out = ~|result;
		end

		// ZeroTest - sets zero_out if mem value is zero
		4'h7 : begin
			result = mem; // passthrough
			zero_out = ~|result;
		end

		// PCZero - Set PC_Skip if mem is nonzero 
		4'h8 : begin
			result = mem; // passthrough
			pc_skip = |result;
		end

		// PCZerobar - Set PC_Skip if mem is zero
		4'h9 : begin
			result = mem; // passthrough
			pc_skip = ~|result;
		end

		// Nop
		default : {carry_out, result} = {carry_in, wreg};
	endcase
end

endmodule

