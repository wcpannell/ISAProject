module Program_Counter(input[10:0] in, output reg[10:0] out, input clock, input reset_bar);

reg hold;

initial
begin
	// First instruction at 0
	out = 11'h0;

	// Wait 1 first time by, prevents adder from incrementing on first
	// posedge (skipping instruction at program_memory[0]).
	 hold = 1'b1;
end

always @(negedge clock)
begin
	if (reset_bar)
	begin
		if (hold)
		begin
			out = 11'h0;
			hold = 1'b0;
		end
		else  // wait one clock cycle before serving in
			out = in;
	end
end

// Reinitialize on reset
always @(negedge reset_bar)
begin
	out = 11'h0;
	hold = 1'b1;
end

endmodule
