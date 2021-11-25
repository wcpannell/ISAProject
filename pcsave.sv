// PC Save register.
// Stores return value during interrupt.
// Saved value is stored until overwritten.

`default_nettype none

module PC_Save(
  input var logic[10:0] addr,
  input var logic write_enable,
  output var logic[10:0] saved
);

// initial
//   saved = 11'h0; // initialize pointing to reset vector

always_latch begin
  if (write_enable) saved <= addr;
end

endmodule
