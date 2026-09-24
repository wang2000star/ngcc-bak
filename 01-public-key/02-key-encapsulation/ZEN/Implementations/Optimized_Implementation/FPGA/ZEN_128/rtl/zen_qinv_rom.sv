module zen_qinv_rom (
  input  logic [9:0]  addr,
  output logic [15:0] data
);

  import zen_accel_pkg::*;

  logic [15:0] qinv_rom [0:ZEN_Q-1];
  integer i;

  function automatic [15:0] inv_mod_q(input integer x);
    integer k;
    begin
      inv_mod_q = 16'd0;
      if (x == 0) begin
        inv_mod_q = 16'd0;
      end else begin
        for (k = 1; k < ZEN_Q; k = k + 1) begin
          if (((x * k) % ZEN_Q) == 1) begin
            inv_mod_q = k[15:0];
          end
        end
      end
    end
  endfunction

  initial begin
    for (i = 0; i < ZEN_Q; i = i + 1) begin
      qinv_rom[i] = inv_mod_q(i);
    end
  end

  always_comb begin
    if (addr < ZEN_Q) begin
      data = qinv_rom[addr];
    end else begin
      data = 16'd0;
    end
  end

endmodule
