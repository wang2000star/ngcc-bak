//======================================================================
//
// cuishen.v
// ---------
// Top level wrapper for the Cuishen-512 hash function providing a
// simple memory-like interface with 32-bit data access. Modelled on
// sha512.v.
//
// Register map (32-bit words):
//   0x00 NAME0      (ro)
//   0x01 NAME1      (ro)
//   0x02 VERSION    (ro)
//   0x08 CTRL       : bit0 = init, bit1 = next, bit2 = final
//   0x09 STATUS     : bit0 = ready, bit1 = digest_valid
//   0x0a..0x0b      COUNTER (64-bit, low word at 0x0a)
//   0x10..0x2f      BLOCK   (32 x 32-bit = 1024-bit message block)
//   0x30..0x47      TAIL    (24 x 32-bit = 768-bit finalization tail)
//   0x60..0x6f      DIGEST  (16 x 32-bit = 512-bit digest, ro)
//
//======================================================================

`default_nettype none

module cuishen(
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
  localparam ADDR_NAME0    = 8'h00;
  localparam ADDR_NAME1    = 8'h01;
  localparam ADDR_VERSION  = 8'h02;

  localparam ADDR_CTRL     = 8'h08;
  localparam CTRL_INIT_BIT  = 0;
  localparam CTRL_NEXT_BIT  = 1;
  localparam CTRL_FINAL_BIT = 2;

  localparam ADDR_STATUS   = 8'h09;
  localparam STATUS_READY_BIT = 0;
  localparam STATUS_VALID_BIT = 1;

  localparam ADDR_COUNTER0 = 8'h0a; // low  32 bits of counter
  localparam ADDR_COUNTER1 = 8'h0b; // high 32 bits of counter

  localparam ADDR_BLOCK0   = 8'h10;
  localparam ADDR_BLOCK31  = 8'h2f;

  localparam ADDR_TAIL0    = 8'h30;
  localparam ADDR_TAIL23   = 8'h47;

  localparam ADDR_DIGEST0  = 8'h60;
  localparam ADDR_DIGEST15 = 8'h6f;

  localparam CORE_NAME0    = 32'h63756973; // "cuis"
  localparam CORE_NAME1    = 32'h68656e35; // "hen5"
  localparam CORE_VERSION  = 32'h302e3730; // "0.70"


  //----------------------------------------------------------------
  // Registers.
  //----------------------------------------------------------------
  reg          init_reg;
  reg          init_new;
  reg          next_reg;
  reg          next_new;
  reg          final_reg;
  reg          final_new;

  reg [31 : 0] block_reg [0 : 31];
  reg          block_we;

  reg [31 : 0] tail_reg [0 : 23];
  reg          tail_we;

  reg [63 : 0] counter_reg;
  reg          counter0_we;
  reg          counter1_we;

  reg [511 : 0] digest_reg;
  reg           digest_valid_reg;
  reg           ready_reg;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire           core_ready;
  wire [1023 : 0] core_block;
  wire [767 : 0]  core_tail;
  wire [511 : 0]  core_digest;
  wire            core_digest_valid;

  reg [5 : 0]    block_addr;
  reg [4 : 0]    tail_addr;
  reg [31 : 0]   tmp_read_data;
  reg            tmp_error;


  //----------------------------------------------------------------
  // Concurrent connectivity.
  //----------------------------------------------------------------
  assign core_block = {block_reg[00], block_reg[01], block_reg[02], block_reg[03],
                       block_reg[04], block_reg[05], block_reg[06], block_reg[07],
                       block_reg[08], block_reg[09], block_reg[10], block_reg[11],
                       block_reg[12], block_reg[13], block_reg[14], block_reg[15],
                       block_reg[16], block_reg[17], block_reg[18], block_reg[19],
                       block_reg[20], block_reg[21], block_reg[22], block_reg[23],
                       block_reg[24], block_reg[25], block_reg[26], block_reg[27],
                       block_reg[28], block_reg[29], block_reg[30], block_reg[31]};

  assign core_tail = {tail_reg[00], tail_reg[01], tail_reg[02], tail_reg[03],
                      tail_reg[04], tail_reg[05], tail_reg[06], tail_reg[07],
                      tail_reg[08], tail_reg[09], tail_reg[10], tail_reg[11],
                      tail_reg[12], tail_reg[13], tail_reg[14], tail_reg[15],
                      tail_reg[16], tail_reg[17], tail_reg[18], tail_reg[19],
                      tail_reg[20], tail_reg[21], tail_reg[22], tail_reg[23]};

  assign read_data = tmp_read_data;
  assign error     = tmp_error;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  cuishen_core core(
                    .clk(clk),
                    .reset_n(reset_n),

                    .init(init_reg),
                    .next(next_reg),
                    .finalize(final_reg),

                    .block(core_block),
                    .counter_bits(counter_reg),
                    .tail_words(core_tail),

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
          for (i = 0 ; i < 32 ; i = i + 1)
            block_reg[i] <= 32'h0;
          for (i = 0 ; i < 24 ; i = i + 1)
            tail_reg[i] <= 32'h0;

          init_reg         <= 1'h0;
          next_reg         <= 1'h0;
          final_reg        <= 1'h0;
          counter_reg      <= 64'h0;
          ready_reg        <= 1'h0;
          digest_reg       <= 512'h0;
          digest_valid_reg <= 1'h0;
        end
      else
        begin
          ready_reg        <= core_ready;
          digest_valid_reg <= core_digest_valid;
          init_reg         <= init_new;
          next_reg         <= next_new;
          final_reg        <= final_new;

          if (core_digest_valid)
            digest_reg <= core_digest;

          if (block_we)
            block_reg[block_addr] <= write_data;

          if (tail_we)
            tail_reg[tail_addr] <= write_data;

          if (counter0_we)
            counter_reg[31 : 0] <= write_data;

          if (counter1_we)
            counter_reg[63 : 32] <= write_data;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api_logic
  //----------------------------------------------------------------
  always @*
    begin : api_logic
      init_new      = 1'h0;
      next_new      = 1'h0;
      final_new     = 1'h0;
      block_we      = 1'h0;
      tail_we       = 1'h0;
      counter0_we   = 1'h0;
      counter1_we   = 1'h0;
      tmp_read_data = 32'h0;
      tmp_error     = 1'h0;

      block_addr = address[5 : 0] - ADDR_BLOCK0[5 : 0];
      tail_addr  = address[4 : 0] - ADDR_TAIL0[4 : 0];

      if (cs)
        begin
          if (we)
            begin
              if ((address >= ADDR_BLOCK0) && (address <= ADDR_BLOCK31))
                block_we = 1'h1;

              if ((address >= ADDR_TAIL0) && (address <= ADDR_TAIL23))
                tail_we = 1'h1;

              case (address)
                ADDR_CTRL:
                  begin
                    init_new  = write_data[CTRL_INIT_BIT];
                    next_new  = write_data[CTRL_NEXT_BIT];
                    final_new = write_data[CTRL_FINAL_BIT];
                  end

                ADDR_COUNTER0:
                  counter0_we = 1'h1;

                ADDR_COUNTER1:
                  counter1_we = 1'h1;

                default:
                  begin
                  end
              endcase // case (address)
            end // if (we)

          else
            begin
              if ((address >= ADDR_DIGEST0) && (address <= ADDR_DIGEST15))
                tmp_read_data = digest_reg[(15 - (address - ADDR_DIGEST0)) * 32 +: 32];

              if ((address >= ADDR_BLOCK0) && (address <= ADDR_BLOCK31))
                tmp_read_data = block_reg[block_addr];

              if ((address >= ADDR_TAIL0) && (address <= ADDR_TAIL23))
                tmp_read_data = tail_reg[tail_addr];

              case (address)
                ADDR_NAME0:    tmp_read_data = CORE_NAME0;
                ADDR_NAME1:    tmp_read_data = CORE_NAME1;
                ADDR_VERSION:  tmp_read_data = CORE_VERSION;
                ADDR_CTRL:     tmp_read_data = {29'h0, final_reg, next_reg, init_reg};
                ADDR_STATUS:   tmp_read_data = {30'h0, digest_valid_reg, ready_reg};
                ADDR_COUNTER0: tmp_read_data = counter_reg[31 : 0];
                ADDR_COUNTER1: tmp_read_data = counter_reg[63 : 32];
                default:
                  begin
                  end
              endcase // case (address)
            end
        end
    end // api_logic
endmodule // cuishen

//======================================================================
// EOF cuishen.v
//======================================================================
