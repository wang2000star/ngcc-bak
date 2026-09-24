module hash_top (
    input  wire          clk,
    input  wire          rst_n,

    // start a new hashing process
    input  wire          start,

    // padded input blocks
    input  wire          block_valid,
    input  wire [1279:0] block_in,
    input  wire          block_last,

    // output
    output reg  [383:0]  digest,
    output reg           done,
    output reg           busy,
    output reg           ready
);

    localparam RATE        = 1280;
    localparam STATE_SIZE  = 2048;
    localparam DIGEST_SIZE = 384;
    localparam NUM_ROUNDS  = 20;

    localparam S_IDLE    = 2'd0;
    localparam S_ABSORB  = 2'd1;
    localparam S_PERMUTE = 2'd2;

    reg [1:0] state_ctrl;

    reg  [STATE_SIZE-1:0] state_reg;
    wire [STATE_SIZE-1:0] state_next;

    reg  [4:0] round_id;
    reg        last_block_reg;

    round u_round (
        .state_in  (state_reg),
        .round_id  (round_id),
        .state_out (state_next)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_ctrl     <= S_IDLE;
            state_reg      <= {STATE_SIZE{1'b0}};
            round_id       <= 5'd0;
            last_block_reg <= 1'b0;

            digest         <= {DIGEST_SIZE{1'b0}};
            done           <= 1'b0;
            busy           <= 1'b0;
            ready          <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state_ctrl)

                // ---------------------------------------------------------
                // Wait for a new hash computation.
                // ---------------------------------------------------------
                S_IDLE: begin
                    busy  <= 1'b0;
                    ready <= 1'b0;

                    if (start) begin
                        state_reg      <= {STATE_SIZE{1'b0}};
                        round_id       <= 5'd0;
                        last_block_reg <= 1'b0;

                        busy           <= 1'b1;
                        ready          <= 1'b1;
                        state_ctrl     <= S_ABSORB;
                    end
                end

                // ---------------------------------------------------------
                // Absorb one already-padded full-rate block.
                // The input block must be valid only when ready = 1.
                // ---------------------------------------------------------
                S_ABSORB: begin
                    busy  <= 1'b1;
                    ready <= 1'b1;

                    if (block_valid) begin
                        // Sponge absorbing:
                        // state[rate-1:0] ^= block_in
                        state_reg[RATE-1:0] <= state_reg[RATE-1:0] ^ block_in;

                        last_block_reg <= block_last;
                        round_id       <= 5'd0;

                        ready          <= 1'b0;
                        state_ctrl     <= S_PERMUTE;
                    end
                end

                // ---------------------------------------------------------
                // Apply the permutation, one round per clock cycle.
                // ---------------------------------------------------------
                S_PERMUTE: begin
                    busy  <= 1'b1;
                    ready <= 1'b0;

                    state_reg <= state_next;

                    if (round_id == NUM_ROUNDS - 1) begin
                        round_id <= 5'd0;

                        if (last_block_reg) begin
                            digest     <= state_next[DIGEST_SIZE-1:0];
                            done       <= 1'b1;
                            busy       <= 1'b0;
                            ready      <= 1'b0;
                            state_ctrl <= S_IDLE;
                        end else begin
                            ready      <= 1'b1;
                            state_ctrl <= S_ABSORB;
                        end
                    end else begin
                        round_id <= round_id + 5'd1;
                    end
                end

                default: begin
                    state_ctrl <= S_IDLE;
                    busy       <= 1'b0;
                    ready      <= 1'b0;
                    done       <= 1'b0;
                    round_id   <= 5'd0;
                end

            endcase
        end
    end

endmodule