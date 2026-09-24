module hash_top (
    input  wire          clk,
    input  wire          rst_n,

    input  wire          start,

    input  wire          block_valid,
    input  wire [1215:0] block_in,
    input  wire          block_last,

    output reg  [767:0]  digest,
    output reg           done,
    output reg           busy,
    output reg           ready
);

    localparam RATE        = 1216;
    localparam STATE_SIZE  = 2048;
    localparam DIGEST_SIZE = 768;
    localparam NUM_ROUNDS  = 24;

    localparam S_IDLE    = 2'd0;
    localparam S_ABSORB  = 2'd1;
    localparam S_PERMUTE = 2'd2;

    reg [1:0] state_ctrl;

    reg  [STATE_SIZE-1:0] state_reg;
    wire [STATE_SIZE-1:0] state_next;

    reg  [STATE_SIZE-1:0] feedforward_reg;
    wire [STATE_SIZE-1:0] absorb_mask;
    wire [STATE_SIZE-1:0] absorbed_state;
    wire [STATE_SIZE-1:0] ff_state_next;

    reg [4:0] round_id;
    reg       last_block_reg;

    round u_round (
        .state_in  (state_reg),
        .round_id  (round_id),
        .state_out (state_next)
    );

    assign absorb_mask =
        block_last ? {824'd0, 1'b1, 7'd0, block_in} :
                     {832'd0,       block_in};

    assign absorbed_state = state_reg ^ absorb_mask;

    assign ff_state_next = state_next ^ feedforward_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_ctrl      <= S_IDLE;
            state_reg       <= {STATE_SIZE{1'b0}};
            feedforward_reg <= {STATE_SIZE{1'b0}};
            round_id        <= 5'd0;
            last_block_reg  <= 1'b0;

            digest          <= {DIGEST_SIZE{1'b0}};
            done            <= 1'b0;
            busy            <= 1'b0;
            ready           <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state_ctrl)

                S_IDLE: begin
                    busy  <= 1'b0;
                    ready <= 1'b0;

                    if (start) begin
                        state_reg       <= {STATE_SIZE{1'b0}};
                        feedforward_reg <= {STATE_SIZE{1'b0}};
                        round_id        <= 5'd0;
                        last_block_reg  <= 1'b0;

                        busy            <= 1'b1;
                        ready           <= 1'b1;
                        state_ctrl      <= S_ABSORB;
                    end
                end

                S_ABSORB: begin
                    busy  <= 1'b1;
                    ready <= 1'b1;

                    if (block_valid) begin
                        state_reg <= absorbed_state;

                        feedforward_reg <= {
                            absorbed_state[STATE_SIZE-1:RATE],
                            {RATE{1'b0}}
                        };

                        last_block_reg <= block_last;
                        round_id       <= 5'd0;

                        ready          <= 1'b0;
                        state_ctrl     <= S_PERMUTE;
                    end
                end

                S_PERMUTE: begin
                    busy  <= 1'b1;
                    ready <= 1'b0;

                    if (round_id == NUM_ROUNDS - 1) begin
                        state_reg <= ff_state_next;
                        round_id  <= 5'd0;

                        if (last_block_reg) begin
                            digest     <= ff_state_next[STATE_SIZE-1 -: DIGEST_SIZE];
                            done       <= 1'b1;
                            busy       <= 1'b0;
                            ready      <= 1'b0;
                            state_ctrl <= S_IDLE;
                        end else begin
                            ready      <= 1'b1;
                            state_ctrl <= S_ABSORB;
                        end
                    end else begin
                        state_reg <= state_next;
                        round_id  <= round_id + 5'd1;
                    end
                end

                default: begin
                    state_ctrl      <= S_IDLE;
                    state_reg       <= {STATE_SIZE{1'b0}};
                    feedforward_reg <= {STATE_SIZE{1'b0}};
                    round_id        <= 5'd0;
                    last_block_reg  <= 1'b0;

                    digest          <= {DIGEST_SIZE{1'b0}};
                    done            <= 1'b0;
                    busy            <= 1'b0;
                    ready           <= 1'b0;
                end

            endcase
        end
    end

endmodule