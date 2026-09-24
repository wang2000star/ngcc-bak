//======================================================================
//
// duet_1024.v
// ------------
// Top level wrapper for the Duet-1024 hash function providing a simple
// memory-like interface with 32-bit data access. Modelled directly on
// duet.v (Duet-512) and duet_768.v (Duet-768).
//
// Register map (32-bit words):
//   0x00 NAME0      (ro)
//   0x01 NAME1      (ro)
//   0x02 VERSION    (ro)
//   0x08 CTRL       : bit0 = init, bit1 = absorb
//   0x09 STATUS     : bit0 = ready, bit1 = digest_valid
//   0x10..0x27      BLOCK   (24 x 32-bit = 768-bit message block, MSB word first)
//   0x40..0x5f      DIGEST  (32 x 32-bit = 1024-bit digest, ro)
//
// The host is responsible for padding the final message block exactly
// as pad_message_block() does in the C reference (M || 1 || 0^k) before
// writing it through BLOCK0..BLOCK23, and pulsing CTRL.absorb; this
// mirrors how the Duet-512/Duet-768 wrappers expect a pre-padded tail
// block from the host rather than padding in hardware.
//
//======================================================================

`default_nettype none

module duet_1024(
            input wire           clk,
            input wire           reset_n,

            input wire           cs,
            input wire           we,

            input wire  [7 : 0]  address,
            input wire  [31 : 0] write_data,
            output wire [31 : 0] read_data,
            output wire          error
           );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_NAME0   = 8'h00;
  localparam ADDR_NAME1   = 8'h01;
  localparam ADDR_VERSION = 8'h02;

  localparam ADDR_CTRL      = 8'h08;
  localparam CTRL_INIT_BIT   = 0;
  localparam CTRL_ABSORB_BIT = 1;

  localparam ADDR_STATUS      = 8'h09;
  localparam STATUS_READY_BIT = 0;
  localparam STATUS_VALID_BIT = 1;

  localparam ADDR_BLOCK0  = 8'h10;
  localparam ADDR_BLOCK_LAST = 8'h27;

  localparam ADDR_DIGEST0  = 8'h40;
  localparam ADDR_DIGEST_LAST = 8'h5f;

  localparam CORE_NAME0   = 32'h64756574; // "duet"
  localparam CORE_NAME1   = 32'h2d313032; // "-102"
  localparam CORE_VERSION = 32'h302e3031; // "0.01"


  //----------------------------------------------------------------
  // Registers.
  //----------------------------------------------------------------
  reg          init_reg;
  reg          init_new;
  reg          absorb_reg;
  reg          absorb_new;

  reg [31 : 0] block_reg [0 : 23];
  reg          block_we;

  reg [1023 : 0] digest_reg;
  reg           digest_valid_reg;
  reg           ready_reg;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire           core_ready;
  wire [767 : 0] core_block;
  wire [1023 : 0] core_digest;
  wire           core_digest_valid;

  reg [5 : 0]    block_addr;
  reg [31 : 0]   tmp_read_data;
  reg            tmp_error;


  //----------------------------------------------------------------
  // Concurrent connectivity.
  //----------------------------------------------------------------
  assign core_block = {
                       block_reg[00], block_reg[01], block_reg[02], block_reg[03],
                       block_reg[04], block_reg[05], block_reg[06], block_reg[07],
                       block_reg[08], block_reg[09], block_reg[10], block_reg[11],
                       block_reg[12], block_reg[13], block_reg[14], block_reg[15],
                       block_reg[16], block_reg[17], block_reg[18], block_reg[19],
                       block_reg[20], block_reg[21], block_reg[22], block_reg[23]};

  assign read_data = tmp_read_data;
  assign error     = tmp_error;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  duet_core_1024 core(
                .clk(clk),
                .reset_n(reset_n),

                .init(init_reg),
                .absorb(absorb_reg),

                .block(core_block),

                .ready(core_ready),
                .digest(core_digest),
                .digest_valid(core_digest_valid)
               );


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < 24 ; i = i + 1)
            block_reg[i] <= 32'h0;

          init_reg         <= 1'h0;
          absorb_reg       <= 1'h0;
          ready_reg        <= 1'h0;
          digest_reg       <= 1024'h0;
          digest_valid_reg <= 1'h0;
        end
      else
        begin
          ready_reg        <= core_ready;
          digest_valid_reg <= core_digest_valid;
          init_reg         <= init_new;
          absorb_reg       <= absorb_new;

          if (core_digest_valid)
            digest_reg <= core_digest;

          if (block_we)
            block_reg[block_addr] <= write_data;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api_logic
  //----------------------------------------------------------------
  always @*
    begin : api_logic
      init_new      = 1'h0;
      absorb_new    = 1'h0;
      block_we      = 1'h0;
      tmp_read_data = 32'h0;
      tmp_error     = 1'h0;

      block_addr = address[5 : 0] - ADDR_BLOCK0[5 : 0];

      if (cs)
        begin
          if (we)
            begin
              if ((address >= ADDR_BLOCK0) && (address <= ADDR_BLOCK_LAST))
                block_we = 1'h1;

              case (address)
                ADDR_CTRL:
                  begin
                    init_new   = write_data[CTRL_INIT_BIT];
                    absorb_new = write_data[CTRL_ABSORB_BIT];
                  end

                default:
                  begin
                  end
              endcase // case (address)
            end // if (we)

          else
            begin
              if ((address >= ADDR_DIGEST0) && (address <= ADDR_DIGEST_LAST))
                tmp_read_data = digest_reg[(31 - (address - ADDR_DIGEST0)) * 32 +: 32];

              if ((address >= ADDR_BLOCK0) && (address <= ADDR_BLOCK_LAST))
                tmp_read_data = block_reg[block_addr];

              case (address)
                ADDR_NAME0:   tmp_read_data = CORE_NAME0;
                ADDR_NAME1:   tmp_read_data = CORE_NAME1;
                ADDR_VERSION: tmp_read_data = CORE_VERSION;
                ADDR_CTRL:    tmp_read_data = {30'h0, absorb_reg, init_reg};
                ADDR_STATUS:  tmp_read_data = {30'h0, digest_valid_reg, ready_reg};
                default:
                  begin
                  end
              endcase // case (address)
            end
        end
    end // api_logic
endmodule // duet_1024

//======================================================================
// EOF duet_1024.v
//======================================================================
