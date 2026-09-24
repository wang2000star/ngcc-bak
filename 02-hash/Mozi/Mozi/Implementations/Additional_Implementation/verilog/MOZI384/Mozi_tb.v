`timescale 1ns / 1ps

module tb_hash_top;

    reg          clk;
    reg          rst_n;
    reg          start;

    reg          block_valid;
    reg [1279:0] block_in;
    reg          block_last;

    wire [383:0] digest;
    wire         done;
    wire         busy;
    wire         ready;

    integer i;

    hash_top uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),

        .block_valid (block_valid),
        .block_in    (block_in),
        .block_last  (block_last),

        .digest      (digest),
        .done        (done),
        .busy        (busy),
        .ready       (ready)
    );

    task print_lanes_128;
        input [2047:0] s;
        integer x;
        integer y;
        integer idx;
        begin
            for (x = 0; x < 4; x = x + 1) begin
                for (y = 0; y < 4; y = y + 1) begin
                    idx = x * 4 + y;
                    $display("lane[%0d][%0d] = 0x%032h",
                             x, y, s[128*idx +: 128]);
                end
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n       = 1'b0;
        start       = 1'b0;
        block_valid = 1'b0;
        block_last  = 1'b0;

        // 对应 C 代码中空消息 padding:
        // padded_input[0] = 8'h80, padded_input[1..159] = 0
        // 若 state[j] <=> state_reg[8*j +: 8]，则写成 1280'h80
        block_in = 1280'h80;

        #30;
        rst_n = 1'b1;

        // 启动一次新的 hash
        @(posedge clk);
        start = 1'b1;

        @(posedge clk);
        start = 1'b0;

        // 等待 hash_top 进入 ABSORB 状态并准备好接收 block
        wait(ready == 1'b1);

        @(posedge clk);
        block_valid = 1'b1;
        block_last  = 1'b1;   // 只有一块，所以这一块就是最后一块

        @(posedge clk);
        block_valid = 1'b0;
        block_last  = 1'b0;

        wait(done == 1'b1);

        #20;
        $finish;
    end

    always @(posedge clk) begin
        if (rst_n) begin

            if (start && !busy) begin
                $display("====================================");
                $display("Start hash");
                $display("block_in = 0x%0320h", block_in);
                $display("====================================");
            end

            if (block_valid && ready) begin
                $display("====================================");
                $display("Absorb block");
                $display("block_last = %0d", block_last);
                $display("block_in = 0x%0320h", block_in);

                $display("State before absorb lanes:");
                print_lanes_128(uut.state_reg);

                $display("State after absorb lanes:");
                print_lanes_128({
                    uut.state_reg[2047:1280],
                    uut.state_reg[1279:0] ^ block_in
                });

                $display("====================================");
            end

            if (uut.state_ctrl == uut.S_PERMUTE) begin
                $display("------------------------------------");
                $display("Round %0d", uut.round_id);

                $display("state_in lanes:");
                print_lanes_128(uut.state_reg);

                $display("state_out lanes:");
                print_lanes_128(uut.state_next);
            end

            if (done) begin
                $display("====================================");
                $display("Hash done");

                // Verilog 向量顺序，高位在前
                $display("digest = 0x%096h", digest);

                // 按照 C 代码 output[j] = state[j] 的字节顺序，每 16 字节换行
                $display("digest byte order:");
                for (i = 0; i < 48; i = i + 1) begin
                    $write("%02x ", digest[8*i +: 8]);

                    if ((i % 16) == 15) begin
                        $write("\n");
                    end
                end

                $display("====================================");
            end
        end
    end

endmodule