module Program_Memory(
	input[10:0] addr,
	output reg[15:0] data,
	input clock
);

reg[15:0] memory[0:511] /* synthesis ram_init_file = "program.mif" */;

// // for Sim only (quartus chokes on it, and also has different path from
// // modelsim)
// initial
// 	$readmemh("../../program.mem", memory);

always @(posedge clock)
		data = memory[addr];
endmodule
