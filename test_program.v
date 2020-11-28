module Test_Program_Memory;

reg[10:0] addr;
wire [15:0] data;
reg clock;

Program_Memory pm1(addr, data, clock);

initial
begin
	$dumpfile("test_program.vcd");
	$dumpvars;
	//$monitor($time, " addr = %H, data = %H", addr, data);
	clock = 1'b0;
	for (addr = 11'h0; addr < 11'h79; addr = addr + 1)
	begin
		clock = ~clock;
		#10 $display("addr = %H, data = %H", addr, data);
		clock = ~clock;
	end
end
endmodule
