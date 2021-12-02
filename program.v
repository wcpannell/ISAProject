module Program_Memory(
	input[10:0] addr,
	output reg[15:0] data,
	input clock
);

//reg[15:0] memory[0:511] /* synthesis ram_init_file = "program.mif" */;
reg[15:0] memory[0:511];

// for Sim only (quartus chokes on it, and also has different path from
// modelsim)
initial
	$readmemh("/home/asx/class/2021Fall/CPE523/project/verilog/program.mem", memory);

always @(posedge clock)
		data = memory[addr];
endmodule
