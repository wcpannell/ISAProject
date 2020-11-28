module test_PC_Save;
reg[10:0] addr;
reg write;
wire[10:0] saved;

PC_Save pc_save(addr, write, saved);

initial
begin
	$dumpfile("pcsave.vcd");
	$dumpvars;
	$monitor ($time, ": addr %d, write %b, saved %d", addr, write, saved);
	write = 1'b0;
	for (addr = 0; addr < 100; addr = addr + 10)
		#10 write = ~write;
	#10 $finish;
end
endmodule

