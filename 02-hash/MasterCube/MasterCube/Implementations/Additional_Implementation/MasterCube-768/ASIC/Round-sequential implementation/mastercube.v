`timescale 1 ns / 1 ps

module mastercube #(
  parameter integer MAX_MSG_BYTES = 256,
  parameter integer FIXED_DIGEST_MODE = 1,
  parameter [1:0]   FIXED_DIGEST_SEL = 2'd2
) (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        start,
  input  wire [63:0] din,
  input  wire        din_valid,
  output wire        buffer_full,
  input  wire        last_block,
  input  wire [63:0] msg_bit_len,
  output wire        ready,
  output reg  [63:0] dout,
  output reg         dout_valid,
  input  wire [1:0]  digest_sel
);
  localparam [1:0] DIGEST_512        = 2'd1;
  localparam integer MSG_BYTES_WIDTH = (MAX_MSG_BYTES < 8) ? 4 :
                                       ((MAX_MSG_BYTES > 65535) ? 16 :
                                        $clog2(MAX_MSG_BYTES + 1));
  localparam [15:0] MAX_MSG_BYTES_16 = MAX_MSG_BYTES[15:0];
  localparam [MSG_BYTES_WIDTH-1:0] MAX_MSG_BYTES_CLAMPED = MAX_MSG_BYTES;

  localparam [4:0] ST_IDLE           = 5'd0;
  localparam [4:0] ST_CLEAR_ISSUE    = 5'd1;
  localparam [4:0] ST_CLEAR_WAIT     = 5'd2;
  localparam [4:0] ST_WAIT_WORD      = 5'd3;
  localparam [4:0] ST_ABSORB_ISSUE   = 5'd4;
  localparam [4:0] ST_ABSORB_WAIT    = 5'd5;
  localparam [4:0] ST_PAD80_ISSUE    = 5'd6;
  localparam [4:0] ST_PAD80_WAIT     = 5'd7;
  localparam [4:0] ST_PAD01_ISSUE    = 5'd8;
  localparam [4:0] ST_PAD01_WAIT     = 5'd9;
  localparam [4:0] ST_PERMUTE_ISSUE  = 5'd10;
  localparam [4:0] ST_PERMUTE_WAIT   = 5'd11;
  localparam [4:0] ST_SQUEEZE_PREP   = 5'd12;
  localparam [4:0] ST_READ_ISSUE     = 5'd13;
  localparam [4:0] ST_READ_WAIT      = 5'd14;
  localparam [4:0] ST_OUTPUT_WORD    = 5'd15;
  localparam [4:0] ST_DONE           = 5'd16;

  localparam [1:0] CMD_CLEAR         = 2'd0;
  localparam [1:0] CMD_XOR_BYTE      = 2'd1;
  localparam [1:0] CMD_READ_BYTE     = 2'd2;
  localparam [1:0] CMD_PERMUTE       = 2'd3;

  localparam [1:0] AFTER_WAIT_WORD   = 2'd0;
  localparam [1:0] AFTER_CUR_WORD    = 2'd1;
  localparam [1:0] AFTER_PAD         = 2'd2;
  localparam [1:0] AFTER_SQUEEZE     = 2'd3;

  reg  [4:0]  state_q;
  reg  [1:0]  digest_sel_q;
  reg  [MSG_BYTES_WIDTH-1:0] msg_bytes_left_q;
  reg  [6:0]  block_byte_ctr_q;
  reg  [1:0]  after_permute_q;
  reg  [6:0]  digest_pos_q;
  reg  [63:0] input_word_q;
  reg  [3:0]  input_bytes_q;

  reg         round_cmd_valid_w;
  reg  [1:0]  round_cmd_w;
  reg  [7:0]  round_byte_addr_w;
  reg  [7:0]  round_byte_data_w;
  reg         round_word64_valid_w;
  reg  [63:0] round_word_data_w;
  reg  [3:0]  next_input_bytes_w;
  reg  [7:0]  input_byte_w;
  reg  [MSG_BYTES_WIDTH-1:0] msg_len_bytes_calc_w;

  wire [15:0] msg_len_bytes_w;
  wire [7:0]  rate_bytes_w;
  wire [7:0]  digest_bytes_w;
  wire        round_accept_w;
  wire        round_ready_w;
  wire        round_done_w;
  wire [7:0]  round_byte_data_r_w;
  wire        digest_done_w;
  wire        word_byte_last_w;
  wire        block_byte_last_w;
  wire        word_absorb_fast_w;
  wire        block_word64_last_w;
  wire [1:0]  active_digest_sel_w;

  assign msg_len_bytes_w    = msg_bit_len[18:3] + {15'd0, |msg_bit_len[2:0]};
  assign digest_done_w      = ({1'b0, digest_pos_q} >= digest_bytes_w);
  assign word_byte_last_w   = (input_bytes_q == 4'd1);
  assign block_byte_last_w  = (({1'b0, block_byte_ctr_q} + 8'd1) >= rate_bytes_w);
  assign word_absorb_fast_w = (input_bytes_q == 4'd8) &&
                              (({1'b0, block_byte_ctr_q} + 8'd8) <= rate_bytes_w);
  assign block_word64_last_w = (({1'b0, block_byte_ctr_q} + 8'd8) >= rate_bytes_w);
  assign round_accept_w     = round_cmd_valid_w && round_ready_w;
  assign buffer_full        = (state_q != ST_WAIT_WORD);
  assign ready              = (state_q == ST_DONE);

  assign active_digest_sel_w = (FIXED_DIGEST_MODE != 0) ? FIXED_DIGEST_SEL :
                                                         digest_sel_q;
  assign rate_bytes_w   = active_digest_sel_w[1] ? (active_digest_sel_w[0] ? 8'd56  : 8'd88) : 8'd120;
  assign digest_bytes_w = active_digest_sel_w[1] ? (active_digest_sel_w[0] ? 8'd128 : 8'd96) : 8'd64;

  mastercube_round u_round (
    .clk_i       (clk),
    .rst_ni      (rst_n),
    .cmd_valid_i (round_cmd_valid_w),
    .cmd_i       (round_cmd_w),
    .byte_addr_i (round_byte_addr_w),
    .byte_data_i (round_byte_data_w),
    .word64_valid_i(round_word64_valid_w),
    .word_data_i (round_word_data_w),
    .ready_o     (round_ready_w),
    .done_o      (round_done_w),
    .byte_data_o (round_byte_data_r_w)
  );

  always @* begin
    msg_len_bytes_calc_w = msg_len_bytes_w[MSG_BYTES_WIDTH-1:0];
    if (msg_len_bytes_w > MAX_MSG_BYTES_16) begin
      msg_len_bytes_calc_w = MAX_MSG_BYTES_CLAMPED;
    end
  end

  always @* begin
    if (msg_bytes_left_q > 8) begin
      next_input_bytes_w = 4'd8;
    end
    else begin
      next_input_bytes_w = msg_bytes_left_q[3:0];
    end
  end

  always @* begin
    input_byte_w = input_word_q[7:0];
  end

  always @* begin
    round_cmd_valid_w = 1'b0;
    round_cmd_w       = CMD_CLEAR;
    round_byte_addr_w = 8'd0;
    round_byte_data_w = 8'd0;
    round_word64_valid_w = 1'b0;
    round_word_data_w = 64'd0;

    case (state_q)
      ST_CLEAR_ISSUE : begin
        round_cmd_valid_w = 1'b1;
        round_cmd_w       = CMD_CLEAR;
      end

      ST_ABSORB_ISSUE : begin
        round_cmd_valid_w = 1'b1;
        round_cmd_w       = CMD_XOR_BYTE;
        round_byte_addr_w = {1'b0, block_byte_ctr_q};
        round_byte_data_w = input_byte_w;
        round_word64_valid_w = word_absorb_fast_w;
        round_word_data_w = input_word_q;
      end

      ST_PAD80_ISSUE : begin
        round_cmd_valid_w = 1'b1;
        round_cmd_w       = CMD_XOR_BYTE;
        round_byte_addr_w = {1'b0, block_byte_ctr_q};
        round_byte_data_w = 8'h80;
      end

      ST_PAD01_ISSUE : begin
        round_cmd_valid_w = 1'b1;
        round_cmd_w       = CMD_XOR_BYTE;
        round_byte_addr_w = rate_bytes_w - 8'd1;
        round_byte_data_w = 8'h01;
      end

      ST_PERMUTE_ISSUE : begin
        round_cmd_valid_w = 1'b1;
        round_cmd_w       = CMD_PERMUTE;
      end

      ST_READ_ISSUE : begin
        round_cmd_valid_w = 1'b1;
        round_cmd_w       = CMD_READ_BYTE;
        round_byte_addr_w = {1'b0, block_byte_ctr_q};
      end

      default : begin
      end
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q             <= ST_IDLE;
      digest_sel_q        <= DIGEST_512;
      dout_valid          <= 1'b0;
    end
    else begin
      dout_valid <= 1'b0;

      case (state_q)
        ST_IDLE : begin
          if (start) begin
            state_q             <= ST_CLEAR_ISSUE;
            digest_sel_q        <= (FIXED_DIGEST_MODE != 0) ? FIXED_DIGEST_SEL :
                                                              digest_sel;
            msg_bytes_left_q    <= msg_len_bytes_calc_w;
            block_byte_ctr_q    <= 7'd0;
            after_permute_q     <= AFTER_WAIT_WORD;
            digest_pos_q        <= 7'd0;
            input_word_q        <= 64'd0;
            input_bytes_q       <= 4'd0;
            dout                <= 64'd0;
          end
        end

        ST_CLEAR_ISSUE : begin
          if (round_accept_w) begin
            state_q <= ST_CLEAR_WAIT;
          end
        end

        ST_CLEAR_WAIT : begin
          if (round_done_w) begin
            block_byte_ctr_q <= 7'd0;
            if (msg_bytes_left_q == 16'd0) begin
              state_q <= ST_PAD80_ISSUE;
            end
            else begin
              state_q <= ST_WAIT_WORD;
            end
          end
        end

        ST_WAIT_WORD : begin
          if (din_valid) begin
            input_word_q      <= din;
            input_bytes_q     <= next_input_bytes_w;
            msg_bytes_left_q  <= msg_bytes_left_q - next_input_bytes_w;
            state_q           <= ST_ABSORB_ISSUE;
          end
        end

        ST_ABSORB_ISSUE : begin
          if (round_accept_w) begin
            state_q <= ST_ABSORB_WAIT;
          end
        end

      ST_ABSORB_WAIT : begin
        if (round_done_w) begin
            if (word_absorb_fast_w) begin
              if (block_word64_last_w) begin
                block_byte_ctr_q <= 7'd0;

                if (msg_bytes_left_q == 16'd0) begin
                  after_permute_q <= AFTER_PAD;
                end
                else begin
                  after_permute_q <= AFTER_WAIT_WORD;
                end

                state_q <= ST_PERMUTE_ISSUE;
              end
              else begin
                block_byte_ctr_q <= block_byte_ctr_q + 7'd8;
                if (msg_bytes_left_q == 16'd0) begin
                  state_q <= ST_PAD80_ISSUE;
                end
                else begin
                  state_q <= ST_WAIT_WORD;
                end
              end
            end
            else if (block_byte_last_w) begin
              block_byte_ctr_q <= 7'd0;

              if (word_byte_last_w) begin
                if (msg_bytes_left_q == 16'd0) begin
                  after_permute_q <= AFTER_PAD;
                end
                else begin
                  after_permute_q <= AFTER_WAIT_WORD;
                end
              end
              else begin
                input_word_q     <= {8'd0, input_word_q[63:8]};
                input_bytes_q    <= input_bytes_q - 4'd1;
                after_permute_q  <= AFTER_CUR_WORD;
              end

              state_q <= ST_PERMUTE_ISSUE;
            end
            else begin
              block_byte_ctr_q <= block_byte_ctr_q + 7'd1;

              if (word_byte_last_w) begin
                if (msg_bytes_left_q == 16'd0) begin
                  state_q <= ST_PAD80_ISSUE;
                end
                else begin
                  state_q <= ST_WAIT_WORD;
                end
              end
              else begin
                input_word_q  <= {8'd0, input_word_q[63:8]};
                input_bytes_q <= input_bytes_q - 4'd1;
                state_q       <= ST_ABSORB_ISSUE;
              end
            end
          end
        end

        ST_PAD80_ISSUE : begin
          if (round_accept_w) begin
            state_q <= ST_PAD80_WAIT;
          end
        end

        ST_PAD80_WAIT : begin
          if (round_done_w) begin
            state_q <= ST_PAD01_ISSUE;
          end
        end

        ST_PAD01_ISSUE : begin
          if (round_accept_w) begin
            state_q <= ST_PAD01_WAIT;
          end
        end

        ST_PAD01_WAIT : begin
          if (round_done_w) begin
            after_permute_q <= AFTER_SQUEEZE;
            state_q        <= ST_PERMUTE_ISSUE;
          end
        end

        ST_PERMUTE_ISSUE : begin
          if (round_accept_w) begin
            state_q <= ST_PERMUTE_WAIT;
          end
        end

        ST_PERMUTE_WAIT : begin
          if (round_done_w) begin
            block_byte_ctr_q <= 7'd0;
            dout             <= 64'd0;

            case (after_permute_q)
              AFTER_CUR_WORD : state_q <= ST_ABSORB_ISSUE;
              AFTER_PAD      : state_q <= ST_PAD80_ISSUE;
              AFTER_SQUEEZE  : state_q <= ST_SQUEEZE_PREP;
              default        : state_q <= ST_WAIT_WORD;
            endcase
          end
        end

        ST_SQUEEZE_PREP : begin
          block_byte_ctr_q <= 7'd0;
          dout             <= 64'd0;
          if (digest_done_w) begin
            state_q <= ST_DONE;
          end
          else begin
            state_q <= ST_READ_ISSUE;
          end
        end

        ST_READ_ISSUE : begin
          if (round_accept_w) begin
            if (block_byte_ctr_q[2:0] == 3'd0) begin
              dout <= 64'd0;
            end
            state_q <= ST_READ_WAIT;
          end
        end

        ST_READ_WAIT : begin
          if (round_done_w) begin
            dout[(block_byte_ctr_q[2:0] * 8) +: 8] <= round_byte_data_r_w;
            if (block_byte_ctr_q[2:0] == 3'd7) begin
              state_q <= ST_OUTPUT_WORD;
            end
            else begin
              block_byte_ctr_q <= block_byte_ctr_q + 7'd1;
              state_q          <= ST_READ_ISSUE;
            end
          end
        end

        ST_OUTPUT_WORD : begin
          dout_valid   <= 1'b1;
          digest_pos_q <= digest_pos_q + 7'd8;

          if ((digest_pos_q + 8'd8) >= digest_bytes_w) begin
            state_q <= ST_DONE;
          end
          else if (({1'b0, block_byte_ctr_q} + 8'd1) >= rate_bytes_w) begin
            block_byte_ctr_q <= 7'd0;
            after_permute_q  <= AFTER_SQUEEZE;
            state_q          <= ST_PERMUTE_ISSUE;
          end
          else begin
            block_byte_ctr_q <= block_byte_ctr_q + 7'd1;
            state_q          <= ST_READ_ISSUE;
          end
        end

        ST_DONE : begin
          if (start) begin
            state_q             <= ST_CLEAR_ISSUE;
            digest_sel_q        <= (FIXED_DIGEST_MODE != 0) ? FIXED_DIGEST_SEL :
                                                              digest_sel;
            msg_bytes_left_q    <= msg_len_bytes_calc_w;
            block_byte_ctr_q    <= 7'd0;
            after_permute_q     <= AFTER_WAIT_WORD;
            digest_pos_q        <= 7'd0;
            input_word_q        <= 64'd0;
            input_bytes_q       <= 4'd0;
            dout                <= 64'd0;
          end
        end

        default : begin
          state_q <= ST_IDLE;
        end
      endcase
    end
  end
endmodule


