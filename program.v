module Program_Memory(
	input[10:0] addr,
	output reg[15:0] data,
	input clock
);

reg[15:0] memory[0:511];

initial
	$readmemh("program.mem", memory);

always @(posedge clock)
		data = memory[addr];
endmodule
