ISA : ISA.v add.v alu.v clock.v decoder.v memory.v mux.v pcsave.v program.v programcounter.v signextend.v wreg.v
	iverilog -Wall -g2012 -o $@ $^ -s Simulate_All

test_alu : alu.v test_alu.v
	iverilog -Wall -g2012 -o $@ $^

test_decoder : test_decoder.v decoder.v
	iverilog -Wall -g2012 -o $@ $^

test_memory : test_memory.v memory.v clock.v wreg.v
	iverilog -Wall -g2012 -o $@ $^

test_mux : test_mux.v mux.v
	iverilog -Wall -g2012 -o $@ $^

test_pcsave : test_pcsave.v pcsave.v
	iverilog -Wall -g2012 -o $@ $^

test_program : test_program.v program.v
	iverilog -Wall -g2012 -o $@ $^

.PHONY: docs
docs:
	$(MAKE) -C docs

.PHONY: clean
clean:
	rm -f *.vcd ISA test_alu test_decoder test_memory test_mux test_pcsave test_program docs.pdf

.PHONY: run
run: ISA
	./ISA

.PHONY: all
all: ISA test_alu test_decoder test_memory test_mux test_pcsave test_program
