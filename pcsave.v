// PC Save register.
// Stores return value during interrupt.
// Saved value is stored until overwritten.

module PC_Save(input[10:0] addr, input write_enable, output reg[10:0] saved);

initial
	saved = 10'h0; // initialize pointing to reset vector

always @(*)
	if (write_enable)
		saved = addr;

endmodule
